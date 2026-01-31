//
//  EnhancedGameModels.swift
//  ApPolForgeSym
//
//  Enhanced models for realistic campaign simulation
//

import Foundation

// MARK: - State Campaign Infrastructure

struct StateCampaignData: Codable, Identifiable {
    let id: UUID
    let stateId: UUID
    
    // AI-predicted staffing levels
    var recommendedStaffPositions: Int
    var currentStaffPositions: Int
    var recommendedVolunteers: Int
    var currentVolunteers: Int
    
    // Infrastructure investment
    var fieldOffices: Int
    var phonebanks: Int
    var canvassingTeams: Int
    
    // Historical spending in this state
    var totalSpent: Double
    
    init(stateId: UUID, electoralVotes: Int, isBattleground: Bool, stateName: String? = nil) {
        self.id = UUID()
        self.stateId = stateId

        // Try to use real data from CampaignDataLoader
        if let name = stateName,
           let staffing = CampaignDataLoader.shared.staffingData(for: name) {
            self.recommendedStaffPositions = staffing.totalStaff
            self.recommendedVolunteers = staffing.activeVolunteersPeak
            self.fieldOffices = staffing.regionalOffices
        } else {
            // Fallback to formula-based calculation
            let baseStaff = electoralVotes * (isBattleground ? 10 : 3)
            let baseVolunteers = electoralVotes * (isBattleground ? 100 : 30)
            self.recommendedStaffPositions = baseStaff
            self.recommendedVolunteers = baseVolunteers
            self.fieldOffices = 0
        }

        self.currentStaffPositions = 0
        self.currentVolunteers = 0
        self.phonebanks = 0
        self.canvassingTeams = 0
        self.totalSpent = 0.0
    }
    
    /// Calculate staffing efficiency (0.0 to 1.0+)
    var staffingEfficiency: Double {
        guard recommendedStaffPositions > 0 else { return 1.0 }
        return Double(currentStaffPositions) / Double(recommendedStaffPositions)
    }
    
    /// Calculate volunteer mobilization (0.0 to 1.0+)
    var volunteerMobilization: Double {
        guard recommendedVolunteers > 0 else { return 1.0 }
        return Double(currentVolunteers) / Double(recommendedVolunteers)
    }
    
    /// Overall infrastructure score
    var infrastructureScore: Double {
        let staffScore = min(staffingEfficiency, 1.0) * 0.4
        let volunteerScore = min(volunteerMobilization, 1.0) * 0.3
        let facilityScore = Double(min(fieldOffices * 10 + phonebanks * 5 + canvassingTeams * 3, 100)) / 100.0 * 0.3
        return (staffScore + volunteerScore + facilityScore) * 100
    }
}

// MARK: - Strategic Recommendation

enum RecommendationPriority: String, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum RecommendationType: String, Codable {
    case defensive = "Defensive"
    case offensive = "Offensive"
    case infrastructure = "Infrastructure"
    case fundraising = "Fundraising"
    case momentum = "Momentum"
}

struct StrategicRecommendation: Identifiable, Codable {
    let id: UUID
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let targetStates: [UUID] // State IDs
    let suggestedActions: [CampaignActionType]
    let estimatedCost: Double
    let expectedImpact: String
    let reasoning: String
    
    init(
        id: UUID = UUID(),
        type: RecommendationType,
        priority: RecommendationPriority,
        title: String,
        description: String,
        targetStates: [UUID],
        suggestedActions: [CampaignActionType],
        estimatedCost: Double,
        expectedImpact: String,
        reasoning: String
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.title = title
        self.description = description
        self.targetStates = targetStates
        self.suggestedActions = suggestedActions
        self.estimatedCost = estimatedCost
        self.expectedImpact = expectedImpact
        self.reasoning = reasoning
    }
}

// MARK: - Multi-State Campaign Action

struct MultiStateAction: Identifiable {
    let id: UUID
    let type: CampaignActionType
    let targetStates: [ElectoralState]
    let player: PlayerType
    let turn: Int
    
    /// Calculate total cost for multi-state action
    var totalCost: Double {
        // Base cost + additional cost per extra state (20% per state)
        let baseCost = type.cost
        let extraStates = max(0, targetStates.count - 1)
        return baseCost * (1.0 + Double(extraStates) * 0.2)
    }
    
    init(
        id: UUID = UUID(),
        type: CampaignActionType,
        targetStates: [ElectoralState],
        player: PlayerType,
        turn: Int
    ) {
        self.id = id
        self.type = type
        self.targetStates = targetStates
        self.player = player
        self.turn = turn
    }
}

// MARK: - Campaign Analytics

struct CampaignAnalytics {
    let playerType: PlayerType
    let currentFunds: Double
    let projectedEndgameFunds: Double
    let burnRate: Double // Per week
    let weeksRemaining: Int
    
    // Electoral math
    let secureElectoralVotes: Int
    let likelyElectoralVotes: Int
    let leaningElectoralVotes: Int
    let tossupElectoralVotes: Int
    
    // Path to victory
    let pathsTo270: [[UUID]] // Arrays of state IDs that lead to 270
    
    var canAffordRestOfCampaign: Bool {
        projectedEndgameFunds >= 0
    }
    
    var fundingAlert: String? {
        if projectedEndgameFunds < 0 {
            return "⚠️ Campaign will run out of money before Election Day"
        } else if projectedEndgameFunds < 5_000_000 {
            return "⚠️ Low funds projected by Election Day"
        }
        return nil
    }
}

// MARK: - AI Strategy Predictor

struct AIStrategyPrediction {
    let opponentNextAction: CampaignActionType
    let confidence: Double // 0.0 to 1.0
    let likelyTargetStates: [UUID]
    let reasoning: String
}
