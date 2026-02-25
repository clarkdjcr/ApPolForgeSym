//
//  CandidateRosterBrowserView.swift
//  ApPolForgeSym
//
//  Read-only browser for all 56 seeded candidateRoster documents.
//  Requires firestoreEnabled = true in AppSettings to show live data.
//

import SwiftUI

struct CandidateRosterBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entries: [RosterEntry] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var senate: [RosterEntry] {
        entries
            .filter { $0.raceLabel.lowercased() == "senate" }
            .filter { matchesSearch($0) }
    }

    private var governor: [RosterEntry] {
        entries
            .filter { $0.raceLabel.lowercased() == "governor" }
            .filter { matchesSearch($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading races…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "No Races Available",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text("Enable Firestore in Settings to load the 2026 race database.")
                    )
                } else {
                    List {
                        if !senate.isEmpty {
                            Section("Senate") {
                                ForEach(senate) { entry in
                                    RosterEntryRow(entry: entry)
                                }
                            }
                        }
                        if !governor.isEmpty {
                            Section("Governor") {
                                ForEach(governor) { entry in
                                    RosterEntryRow(entry: entry)
                                }
                            }
                        }
                        if senate.isEmpty && governor.isEmpty {
                            ContentUnavailableView.search
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .navigationTitle("2026 Race Database")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .searchable(text: $searchText, prompt: "Filter by state (e.g. AZ)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            entries = await FirestoreService.shared.fetchAllCandidateRosters()
            isLoading = false
        }
    }

    private func matchesSearch(_ entry: RosterEntry) -> Bool {
        guard !searchText.isEmpty else { return true }
        return entry.stateAbbreviation.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - RosterEntryRow

private struct RosterEntryRow: View {
    let entry: RosterEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(entry.stateAbbreviation) \(entry.raceLabel)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                CandidateChip(
                    name: entry.roster.candidateDem,
                    party: .democratic,
                    isIncumbent: entry.roster.demIncumbent
                )
                CandidateChip(
                    name: entry.roster.candidateRep,
                    party: .republican,
                    isIncumbent: entry.roster.repIncumbent
                )
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.stateAbbreviation) \(entry.raceLabel): " +
            "\(entry.roster.candidateDem)\(entry.roster.demIncumbent ? " (incumbent)" : ""), Democrat, versus " +
            "\(entry.roster.candidateRep)\(entry.roster.repIncumbent ? " (incumbent)" : ""), Republican"
        )
    }
}

// MARK: - CandidateChip

private struct CandidateChip: View {
    let name: String
    let party: PartyAffiliation
    let isIncumbent: Bool

    private var dotColor: Color {
        party == .democratic ? .blue : .red
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(displayName)
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayName: String {
        isIncumbent ? "\(name) ★" : name
    }
}

#Preview {
    CandidateRosterBrowserView()
}
