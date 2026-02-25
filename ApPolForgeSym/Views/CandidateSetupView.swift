//
//  CandidateSetupView.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Presented as a sheet from SetupView. Allows the user to configure
//  a real-world candidate they want to track or simulate.
//

import SwiftUI

// MARK: - State Picker Data

private struct StateEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let abbreviation: String
}

private let usStates: [StateEntry] = [
    StateEntry(name: "Alabama", abbreviation: "AL"),
    StateEntry(name: "Alaska", abbreviation: "AK"),
    StateEntry(name: "Arizona", abbreviation: "AZ"),
    StateEntry(name: "Arkansas", abbreviation: "AR"),
    StateEntry(name: "California", abbreviation: "CA"),
    StateEntry(name: "Colorado", abbreviation: "CO"),
    StateEntry(name: "Connecticut", abbreviation: "CT"),
    StateEntry(name: "Delaware", abbreviation: "DE"),
    StateEntry(name: "Florida", abbreviation: "FL"),
    StateEntry(name: "Georgia", abbreviation: "GA"),
    StateEntry(name: "Hawaii", abbreviation: "HI"),
    StateEntry(name: "Idaho", abbreviation: "ID"),
    StateEntry(name: "Illinois", abbreviation: "IL"),
    StateEntry(name: "Indiana", abbreviation: "IN"),
    StateEntry(name: "Iowa", abbreviation: "IA"),
    StateEntry(name: "Kansas", abbreviation: "KS"),
    StateEntry(name: "Kentucky", abbreviation: "KY"),
    StateEntry(name: "Louisiana", abbreviation: "LA"),
    StateEntry(name: "Maine", abbreviation: "ME"),
    StateEntry(name: "Maryland", abbreviation: "MD"),
    StateEntry(name: "Massachusetts", abbreviation: "MA"),
    StateEntry(name: "Michigan", abbreviation: "MI"),
    StateEntry(name: "Minnesota", abbreviation: "MN"),
    StateEntry(name: "Mississippi", abbreviation: "MS"),
    StateEntry(name: "Missouri", abbreviation: "MO"),
    StateEntry(name: "Montana", abbreviation: "MT"),
    StateEntry(name: "Nebraska", abbreviation: "NE"),
    StateEntry(name: "Nevada", abbreviation: "NV"),
    StateEntry(name: "New Hampshire", abbreviation: "NH"),
    StateEntry(name: "New Jersey", abbreviation: "NJ"),
    StateEntry(name: "New Mexico", abbreviation: "NM"),
    StateEntry(name: "New York", abbreviation: "NY"),
    StateEntry(name: "North Carolina", abbreviation: "NC"),
    StateEntry(name: "North Dakota", abbreviation: "ND"),
    StateEntry(name: "Ohio", abbreviation: "OH"),
    StateEntry(name: "Oklahoma", abbreviation: "OK"),
    StateEntry(name: "Oregon", abbreviation: "OR"),
    StateEntry(name: "Pennsylvania", abbreviation: "PA"),
    StateEntry(name: "Rhode Island", abbreviation: "RI"),
    StateEntry(name: "South Carolina", abbreviation: "SC"),
    StateEntry(name: "South Dakota", abbreviation: "SD"),
    StateEntry(name: "Tennessee", abbreviation: "TN"),
    StateEntry(name: "Texas", abbreviation: "TX"),
    StateEntry(name: "Utah", abbreviation: "UT"),
    StateEntry(name: "Vermont", abbreviation: "VT"),
    StateEntry(name: "Virginia", abbreviation: "VA"),
    StateEntry(name: "Washington", abbreviation: "WA"),
    StateEntry(name: "West Virginia", abbreviation: "WV"),
    StateEntry(name: "Wisconsin", abbreviation: "WI"),
    StateEntry(name: "Wyoming", abbreviation: "WY"),
    StateEntry(name: "District of Columbia", abbreviation: "DC")
]

// MARK: - Candidate Setup View

struct CandidateSetupView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    // Core candidate fields
    @State private var candidateName: String = ""
    @State private var selectedParty: PartyAffiliation = .democratic
    @State private var selectedCampaignLevel: CampaignLevel = .federal
    @State private var selectedRaceType: RaceType = .presidential
    @State private var selectedStateEntry: StateEntry = usStates.first!
    @State private var districtNumber: Int = 1
    @State private var isIncumbent: Bool = false
    @State private var opponentName: String = ""
    @State private var selectedOpponentParty: PartyAffiliation = .republican
    @State private var showingValidationAlert = false

    // Autofill state
    @State private var isLoadingRoster: Bool = false
    @State private var rosterLoaded: Bool = false
    @State private var fetchedRoster: CandidateRoster? = nil

    // Candidate contact info
    @State private var campaignWebsite: String = ""
    @State private var campaignPhone: String = ""
    @State private var campaignAddress: String = ""

    // Opponent contact info
    @State private var opponentWebsite: String = ""
    @State private var opponentPhone: String = ""
    @State private var opponentAddress: String = ""

    private var isDistrictRace: Bool {
        selectedRaceType == .house ||
        selectedRaceType == .stateSenate ||
        selectedRaceType == .stateHouse
    }

    private var filteredRaceTypes: [RaceType] {
        RaceType.allCases.filter { $0.campaignLevel == selectedCampaignLevel }
    }

    private var isFormValid: Bool {
        !candidateName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !opponentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!isDistrictRace || districtNumber >= 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Campaign Level
                Section {
                    Picker("Level", selection: $selectedCampaignLevel) {
                        ForEach(CampaignLevel.allCases) { level in
                            Label(level.rawValue, systemImage: level.icon).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCampaignLevel) { _, newLevel in
                        // Reset to first race type for the new level
                        selectedRaceType = filteredRaceTypes.first ?? .presidential
                        rosterLoaded = false
                        fetchedRoster = nil
                    }
                } header: {
                    Text("Campaign Level")
                }

                // MARK: Race
                Section {
                    Picker("Race Type", selection: $selectedRaceType) {
                        ForEach(filteredRaceTypes) { raceType in
                            Label(raceType.rawValue, systemImage: raceType.icon)
                                .tag(raceType)
                        }
                    }
                    .onChange(of: selectedRaceType) { _, _ in
                        rosterLoaded = false
                        fetchedRoster = nil
                        triggerAutofill()
                    }

                    Picker("State", selection: $selectedStateEntry) {
                        ForEach(usStates) { state in
                            Text("\(state.name) (\(state.abbreviation))").tag(state)
                        }
                    }
                    .onChange(of: selectedStateEntry) { _, _ in
                        rosterLoaded = false
                        fetchedRoster = nil
                        triggerAutofill()
                    }

                    if isDistrictRace {
                        Stepper(
                            value: $districtNumber,
                            in: 0...53
                        ) {
                            HStack {
                                Text("District")
                                Spacer()
                                Text(districtNumber == 0 ? "At-Large" : "\(districtNumber)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("District number. 0 for at-large.")
                    }
                } header: {
                    Text("Race")
                } footer: {
                    if isDistrictRace {
                        Text("Enter 0 for at-large districts (e.g. Montana, Alaska).")
                            .font(.caption)
                    }
                }

                // MARK: Your Candidate
                Section {
                    HStack {
                        TextField("Full Name", text: $candidateName)
                            .accessibilityLabel("Candidate full name")
                            .onChange(of: candidateName) { _, _ in rosterLoaded = false }

                        if isLoadingRoster {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if let roster = fetchedRoster {
                        Picker("Select Real Candidate", selection: $selectedParty) {
                            Text(roster.candidateDem).tag(PartyAffiliation.democratic)
                            Text(roster.candidateRep).tag(PartyAffiliation.republican)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedParty) { _, newParty in
                            applyRosterSelection(roster, playerIsDem: newParty == .democratic)
                        }
                    }

                    if rosterLoaded {
                        Text("Real 2026 candidate data loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Party", selection: $selectedParty) {
                        ForEach(PartyAffiliation.allCases) { party in
                            Text(party.rawValue).tag(party)
                        }
                    }

                    Toggle("Incumbent", isOn: $isIncumbent)
                        .accessibilityLabel("Is the candidate an incumbent?")
                } header: {
                    Text("Your Candidate")
                } footer: {
                    Text("Real 2026 candidates auto-fill when you select a race and state above.")
                        .font(.caption)
                }

                // MARK: Opponent
                Section {
                    TextField("Opponent Full Name", text: $opponentName)
                        .accessibilityLabel("Opponent full name")
                        .onChange(of: opponentName) { _, _ in rosterLoaded = false }

                    Picker("Opponent Party", selection: $selectedOpponentParty) {
                        ForEach(PartyAffiliation.allCases) { party in
                            Text(party.rawValue).tag(party)
                        }
                    }
                } header: {
                    Text("Opponent")
                }

                // MARK: Campaign Contact
                Section {
                    TextField("Website", text: $campaignWebsite)
                        .autocorrectionDisabled()
#if canImport(UIKit)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
#endif
                    TextField("Phone", text: $campaignPhone)
#if canImport(UIKit)
                        .keyboardType(.phonePad)
#endif
                    TextField("Address", text: $campaignAddress)
                } header: {
                    Text("Your Candidate Contact")
                } footer: {
                    Text("Optional — stored locally on this device.")
                        .font(.caption)
                }

                // MARK: Opponent Contact
                Section {
                    TextField("Website", text: $opponentWebsite)
#if canImport(UIKit)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
#endif
                        .autocorrectionDisabled()
                    TextField("Phone", text: $opponentPhone)
#if canImport(UIKit)
                        .keyboardType(.phonePad)
#endif
                    TextField("Address", text: $opponentAddress)
                } header: {
                    Text("Opponent Contact")
                } footer: {
                    Text("Optional — stored locally on this device.")
                        .font(.caption)
                }

                // MARK: Preview
                Section {
                    CandidatePreviewRow(
                        name: candidateName.isEmpty ? "Your Candidate" : candidateName,
                        party: selectedParty,
                        raceTitle: previewRaceTitle,
                        isIncumbent: isIncumbent
                    )
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("New Candidate")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard isFormValid else {
                            showingValidationAlert = true
                            return
                        }
                        saveCandidate()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text("Please enter your candidate name and opponent name before continuing.")
            }
        }
    }

    // MARK: - Autofill

    private func triggerAutofill() {
        guard !rosterLoaded else { return }
        let raceId = computedRaceId()
        isLoadingRoster = true
        fetchedRoster = nil
        Task {
            if let roster = await FirestoreService.shared.fetchCandidateRoster(raceId: raceId) {
                fetchedRoster = roster
                applyRosterSelection(roster, playerIsDem: selectedParty == .democratic)
                rosterLoaded = true
            }
            isLoadingRoster = false
        }
    }

    private func applyRosterSelection(_ roster: CandidateRoster, playerIsDem: Bool) {
        candidateName         = playerIsDem ? roster.candidateDem : roster.candidateRep
        opponentName          = playerIsDem ? roster.candidateRep : roster.candidateDem
        selectedParty         = playerIsDem ? roster.demParty     : roster.repParty
        selectedOpponentParty = playerIsDem ? roster.repParty     : roster.demParty
        isIncumbent           = playerIsDem ? roster.demIncumbent : roster.repIncumbent
    }

    private func computedRaceId() -> String {
        let abbrev = selectedStateEntry.abbreviation
        switch selectedRaceType {
        case .presidential: return "\(abbrev)-presidential"
        case .senate:       return "\(abbrev)-senate"
        case .house:        return "\(abbrev)-\(districtNumber)-house"
        case .governor:     return "\(abbrev)-governor"
        case .stateSenate:  return "\(abbrev)-\(districtNumber)-state-senate"
        case .stateHouse:   return "\(abbrev)-\(districtNumber)-state-house"
        }
    }

    // MARK: - Helpers

    private var previewRaceTitle: String {
        switch selectedRaceType {
        case .presidential:
            return "Presidential Race"
        case .senate:
            return "\(selectedStateEntry.name) Senate"
        case .house:
            if districtNumber == 0 { return "\(selectedStateEntry.abbreviation) At-Large" }
            return "\(selectedStateEntry.abbreviation) District \(districtNumber)"
        case .governor:
            return "\(selectedStateEntry.name) Governor"
        case .stateSenate:
            return "\(selectedStateEntry.abbreviation) State Senate Dist. \(districtNumber)"
        case .stateHouse:
            return "\(selectedStateEntry.abbreviation) State House Dist. \(districtNumber)"
        }
    }

    private func saveCandidate() {
        let candidate = UserCandidate(
            name: candidateName.trimmingCharacters(in: .whitespaces),
            party: selectedParty,
            campaignLevel: selectedCampaignLevel,
            raceType: selectedRaceType,
            state: selectedStateEntry.name,
            stateAbbreviation: selectedStateEntry.abbreviation,
            districtNumber: isDistrictRace ? districtNumber : 0,
            isIncumbent: isIncumbent,
            opponentName: opponentName.trimmingCharacters(in: .whitespaces),
            opponentParty: selectedOpponentParty,
            campaignWebsite: campaignWebsite.trimmingCharacters(in: .whitespaces),
            campaignPhone: campaignPhone.trimmingCharacters(in: .whitespaces),
            campaignAddress: campaignAddress.trimmingCharacters(in: .whitespaces),
            opponentWebsite: opponentWebsite.trimmingCharacters(in: .whitespaces),
            opponentPhone: opponentPhone.trimmingCharacters(in: .whitespaces),
            opponentAddress: opponentAddress.trimmingCharacters(in: .whitespaces)
        )
        gameState.userCandidates.append(candidate)
        if gameState.activeUserCandidateId == nil {
            gameState.activeUserCandidateId = candidate.id
            AppSettings.shared.activeRaceId = candidate.raceId
        }
        dismiss()
    }
}

// MARK: - Candidate Preview Row

struct CandidatePreviewRow: View {
    let name: String
    let party: PartyAffiliation
    let raceTitle: String
    let isIncumbent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: party.hexColor) ?? .accentColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(party.abbreviation)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(raceTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isIncumbent {
                        Text("Incumbent")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Hex Extension (local)

private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard hex.count == 6,
              let value = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue:  Double(value & 0xFF) / 255
        )
    }
}

#Preview {
    CandidateSetupView(gameState: GameState())
}
