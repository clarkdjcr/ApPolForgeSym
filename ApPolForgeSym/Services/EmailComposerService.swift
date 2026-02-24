//
//  EmailComposerService.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Generates HTML + plain-text campaign briefing emails.
//  Send mechanism by platform:
//    iOS/iPadOS: MFMailComposeViewController (MessageUI)
//    macOS:      NSSharingService (Mail.app)
//    visionOS:   UIPasteboard clipboard fallback
//

import Foundation
import Combine
import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Email Send Result

enum EmailSendResult {
    case sent
    case saved
    case cancelled
    case failed(String)
}

// MARK: - Email Composer Service

@MainActor
final class EmailComposerService: ObservableObject {
    static let shared = EmailComposerService()

    @Published var lastGeneratedEmail: CampaignEmail?
    @Published var isGenerating: Bool = false

    private init() {}

    // MARK: - Generation

    /// Build a CampaignEmail from live data for the given candidate.
    func generateEmail(
        for candidate: UserCandidate,
        pollAverage: PollAverage?,
        topCorrelations: [PollIssueCorrelation],
        recentNews: [NewsArticle],
        template: EmailTemplate,
        recipients: [String],
        options: EmailOptions = EmailOptions()
    ) -> CampaignEmail {
        isGenerating = true
        defer { isGenerating = false }

        let subject = buildSubject(candidate: candidate, template: template)
        let plain = buildPlainText(
            candidate: candidate,
            pollAverage: pollAverage,
            topCorrelations: topCorrelations,
            recentNews: recentNews,
            template: template,
            options: options
        )
        let html = buildHTML(
            candidate: candidate,
            pollAverage: pollAverage,
            topCorrelations: topCorrelations,
            recentNews: recentNews,
            template: template,
            options: options
        )

        let email = CampaignEmail(
            subject: subject,
            recipientAddresses: recipients,
            template: template,
            includePollData: options.includePollData,
            includeIssueAlerts: options.includeIssueAlerts,
            includeNewsDigest: options.includeNewsDigest,
            includeWinProbability: options.includeWinProbability,
            candidateId: candidate.id,
            htmlBody: html,
            plainTextBody: plain
        )

        lastGeneratedEmail = email
        return email
    }

    // MARK: - Platform Send

    /// Copy plain-text body to clipboard. Universal fallback, primary on visionOS.
    func copyToClipboard(_ email: CampaignEmail) {
        #if canImport(UIKit)
        UIPasteboard.general.string = email.plainTextBody
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(email.plainTextBody, forType: .string)
        #endif
    }

    #if canImport(AppKit)
    /// Open Mail.app on macOS using NSSharingService.
    func sendViaMacMail(_ email: CampaignEmail) {
        guard let service = NSSharingService(named: .composeEmail) else {
            copyToClipboard(email)
            return
        }
        service.recipients = email.recipientAddresses
        service.subject = email.subject
        service.perform(withItems: [email.plainTextBody])
    }
    #endif

    // MARK: - Subject Builder

    private func buildSubject(candidate: UserCandidate, template: EmailTemplate) -> String {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        switch template {
        case .briefing:
            return "[\(dateStr)] Campaign Briefing — \(candidate.name), \(candidate.displayRaceTitle)"
        case .pollingUpdate:
            return "[\(dateStr)] Poll Update — \(candidate.displayRaceTitle)"
        case .issueAlert:
            return "[\(dateStr)] Issue Alert — \(candidate.displayRaceTitle)"
        case .fullReport:
            return "[\(dateStr)] Full Campaign Report — \(candidate.name)"
        }
    }

    // MARK: - Plain Text Builder

    private func buildPlainText(
        candidate: UserCandidate,
        pollAverage: PollAverage?,
        topCorrelations: [PollIssueCorrelation],
        recentNews: [NewsArticle],
        template: EmailTemplate,
        options: EmailOptions
    ) -> String {
        var lines: [String] = []

        lines.append("═══════════════════════════════════════")
        lines.append("POLFORGE CAMPAIGN INTELLIGENCE REPORT")
        lines.append("═══════════════════════════════════════")
        lines.append("Candidate: \(candidate.name) (\(candidate.party.rawValue))")
        lines.append("Race: \(candidate.displayRaceTitle)")
        lines.append("Opponent: \(candidate.opponentName) (\(candidate.opponentParty.rawValue))")
        lines.append("Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))")
        lines.append("")

        // Poll Section
        if options.includePollData, let avg = pollAverage {
            lines.append("─── POLL AVERAGES ───────────────────────")
            let candidateIsD = candidate.party == .democratic
            let candidatePct = candidateIsD ? avg.computedAvgDem : avg.computedAvgRep
            let opponentPct = candidateIsD ? avg.computedAvgRep : avg.computedAvgDem
            lines.append("\(candidate.name): \(String(format: "%.1f", candidatePct))%")
            lines.append("\(candidate.opponentName): \(String(format: "%.1f", opponentPct))%")
            lines.append("Margin: \(avg.marginDisplay)")
            lines.append("Tier: \(avg.tierLabel)")
            lines.append("Last updated: \(avg.lastRefreshedDisplay)")
            if options.includeWinProbability {
                let winProb = candidateIsD ? avg.demWinProbability : avg.repWinProbability
                lines.append("Win probability: \(String(format: "%.0f", winProb * 100))%")
            }
            lines.append("")
        }

        // Issue Alerts Section
        if options.includeIssueAlerts, !topCorrelations.isEmpty {
            lines.append("─── TOP POLLING-SENSITIVE ISSUES ────────")
            for (i, corr) in topCorrelations.prefix(3).enumerated() {
                let swing = String(format: "%.2f", corr.pollingSwingPerEvent)
                lines.append("\(i + 1). \(corr.issueCategory.rawValue)")
                lines.append("   Correlation: \(corr.formattedCoefficient) (\(corr.strengthLabel))")
                lines.append("   Avg swing/event: \(swing)pp | Recent articles: \(corr.recentNewsCount)")
            }
            lines.append("")
        }

        // News Digest Section
        if options.includeNewsDigest, !recentNews.isEmpty {
            lines.append("─── RECENT NEWS ─────────────────────────")
            let conflicted = recentNews.filter(\.conflictsWithOtherSources)
            let validated = recentNews.filter { $0.isValidated && !$0.conflictsWithOtherSources }

            for article in validated.prefix(5) {
                lines.append("• [\(article.source)] \(article.headline)")
                lines.append("  Issue: \(article.classifiedIssue.rawValue) | \(article.publishedDisplay)")
            }

            if !conflicted.isEmpty {
                lines.append("")
                lines.append("⚠ CONFLICTING REPORTS (\(conflicted.count) articles):")
                for article in conflicted.prefix(3) {
                    lines.append("• [\(article.source)] \(article.headline)")
                }
            }
            lines.append("")
        }

        lines.append("═══════════════════════════════════════")
        lines.append("Generated by PolForge | polforge.app")

        return lines.joined(separator: "\n")
    }

    // MARK: - HTML Builder

    private func buildHTML(
        candidate: UserCandidate,
        pollAverage: PollAverage?,
        topCorrelations: [PollIssueCorrelation],
        recentNews: [NewsArticle],
        template: EmailTemplate,
        options: EmailOptions
    ) -> String {
        var body = ""

        // Poll table
        if options.includePollData, let avg = pollAverage {
            let candidateIsD = candidate.party == .democratic
            let candidatePct = candidateIsD ? avg.computedAvgDem : avg.computedAvgRep
            let opponentPct = candidateIsD ? avg.computedAvgRep : avg.computedAvgDem
            let winProb = candidateIsD ? avg.demWinProbability : avg.repWinProbability

            body += """
            <h2 style="color:#2c3e50;">Poll Averages</h2>
            <table style="width:100%;border-collapse:collapse;margin-bottom:20px;">
              <tr style="background:#3498db;color:white;">
                <th style="padding:8px;text-align:left;">Candidate</th>
                <th style="padding:8px;text-align:right;">Avg %</th>
              </tr>
              <tr style="background:#eaf4fb;">
                <td style="padding:8px;">\(htmlEscape(candidate.name)) (\(candidate.party.abbreviation))</td>
                <td style="padding:8px;text-align:right;font-weight:bold;">\(String(format: "%.1f", candidatePct))%</td>
              </tr>
              <tr>
                <td style="padding:8px;">\(htmlEscape(candidate.opponentName)) (\(candidate.opponentParty.abbreviation))</td>
                <td style="padding:8px;text-align:right;">\(String(format: "%.1f", opponentPct))%</td>
              </tr>
            </table>
            <p><strong>Margin:</strong> \(avg.marginDisplay) &nbsp;|&nbsp;
               <strong>Tier:</strong> \(avg.tierLabel) &nbsp;|&nbsp;
               <strong>Updated:</strong> \(avg.lastRefreshedDisplay)</p>
            """
            if options.includeWinProbability {
                body += "<p><strong>Win Probability:</strong> \(String(format: "%.0f", winProb * 100))%</p>\n"
            }
        }

        // Issue alerts table
        if options.includeIssueAlerts, !topCorrelations.isEmpty {
            body += "<h2 style=\"color:#2c3e50;\">Top Polling-Sensitive Issues</h2>\n"
            body += "<table style=\"width:100%;border-collapse:collapse;margin-bottom:20px;\">\n"
            body += "<tr style=\"background:#e74c3c;color:white;\"><th style=\"padding:8px;text-align:left;\">Issue</th><th>Correlation</th><th>Swing/Event</th><th>Articles</th></tr>\n"
            for (i, corr) in topCorrelations.prefix(3).enumerated() {
                let bg = i % 2 == 0 ? "#fef5f5" : "#fff"
                body += "<tr style=\"background:\(bg);\"><td style=\"padding:8px;\">\(htmlEscape(corr.issueCategory.rawValue))</td><td style=\"text-align:center;\">\(corr.formattedCoefficient) (\(corr.strengthLabel))</td><td style=\"text-align:center;\">\(String(format: "%.2f", corr.pollingSwingPerEvent))pp</td><td style=\"text-align:center;\">\(corr.recentNewsCount)</td></tr>\n"
            }
            body += "</table>\n"
        }

        // News digest
        if options.includeNewsDigest, !recentNews.isEmpty {
            let validated = recentNews.filter { $0.isValidated && !$0.conflictsWithOtherSources }
            let conflicted = recentNews.filter(\.conflictsWithOtherSources)

            body += "<h2 style=\"color:#2c3e50;\">Recent News</h2>\n<ul>\n"
            for article in validated.prefix(5) {
                body += "<li><strong>[\(htmlEscape(article.source))]</strong> \(htmlEscape(article.headline)) <em style=\"color:#7f8c8d;\">(\(article.publishedDisplay))</em></li>\n"
            }
            body += "</ul>\n"

            if !conflicted.isEmpty {
                body += "<h3 style=\"color:#e67e22;\">⚠ Conflicting Reports</h3>\n<ul>\n"
                for article in conflicted.prefix(3) {
                    body += "<li style=\"color:#e67e22;\"><strong>[\(htmlEscape(article.source))]</strong> \(htmlEscape(article.headline))</li>\n"
                }
                body += "</ul>\n"
            }
        }

        return """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"><title>PolForge Campaign Report</title></head>
        <body style="font-family:Arial,Helvetica,sans-serif;max-width:600px;margin:0 auto;padding:20px;color:#2c3e50;">
          <div style="background:linear-gradient(135deg,#3498db,#e74c3c);padding:20px;border-radius:8px;margin-bottom:24px;">
            <h1 style="color:white;margin:0;font-size:22px;">PolForge Campaign Intelligence</h1>
            <p style="color:rgba(255,255,255,0.9);margin:4px 0 0 0;">\(htmlEscape(candidate.name)) — \(htmlEscape(candidate.displayRaceTitle))</p>
          </div>
          \(body)
          <hr style="border:none;border-top:1px solid #ecf0f1;margin-top:32px;">
          <p style="color:#95a5a6;font-size:12px;">Generated by PolForge · \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))</p>
        </body>
        </html>
        """
    }

    private func htmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Email Options

struct EmailOptions {
    var includePollData: Bool = true
    var includeIssueAlerts: Bool = true
    var includeNewsDigest: Bool = true
    var includeWinProbability: Bool = true

    nonisolated init() {}
    init(from template: EmailTemplate) {
        includePollData = template.defaultIncludePollData
        includeIssueAlerts = template.defaultIncludeIssueAlerts
        includeNewsDigest = template.defaultIncludeNewsDigest
        includeWinProbability = true
    }
}
