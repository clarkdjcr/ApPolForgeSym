//
//  LivePollingModels.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//

import Foundation

// MARK: - Poll Source

/// External polling aggregator sources
enum PollSource: String, Codable, CaseIterable, Identifiable {
    case fiveThirtyEight = "FiveThirtyEight"
    case realClearPolitics = "RealClearPolitics"
    case ballotpedia = "Ballotpedia"
    case other = "Other"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var credibilityScore: Double {
        switch self {
        case .fiveThirtyEight: return 0.95
        case .realClearPolitics: return 0.90
        case .ballotpedia: return 0.85
        case .other: return 0.70
        }
    }
}

// MARK: - Individual Poll

/// A single polling result for a given race.
struct LivePoll: Identifiable, Codable {
    let id: UUID
    /// Firestore race key, e.g. "PA-presidential", "OH-Senate"
    let raceId: String
    let pollster: String
    let source: PollSource
    let startDate: Date
    let endDate: Date
    let sampleSize: Int
    let marginOfError: Double
    /// "Phone", "Online", "Mixed"
    let methodology: String
    let demPercent: Double
    let repPercent: Double
    let indPercent: Double
    let undecidedPercent: Double
    /// True for Tier-1-source polls or cross-validated Tier-2 polls
    let isValidated: Bool

    var margin: Double { abs(demPercent - repPercent) }

    var leadingParty: PartyAffiliation? {
        if demPercent > repPercent + marginOfError { return .democratic }
        if repPercent > demPercent + marginOfError { return .republican }
        return nil
    }

    var dateRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: startDate))–\(formatter.string(from: endDate))"
    }

    init(
        id: UUID = UUID(),
        raceId: String,
        pollster: String,
        source: PollSource,
        startDate: Date,
        endDate: Date,
        sampleSize: Int,
        marginOfError: Double,
        methodology: String,
        demPercent: Double,
        repPercent: Double,
        indPercent: Double = 0,
        undecidedPercent: Double = 0,
        isValidated: Bool = false
    ) {
        self.id = id
        self.raceId = raceId
        self.pollster = pollster
        self.source = source
        self.startDate = startDate
        self.endDate = endDate
        self.sampleSize = sampleSize
        self.marginOfError = marginOfError
        self.methodology = methodology
        self.demPercent = demPercent
        self.repPercent = repPercent
        self.indPercent = indPercent
        self.undecidedPercent = undecidedPercent
        self.isValidated = isValidated
    }
}

// MARK: - Poll Average

/// The computed polling average for a race, stored in Firestore metadata.
/// App reads only this document (1 Firestore read per race). Full pollData
/// subcollection is fetched only on drill-down.
struct PollAverage: Identifiable, Codable {
    let id: UUID
    /// Firestore race key, e.g. "PA-presidential", "OH-Senate"
    let raceId: String
    let lastRefreshed: Date
    let computedAvgDem: Double
    let computedAvgRep: Double
    let forecastedWinner: PartyAffiliation?
    let forecastedMargin: Double
    /// 1=Battleground (<5pp), 2=Lean (5–10pp), 3=Likely (10–20pp), 4=Safe (>20pp)
    let competitivenessTier: Int

    // MARK: Win Probability

    /// Democratic win probability derived from polling margin using a
    /// sigmoid function (σ ≈ 3pp historical polling error).
    var demWinProbability: Double {
        winProbability(margin: computedAvgDem - computedAvgRep)
    }

    var repWinProbability: Double {
        1.0 - demWinProbability
    }

    private func winProbability(margin: Double) -> Double {
        // Approximated normal CDF via logistic function
        // P(win) ≈ 1 / (1 + exp(-margin / (σ * 0.588)))
        // where σ = 3pp
        let sigma = 3.0
        let z = margin / (sigma * 0.588)
        return 1.0 / (1.0 + exp(-z))
    }

    var tierLabel: String {
        switch competitivenessTier {
        case 1: return "Battleground"
        case 2: return "Lean"
        case 3: return "Likely"
        default: return "Safe"
        }
    }

    var marginDisplay: String {
        let leader = computedAvgDem > computedAvgRep ? "D" : "R"
        return "\(leader)+\(String(format: "%.1f", forecastedMargin))"
    }

    var lastRefreshedDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastRefreshed, relativeTo: Date())
    }

    init(
        id: UUID = UUID(),
        raceId: String,
        lastRefreshed: Date = Date(),
        computedAvgDem: Double,
        computedAvgRep: Double,
        forecastedWinner: PartyAffiliation? = nil,
        forecastedMargin: Double,
        competitivenessTier: Int
    ) {
        self.id = id
        self.raceId = raceId
        self.lastRefreshed = lastRefreshed
        self.computedAvgDem = computedAvgDem
        self.computedAvgRep = computedAvgRep
        self.forecastedWinner = forecastedWinner
        self.forecastedMargin = forecastedMargin
        self.competitivenessTier = competitivenessTier
    }
}
