//
//  CongressionalMapView.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Shows Senate and House race polling averages. Mirrors the existing
//  StateRow design. Competitive races sorted to the top.
//  Data is read from FirestoreService (pre-computed competitiveness tiers).
//

import SwiftUI

// MARK: - Congressional Map View

struct CongressionalMapView: View {
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var selectedChamber: ChamberType = .senate
    @State private var searchText = ""

    private var filteredRaces: [CongressionalRace] {
        let chamberFiltered = firestoreService.congressionalRaces
            .filter { $0.district.chamber == selectedChamber }

        let searched: [CongressionalRace]
        if searchText.isEmpty {
            searched = chamberFiltered
        } else {
            searched = chamberFiltered.filter {
                $0.district.state.localizedCaseInsensitiveContains(searchText) ||
                $0.district.stateAbbreviation.localizedCaseInsensitiveContains(searchText) ||
                $0.candidateDem.localizedCaseInsensitiveContains(searchText) ||
                $0.candidateRep.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: competitive first (tier 1→4), then alphabetical
        return searched.sorted {
            if $0.district.competitivenessTier != $1.district.competitivenessTier {
                return $0.district.competitivenessTier < $1.district.competitivenessTier
            }
            return $0.displayTitle < $1.displayTitle
        }
    }

    private var competitiveRaces: [CongressionalRace] {
        filteredRaces.filter { $0.district.competitivenessTier <= 2 }
    }

    private var otherRaces: [CongressionalRace] {
        filteredRaces.filter { $0.district.competitivenessTier > 2 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chamber selector
            Picker("Chamber", selection: $selectedChamber) {
                ForEach(ChamberType.allCases) { chamber in
                    Text(chamber.rawValue).tag(chamber)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedChamber) { _, newChamber in
                Task {
                    await firestoreService.fetchCongressionalRaces(chamber: newChamber)
                }
            }

            if firestoreService.isLoading {
                ProgressView("Loading races…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRaces.isEmpty {
                ContentUnavailableView(
                    "No Races Found",
                    systemImage: "building.2",
                    description: Text(firestoreService.congressionalRaces.isEmpty
                        ? "Firestore data not yet loaded. Pull to refresh."
                        : "Try adjusting your search.")
                )
            } else {
                List {
                    if !competitiveRaces.isEmpty {
                        Section("Competitive (\(competitiveRaces.count))") {
                            ForEach(competitiveRaces) { race in
                                CongressionalRaceRow(race: race)
                            }
                        }
                    }

                    if !otherRaces.isEmpty {
                        Section("Other Races (\(otherRaces.count))") {
                            ForEach(otherRaces) { race in
                                CongressionalRaceRow(race: race)
                            }
                        }
                    }
                }
                .refreshable {
                    await firestoreService.fetchCongressionalRaces(chamber: selectedChamber)
                }
                .searchable(text: $searchText, prompt: "Search races")
            }
        }
        .onAppear {
            Task {
                await firestoreService.fetchCongressionalRaces(chamber: selectedChamber)
            }
        }
    }
}

// MARK: - Congressional Race Row

struct CongressionalRaceRow: View {
    let race: CongressionalRace

    private func tierBadgeColor(for tier: Int) -> Color {
        switch tier {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(race.displayTitle)
                        .font(.headline)

                    if let cookPVI = cookPVIDisplay {
                        Text(cookPVI)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(race.marginDisplay)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(race.district.tierLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tierBadgeColor(for: race.district.competitivenessTier).opacity(0.2))
                        .foregroundStyle(tierBadgeColor(for: race.district.competitivenessTier))
                        .clipShape(Capsule())

                    if race.district.competitivenessTier == 1 {
                        Text("COMPETITIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .overlay(Capsule().stroke(Color.red, lineWidth: 1))
                    }
                }
            }

            // Vote share bar (non-electoral-college — shows raw poll %)
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: PartyAffiliation.democratic.hexColor) ?? .blue)
                        .frame(width: geometry.size.width * (race.demPollingAverage / 100))

                    Rectangle()
                        .fill(Color(hex: PartyAffiliation.republican.hexColor) ?? .red)
                        .frame(width: geometry.size.width * (race.repPollingAverage / 100))

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // Candidate label row
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: PartyAffiliation.democratic.hexColor) ?? .blue)
                        .frame(width: 8, height: 8)
                    Text("\(race.candidateDem) \(race.candidateDemIncumbent ? "★" : "")")
                        .font(.caption)
                        .lineLimit(1)
                    Text(String(format: "%.1f%%", race.demPollingAverage))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(String(format: "%.1f%%", race.repPollingAverage))
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(race.candidateRep) \(race.candidateRepIncumbent ? "★" : "")")
                        .font(.caption)
                        .lineLimit(1)
                    Circle()
                        .fill(Color(hex: PartyAffiliation.republican.hexColor) ?? .red)
                        .frame(width: 8, height: 8)
                }
            }

            // Cook PVI note
            HStack {
                Text("Cook PVI: \(race.district.cookPVI)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if let refreshed = race.lastRefreshed {
                    Text(RelativeDateTimeFormatter().localizedString(for: refreshed, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(race.displayTitle): \(race.candidateDem) \(String(format: "%.1f", race.demPollingAverage)) percent vs \(race.candidateRep) \(String(format: "%.1f", race.repPollingAverage)) percent. \(race.district.tierLabel).")
    }

    private var cookPVIDisplay: String? {
        let pvi = race.district.cookPVI
        guard pvi != "EVEN" else { return "Cook PVI: Even" }
        return nil
    }
}

// MARK: - Color Hex Extension

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
    CongressionalMapView()
}
