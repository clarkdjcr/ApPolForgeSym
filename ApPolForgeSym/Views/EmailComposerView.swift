//
//  EmailComposerView.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Compose and send campaign intelligence emails.
//  iOS/iPadOS: Mail.app via MFMailComposeViewController
//  macOS:      Mail.app via NSSharingService
//  visionOS:   Clipboard fallback
//

import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

// MARK: - Email Composer View

struct EmailComposerView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var composerService = EmailComposerService.shared
    @StateObject private var firestoreService = FirestoreService.shared
    @StateObject private var correlationEngine = IssueCorrelationEngine.shared
    @StateObject private var newsService = NewsAggregatorService.shared

    @State private var recipientText: String = ""
    @State private var selectedTemplate: EmailTemplate = .briefing
    @State private var includePollData = true
    @State private var includeIssueAlerts = true
    @State private var includeNewsDigest = true
    @State private var includeWinProbability = true
    @State private var generatedEmail: CampaignEmail?
    @State private var showingPreview = false
    @State private var showingMailCompose = false
    @State private var showingCopiedAlert = false
    @State private var showingNoMailAlert = false

    #if canImport(MessageUI)
    @State private var canSendMail = MFMailComposeViewController.canSendMail()
    #endif

    private var activeCandidate: UserCandidate? {
        guard let id = gameState.activeUserCandidateId else { return nil }
        return gameState.userCandidates.first { $0.id == id }
    }

    private var recipients: [String] {
        recipientText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.contains("@") }
    }

    var body: some View {
        List {
            // MARK: Candidate Selector
            Section("Campaign") {
                if let candidate = activeCandidate {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(candidate.name)
                                .font(.headline)
                            Text(candidate.displayRaceTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(candidate.party.abbreviation)
                            .font(.headline)
                            .padding(8)
                            .background(Color(hex: candidate.party.hexColor)?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                            .clipShape(Circle())
                    }
                } else {
                    Label("No candidate selected. Add one from Setup.", systemImage: "person.badge.plus")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }

            // MARK: Recipients
            Section {
                TextField("email@domain.com, email2@domain.com", text: $recipientText)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    #endif
                    .accessibilityLabel("Recipient email addresses, comma-separated")

                if !recipients.isEmpty {
                    Text("\(recipients.count) recipient\(recipients.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Recipients")
            } footer: {
                Text("Separate multiple addresses with commas.")
                    .font(.caption)
            }

            // MARK: Template
            Section("Template") {
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(EmailTemplate.allCases) { template in
                        Label(template.rawValue, systemImage: template.icon)
                            .tag(template)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTemplate) { _, template in
                    includePollData = template.defaultIncludePollData
                    includeIssueAlerts = template.defaultIncludeIssueAlerts
                    includeNewsDigest = template.defaultIncludeNewsDigest
                }

                Text(selectedTemplate.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: Content Toggles
            Section("Content") {
                Toggle("Poll Averages & Win Probability", isOn: $includePollData)
                    .onChange(of: includePollData) { _, v in if !v { includeWinProbability = false } }
                if includePollData {
                    Toggle("Win Probability Estimate", isOn: $includeWinProbability)
                        .padding(.leading, 20)
                }
                Toggle("Issue Sensitivity Alerts", isOn: $includeIssueAlerts)
                Toggle("News Digest", isOn: $includeNewsDigest)
            }

            // MARK: Preview
            if let email = generatedEmail {
                Section {
                    Button {
                        showingPreview = true
                    } label: {
                        Label("Preview Email", systemImage: "eye")
                    }

                    Button {
                        sendOrCopy(email: email)
                    } label: {
                        Label(sendButtonLabel, systemImage: sendButtonIcon)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Generated: \(generatedEmail?.subject ?? "")")
                        .lineLimit(2)
                }
            }

            // MARK: Generate Button
            Section {
                Button {
                    generateEmail()
                } label: {
                    HStack {
                        Spacer()
                        if composerService.isGenerating {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Label(
                            composerService.isGenerating ? "Generating…" : "Generate Email",
                            systemImage: "doc.badge.arrow.up"
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .background(activeCandidate != nil ? Color.green : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(activeCandidate == nil || composerService.isGenerating)
            }
        }
        .navigationTitle("Email Composer")
        .sheet(isPresented: $showingPreview) {
            if let email = generatedEmail {
                EmailPreviewSheet(email: email)
            }
        }
        #if canImport(MessageUI)
        .sheet(isPresented: $showingMailCompose) {
            if let email = generatedEmail {
                MailComposeView(email: email, isPresented: $showingMailCompose)
            }
        }
        #endif
        .alert("Copied to Clipboard", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("The email content has been copied to your clipboard.")
        }
        .alert("Mail Not Available", isPresented: $showingNoMailAlert) {
            Button("Copy to Clipboard") {
                if let email = generatedEmail {
                    composerService.copyToClipboard(email)
                    showingCopiedAlert = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Mail.app is not configured on this device. The email content will be copied to clipboard instead.")
        }
    }

    // MARK: - Helpers

    private var sendButtonLabel: String {
        #if os(macOS)
        return "Open in Mail.app"
        #elseif canImport(MessageUI)
        return MFMailComposeViewController.canSendMail() ? "Send via Mail.app" : "Copy to Clipboard"
        #else
        return "Copy to Clipboard"
        #endif
    }

    private var sendButtonIcon: String {
        #if os(macOS)
        return "envelope.badge"
        #elseif canImport(MessageUI)
        return MFMailComposeViewController.canSendMail() ? "envelope.fill" : "doc.on.clipboard"
        #else
        return "doc.on.clipboard"
        #endif
    }

    private func generateEmail() {
        guard let candidate = activeCandidate else { return }

        let pollAvg = firestoreService.pollAverages[candidate.raceId]
        let correlations = correlationEngine.topSensitiveIssues(for: candidate.raceId, limit: 3)
        let articles = newsService.articles.filter { $0.relatedRaceIds.contains(candidate.raceId) || $0.relatedRaceIds.isEmpty }

        let options = EmailOptions(from: selectedTemplate)
        var opts = options
        opts.includePollData = includePollData
        opts.includeIssueAlerts = includeIssueAlerts
        opts.includeNewsDigest = includeNewsDigest
        opts.includeWinProbability = includeWinProbability

        generatedEmail = composerService.generateEmail(
            for: candidate,
            pollAverage: pollAvg,
            topCorrelations: correlations,
            recentNews: Array(articles.prefix(20)),
            template: selectedTemplate,
            recipients: recipients.isEmpty ? ["campaign@example.com"] : recipients,
            options: opts
        )
    }

    private func sendOrCopy(email: CampaignEmail) {
        #if os(macOS)
        composerService.sendViaMacMail(email)
        #elseif canImport(MessageUI)
        if MFMailComposeViewController.canSendMail() {
            showingMailCompose = true
        } else {
            composerService.copyToClipboard(email)
            showingCopiedAlert = true
        }
        #else
        composerService.copyToClipboard(email)
        showingCopiedAlert = true
        #endif
    }
}

// MARK: - Email Preview Sheet

struct EmailPreviewSheet: View {
    let email: CampaignEmail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        LabeledContent("Subject", value: email.subject)
                        LabeledContent("To", value: email.recipientList.isEmpty ? "(none)" : email.recipientList)
                        LabeledContent("Template", value: email.template.rawValue)
                    }
                    .padding(.horizontal)

                    Divider()

                    Text(email.plainTextBody)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        #if os(macOS)
                        .background(Color(nsColor: .textBackgroundColor))
                        #else
                        .background(Color(uiColor: .systemGray6))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Email Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - MFMailComposeViewController Wrapper (iOS/iPadOS only)

#if canImport(MessageUI)
struct MailComposeView: UIViewControllerRepresentable {
    let email: CampaignEmail
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(email.recipientAddresses)
        vc.setSubject(email.subject)
        vc.setMessageBody(email.htmlBody.isEmpty ? email.plainTextBody : email.htmlBody,
                          isHTML: !email.htmlBody.isEmpty)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        init(isPresented: Binding<Bool>) { self._isPresented = isPresented }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            isPresented = false
        }
    }
}
#endif

// MARK: - Color Hex Extension (local)

private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue:  Double(value & 0xFF) / 255
        )
    }
}

#Preview {
    EmailComposerView(gameState: GameState())
}
