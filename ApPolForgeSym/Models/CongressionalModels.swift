//
//  CongressionalModels.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//

import Foundation

// MARK: - Party Affiliation

enum PartyAffiliation: String, Codable, CaseIterable, Identifiable {
    case democratic = "Democratic"
    case republican = "Republican"
    case independent = "Independent"
    case libertarian = "Libertarian"
    case green = "Green"
    case other = "Other"

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .democratic: return "D"
        case .republican: return "R"
        case .independent: return "I"
        case .libertarian: return "L"
        case .green: return "G"
        case .other: return "O"
        }
    }

    var hexColor: String {
        switch self {
        case .democratic: return "#3498db"
        case .republican: return "#e74c3c"
        case .independent: return "#9b59b6"
        case .libertarian: return "#f39c12"
        case .green: return "#27ae60"
        case .other: return "#95a5a6"
        }
    }
}

// MARK: - Campaign Level

enum CampaignLevel: String, Codable, CaseIterable, Identifiable {
    case federal = "Federal"
    case state   = "State"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .federal: return "building.columns.fill"
        case .state:   return "mappin.and.ellipse"
        }
    }
}

// MARK: - Race Type

enum RaceType: String, Codable, CaseIterable, Identifiable {
    case presidential = "Presidential"
    case senate       = "Senate"
    case house        = "House"
    case governor     = "Governor"
    case stateSenate  = "State Senate"
    case stateHouse   = "State House"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .presidential: return "building.columns.fill"
        case .senate:       return "building.2.fill"
        case .house:        return "house.fill"
        case .governor:     return "mappin.and.ellipse"
        case .stateSenate:  return "building.2.crop.circle"
        case .stateHouse:   return "house.and.flag.fill"
        }
    }

    var campaignLevel: CampaignLevel {
        switch self {
        case .presidential, .senate, .house: return .federal
        case .governor, .stateSenate, .stateHouse: return .state
        }
    }
}

// MARK: - Chamber Type

enum ChamberType: String, Codable, CaseIterable, Identifiable {
    case senate = "Senate"
    case house = "House"

    var id: String { rawValue }
}

// MARK: - Congressional District

struct CongressionalDistrict: Identifiable, Codable {
    let id: UUID
    let state: String
    let stateAbbreviation: String
    /// 0 = at-large, 1-N = numbered districts
    let districtNumber: Int
    let chamber: ChamberType
    /// Cook PVI, e.g. "R+5", "D+12", "EVEN"
    let cookPVI: String
    /// 1=Battleground (<5pp), 2=Lean (5–10pp), 3=Likely (10–20pp), 4=Safe (>20pp)
    let competitivenessTier: Int
    let incumbentParty: PartyAffiliation?
    let currentDemPercent: Double
    let currentRepPercent: Double

    var displayName: String {
        if chamber == .senate {
            return "\(state) Senate"
        } else if districtNumber == 0 {
            return "\(stateAbbreviation) At-Large"
        } else {
            return "\(stateAbbreviation)-\(districtNumber)"
        }
    }

    var margin: Double {
        abs(currentDemPercent - currentRepPercent)
    }

    var tierLabel: String {
        switch competitivenessTier {
        case 1: return "Battleground"
        case 2: return "Lean"
        case 3: return "Likely"
        default: return "Safe"
        }
    }

    var leadingParty: PartyAffiliation? {
        if currentDemPercent > currentRepPercent + 1 { return .democratic }
        if currentRepPercent > currentDemPercent + 1 { return .republican }
        return nil
    }

    init(
        id: UUID = UUID(),
        state: String,
        stateAbbreviation: String,
        districtNumber: Int,
        chamber: ChamberType,
        cookPVI: String = "EVEN",
        competitivenessTier: Int = 3,
        incumbentParty: PartyAffiliation? = nil,
        currentDemPercent: Double = 50.0,
        currentRepPercent: Double = 50.0
    ) {
        self.id = id
        self.state = state
        self.stateAbbreviation = stateAbbreviation
        self.districtNumber = districtNumber
        self.chamber = chamber
        self.cookPVI = cookPVI
        self.competitivenessTier = competitivenessTier
        self.incumbentParty = incumbentParty
        self.currentDemPercent = currentDemPercent
        self.currentRepPercent = currentRepPercent
    }
}

// MARK: - Congressional Race

struct CongressionalRace: Identifiable, Codable {
    let id: UUID
    /// Firestore document ID, e.g. "PA-Senate-2026", "OH-3-House-2026"
    let raceId: String
    let district: CongressionalDistrict
    /// Election cycle year, e.g. 2026
    let cycle: Int
    let candidateDem: String
    let candidateRep: String
    let candidateDemIncumbent: Bool
    let candidateRepIncumbent: Bool
    var demPollingAverage: Double
    var repPollingAverage: Double
    var lastRefreshed: Date?
    var forecastedWinner: PartyAffiliation?
    var forecastedMargin: Double

    var isCompetitive: Bool {
        district.competitivenessTier <= 2
    }

    var displayTitle: String {
        if district.chamber == .senate {
            return "\(district.state) Senate"
        } else if district.districtNumber == 0 {
            return "\(district.stateAbbreviation) At-Large"
        } else {
            return "\(district.stateAbbreviation) District \(district.districtNumber)"
        }
    }

    var marginDisplay: String {
        let leader = demPollingAverage > repPollingAverage ? "D" : "R"
        return "\(leader)+\(String(format: "%.1f", forecastedMargin))"
    }

    init(
        id: UUID = UUID(),
        raceId: String,
        district: CongressionalDistrict,
        cycle: Int,
        candidateDem: String,
        candidateRep: String,
        candidateDemIncumbent: Bool = false,
        candidateRepIncumbent: Bool = false,
        demPollingAverage: Double = 50.0,
        repPollingAverage: Double = 50.0,
        lastRefreshed: Date? = nil,
        forecastedWinner: PartyAffiliation? = nil,
        forecastedMargin: Double = 0.0
    ) {
        self.id = id
        self.raceId = raceId
        self.district = district
        self.cycle = cycle
        self.candidateDem = candidateDem
        self.candidateRep = candidateRep
        self.candidateDemIncumbent = candidateDemIncumbent
        self.candidateRepIncumbent = candidateRepIncumbent
        self.demPollingAverage = demPollingAverage
        self.repPollingAverage = repPollingAverage
        self.lastRefreshed = lastRefreshed
        self.forecastedWinner = forecastedWinner
        self.forecastedMargin = forecastedMargin
    }
}

// MARK: - User Candidate

/// Represents a real-world candidate that the user is tracking or managing.
struct UserCandidate: Identifiable, Codable {
    let id: UUID
    var name: String
    var party: PartyAffiliation
    var campaignLevel: CampaignLevel
    var raceType: RaceType
    var state: String
    var stateAbbreviation: String
    /// Used for House, State Senate, and State House races; 0 = at-large
    var districtNumber: Int
    var isIncumbent: Bool
    var opponentName: String
    var opponentParty: PartyAffiliation
    var createdAt: Date

    // Candidate contact info (optional, stored locally)
    var campaignWebsite: String
    var campaignPhone: String
    var campaignAddress: String

    // Opponent contact info (optional, stored locally)
    var opponentWebsite: String
    var opponentPhone: String
    var opponentAddress: String

    var displayRaceTitle: String {
        switch raceType {
        case .presidential:
            return "Presidential Race"
        case .senate:
            return "\(state) Senate"
        case .house:
            if districtNumber == 0 {
                return "\(stateAbbreviation) At-Large"
            }
            return "\(stateAbbreviation) District \(districtNumber)"
        case .governor:
            return "\(state) Governor"
        case .stateSenate:
            return "\(stateAbbreviation) State Senate Dist. \(districtNumber)"
        case .stateHouse:
            return "\(stateAbbreviation) State House Dist. \(districtNumber)"
        }
    }

    /// Firestore race ID for polling lookups
    var raceId: String {
        switch raceType {
        case .presidential:
            return "\(stateAbbreviation)-presidential"
        case .senate:
            return "\(stateAbbreviation)-senate"
        case .house:
            return "\(stateAbbreviation)-\(districtNumber)-house"
        case .governor:
            return "\(stateAbbreviation)-governor"
        case .stateSenate:
            return "\(stateAbbreviation)-\(districtNumber)-state-senate"
        case .stateHouse:
            return "\(stateAbbreviation)-\(districtNumber)-state-house"
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        party: PartyAffiliation,
        campaignLevel: CampaignLevel = .federal,
        raceType: RaceType,
        state: String,
        stateAbbreviation: String,
        districtNumber: Int = 0,
        isIncumbent: Bool = false,
        opponentName: String,
        opponentParty: PartyAffiliation,
        createdAt: Date = Date(),
        campaignWebsite: String = "",
        campaignPhone: String = "",
        campaignAddress: String = "",
        opponentWebsite: String = "",
        opponentPhone: String = "",
        opponentAddress: String = ""
    ) {
        self.id = id
        self.name = name
        self.party = party
        self.campaignLevel = campaignLevel
        self.raceType = raceType
        self.state = state
        self.stateAbbreviation = stateAbbreviation
        self.districtNumber = districtNumber
        self.isIncumbent = isIncumbent
        self.opponentName = opponentName
        self.opponentParty = opponentParty
        self.createdAt = createdAt
        self.campaignWebsite = campaignWebsite
        self.campaignPhone = campaignPhone
        self.campaignAddress = campaignAddress
        self.opponentWebsite = opponentWebsite
        self.opponentPhone = opponentPhone
        self.opponentAddress = opponentAddress
    }
}
