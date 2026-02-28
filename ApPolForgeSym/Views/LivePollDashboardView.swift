//
//  LivePollDashboardView.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Displays live poll averages for all tracked races, sorted by closest margin.
//  Supports pull-to-refresh and drill-down into individual polls.
//  Data comes from FirestoreService (read-only Firestore client).
//

import SwiftUI

// MARK: - Live Poll Dashboard View

struct LivePollDashboardView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var firestoreService = FirestoreService.shared
    @StateObject private var biweeklyManager = BiweeklyRefreshManager.shared
    @State private var selectedPollAverage: PollAverage?
    @State private var showingDrillDown = false

    private var activeCandidate: UserCandidate? {
        guard let activeId = gameState.activeUserCandidateId else { return nil }
        return gameState.userCandidates.first { $0.id == activeId }
    }

    private var sortedAverages: [PollAverage] {
        firestoreService.pollAverages.values
            .sorted { $0.forecastedMargin < $1.forecastedMargin }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sync status bar
            SyncStatusBar(
                lastSync: firestoreService.lastSyncDate,
                nextSync: biweeklyManager.nextScheduledRefresh,
                isLoading: biweeklyManager.isRefreshing
            )

            if firestoreService.isLoading && sortedAverages.isEmpty {
                ProgressView("Loading polls…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sortedAverages.isEmpty {
                ContentUnavailableView(
                    "No Polls Loaded",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Pull to refresh or ensure Firestore is configured with poll data.")
                )
            } else {
                List {
                    // Active candidate section (if set)
                    if let candidate = activeCandidate,
                       let avg = firestoreService.pollAverages[candidate.raceId] {
                        Section("Your Race") {
                            PollAverageRow(
                                average: avg,
                                candidate: candidate,
                                onDrillDown: {
                                    selectedPollAverage = avg
                                    showingDrillDown = true
                                }
                            )
                        }
                    }

                    Section("All Tracked Races — Closest Margin First") {
                        ForEach(sortedAverages) { average in
                            PollAverageRow(
                                average: average,
                                candidate: candidateFor(raceId: average.raceId),
                                onDrillDown: {
                                    selectedPollAverage = average
                                    showingDrillDown = true
                                }
                            )
                        }
                    }
                }
                .refreshable {
                    let raceIds = Array(firestoreService.pollAverages.keys)
                    await biweeklyManager.performManualRefresh(raceIds: raceIds)
                }
            }
        }
        .sheet(isPresented: $showingDrillDown) {
            if let avg = selectedPollAverage {
                PollDrillDownView(average: avg, gameState: gameState)
            }
        }
        .onAppear {
            firestoreService.loadFromCache()
            guard AppSettings.shared.firestoreEnabled else { return }
            if sortedAverages.isEmpty || biweeklyManager.isDueForRefresh {
                Task {
                    let raceIds = gameState.userCandidates.map(\.raceId)
                    await firestoreService.performFullRefresh(raceIds: raceIds)
                }
            }
        }
    }

    private func candidateFor(raceId: String) -> UserCandidate? {
        gameState.userCandidates.first { $0.raceId == raceId }
    }
}

// MARK: - Sync Status Bar

struct SyncStatusBar: View {
    let lastSync: Date?
    let nextSync: Date?
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Refreshing…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.green)
                if let sync = lastSync {
                    Text("Updated \(RelativeDateTimeFormatter().localizedString(for: sync, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not yet synced")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let next = nextSync, next > Date() {
                    Text("Next: \(RelativeDateTimeFormatter().localizedString(for: next, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(uiColor: .systemGray6))
        #endif
    }
}

// MARK: - Poll Average Row

struct PollAverageRow: View {
    let average: PollAverage
    let candidate: UserCandidate?
    let onDrillDown: () -> Void

    private func tierColor(for tier: Int) -> Color {
        switch tier {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }

    var body: some View {
        Button(action: onDrillDown) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and tier badge
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(raceTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(average.raceId)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(average.marginDisplay)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(average.tierLabel)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tierColor(for: average.competitivenessTier).opacity(0.2))
                            .foregroundStyle(tierColor(for: average.competitivenessTier))
                            .clipShape(Capsule())
                    }
                }

                // Poll bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * (average.computedAvgDem / 100))
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geo.size.width * (average.computedAvgRep / 100))
                        Rectangle()
                            .fill(Color.gray.opacity(0.25))
                    }
                }
                .frame(height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3))

                // Pct + win probability
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(.blue).frame(width: 7, height: 7)
                        Text("D: \(String(format: "%.1f", average.computedAvgDem))%")
                            .font(.caption)
                    }

                    Spacer()

                    // Win probability bar
                    WinProbabilityBar(
                        demProb: average.demWinProbability,
                        repProb: average.repWinProbability
                    )

                    Spacer()

                    HStack(spacing: 4) {
                        Text("R: \(String(format: "%.1f", average.computedAvgRep))%")
                            .font(.caption)
                        Circle().fill(.red).frame(width: 7, height: 7)
                    }
                }

                // Last updated
                HStack {
                    Text(average.lastRefreshedDisplay)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(raceTitle): Democrat \(String(format: "%.1f", average.computedAvgDem)) percent, Republican \(String(format: "%.1f", average.computedAvgRep)) percent. \(average.tierLabel).")
    }

    private var raceTitle: String {
        candidate?.displayRaceTitle ?? average.raceId
    }
}

// MARK: - Win Probability Bar

struct WinProbabilityBar: View {
    let demProb: Double
    let repProb: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: geo.size.width * demProb)
                Rectangle()
                    .fill(Color.red.opacity(0.7))
            }
        }
        .frame(width: 80, height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Poll Drill Down View

struct PollDrillDownView: View {
    let average: PollAverage
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var individualPolls: [LivePoll] = []
    @State private var isLoading = false

    var candidate: UserCandidate? {
        gameState.userCandidates.first { $0.raceId == average.raceId }
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary section
                Section("Polling Average") {
                    LabeledContent("Democrat", value: String(format: "%.1f%%", average.computedAvgDem))
                    LabeledContent("Republican", value: String(format: "%.1f%%", average.computedAvgRep))
                    LabeledContent("Margin", value: average.marginDisplay)
                    LabeledContent("Tier", value: average.tierLabel)
                    LabeledContent("D Win Probability", value: String(format: "%.0f%%", average.demWinProbability * 100))
                    LabeledContent("R Win Probability", value: String(format: "%.0f%%", average.repWinProbability * 100))
                    LabeledContent("Last Updated", value: average.lastRefreshedDisplay)
                }

                // Individual polls
                if isLoading {
                    Section("Individual Polls") {
                        ProgressView("Loading polls…")
                    }
                } else if individualPolls.isEmpty {
                    Section("Individual Polls") {
                        Text("No individual poll data available.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Individual Polls (\(individualPolls.count))") {
                        ForEach(individualPolls) { poll in
                            IndividualPollRow(poll: poll)
                        }
                    }
                }
            }
            .navigationTitle(candidate?.displayRaceTitle ?? average.raceId)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                isLoading = true
                Task {
                    individualPolls = await firestoreService.fetchDrillDownPolls(for: average.raceId)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Individual Poll Row

struct IndividualPollRow: View {
    let poll: LivePoll

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(poll.pollster)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(poll.source.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if poll.isValidated {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Text("D: \(String(format: "%.1f%%", poll.demPercent))")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("R: \(String(format: "%.1f%%", poll.repPercent))")
                    .font(.caption)
                    .foregroundStyle(.red)
                Spacer()
                Text("n=\(poll.sampleSize) ±\(String(format: "%.1f", poll.marginOfError))pp")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(poll.dateRangeDisplay)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("• \(poll.methodology)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    LivePollDashboardView(gameState: GameState())
}
