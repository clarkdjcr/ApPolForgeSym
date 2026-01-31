//
//  CampaignDataLoader.swift
//  ApPolForgeSym
//
//  Loads real campaign data from bundled JSON for all 50 states + DC
//

import Foundation

// MARK: - JSON Data Structures

struct CampaignDataFile: Codable {
    let metadata: CampaignMetadata
    let states: [StateDataEntry]
}

struct CampaignMetadata: Codable {
    let totalElectoralVotes: Int
    let totalBudgetAllStatesM: Double
    let stateCount: Int
}

struct StateDataEntry: Codable {
    let name: String
    let abbreviation: String
    let electoralVotes: Int
    let region: String
    let competitivenessTier: Int
    let historical: HistoricalData
    let actionEffectiveness: ActionEffectivenessData
    let roi: ROIData
    let staffing: StaffingData
    let budget: BudgetData
    let weeklyPacing: [WeeklyPacingEntry]
}

struct HistoricalData: Codable {
    let winner2020: String
    let winner2016: String
    let winner2012: String
    let winner2008: String
    let margin2020: Double
    let margin2016: Double
    let margin2012: Double
    let margin2008: Double
    let trend: String
    let turnout2020: Double
    let turnout2016: Double
}

struct ActionEffectivenessData: Codable {
    let townHall: Int
    let adCampaign: Int
    let debate: Int
    let rally: Int
    let opposition: Int
    let grassroots: Int
    let fundraiser: Int
}

struct ROIData: Codable {
    let swingPotentialScore: Int
    let roiRating: String
    let spendEfficiencyRating: String
    let costPerEV: Double
    let totalSpend2020M: Double
    let mediaMarketCostIndex: Double
}

struct StaffingData: Codable {
    let totalStaff: Int
    let stateLeadership: Int
    let fieldOrganizers: Int
    let communicationsStaff: Int
    let regionalOffices: Int
    let activeVolunteersPeak: Int
    let volunteerShiftsFinalMonth: Int
    let registeredVoters: Int
}

struct BudgetData: Codable {
    let totalBudgetM: Double
    let staffPayrollM: Double
    let tvAdvertisingM: Double
    let digitalAdvertisingM: Double
    let gotvOperationsM: Double
    let earlyVoteInvestmentPct: Double
}

struct WeeklyPacingEntry: Codable {
    let week: Int
    let staff: Int
    let volunteers: Int
    let budgetK: Double
}

// MARK: - Campaign Data Loader

class CampaignDataLoader {
    static let shared = CampaignDataLoader()

    private var cachedData: CampaignDataFile?

    private init() {}

    /// Load and cache the campaign data from the app bundle
    func loadData() -> CampaignDataFile? {
        if let cached = cachedData { return cached }

        guard let url = Bundle.main.url(forResource: "CampaignData", withExtension: "json") else {
            print("CampaignDataLoader: CampaignData.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CampaignDataFile.self, from: data)
            cachedData = decoded
            return decoded
        } catch {
            print("CampaignDataLoader: Failed to decode CampaignData.json: \(error)")
            return nil
        }
    }

    /// Create all ElectoralState objects from real data
    func loadStates() -> [ElectoralState] {
        guard let campaignData = loadData() else {
            // Fallback to empty array — caller can handle
            return []
        }

        return campaignData.states.map { entry in
            // Derive initial support from weighted historical margins
            // 2020×0.4 + 2016×0.3 + 2012×0.2 + 2008×0.1
            let weightedMargin =
                entry.historical.margin2020 * 0.4 +
                entry.historical.margin2016 * 0.3 +
                entry.historical.margin2012 * 0.2 +
                entry.historical.margin2008 * 0.1

            // Determine which party the margin favors based on 2020 winner
            let isDemLeaning = entry.historical.winner2020 == "D"

            // Add ±3pt random noise for variety
            let noise = Double.random(in: -3...3)
            let adjustedMargin = weightedMargin + noise

            // Base at 50/50, then shift by half the margin to each side
            let halfMargin = adjustedMargin / 2.0
            let incumbentSupport: Double
            let challengerSupport: Double

            if isDemLeaning {
                // Incumbent (Liberty/Blue) leads in D-leaning states
                incumbentSupport = min(max(50.0 + halfMargin, 25), 75)
                challengerSupport = min(max(50.0 - halfMargin, 25), 75)
            } else {
                // Challenger (Progress/Red) leads in R-leaning states
                incumbentSupport = min(max(50.0 - halfMargin, 25), 75)
                challengerSupport = min(max(50.0 + halfMargin, 25), 75)
            }

            // Build action effectiveness dictionary
            let actionEffectiveness: [String: Int] = [
                "rally": entry.actionEffectiveness.rally,
                "adCampaign": entry.actionEffectiveness.adCampaign,
                "fundraiser": entry.actionEffectiveness.fundraiser,
                "townHall": entry.actionEffectiveness.townHall,
                "debate": entry.actionEffectiveness.debate,
                "grassroots": entry.actionEffectiveness.grassroots,
                "opposition": entry.actionEffectiveness.opposition,
            ]

            return ElectoralState(
                name: entry.name,
                abbreviation: entry.abbreviation,
                electoralVotes: entry.electoralVotes,
                incumbentSupport: incumbentSupport,
                challengerSupport: challengerSupport,
                region: entry.region,
                competitivenessTier: entry.competitivenessTier,
                swingPotentialScore: entry.roi.swingPotentialScore,
                roiRating: entry.roi.roiRating,
                spendEfficiency: entry.roi.spendEfficiencyRating,
                actionEffectiveness: actionEffectiveness,
                mediaMarketCostIndex: entry.roi.mediaMarketCostIndex
            )
        }
    }

    /// Get weekly pacing target for a state at a given game week (1-20)
    func weeklyTarget(for stateName: String, week: Int) -> WeeklyPacingEntry? {
        guard let data = loadData(),
              let stateEntry = data.states.first(where: { $0.name == stateName }),
              week >= 1, week <= 20 else {
            return nil
        }
        return stateEntry.weeklyPacing.first(where: { $0.week == week })
    }

    /// Get staffing data for a state
    func staffingData(for stateName: String) -> StaffingData? {
        guard let data = loadData() else { return nil }
        return data.states.first(where: { $0.name == stateName })?.staffing
    }

    /// Get budget data for a state
    func budgetData(for stateName: String) -> BudgetData? {
        guard let data = loadData() else { return nil }
        return data.states.first(where: { $0.name == stateName })?.budget
    }

    /// Recommended starting funds derived from real total budgets
    /// Based on ~55/45 incumbent/challenger split of total campaign spending
    func recommendedStartingFunds() -> (incumbent: Double, challenger: Double) {
        guard let data = loadData() else {
            return (220_000_000, 150_000_000)
        }

        // Total budget across all states in millions
        let totalM = data.metadata.totalBudgetAllStatesM
        // Convert to actual dollars, use 20% for game balance (players earn more via fundraising)
        let totalDollars = totalM * 1_000_000 * 0.20
        let incumbentFunds = totalDollars * 0.55
        let challengerFunds = totalDollars * 0.45

        return (incumbentFunds, challengerFunds)
    }
}
