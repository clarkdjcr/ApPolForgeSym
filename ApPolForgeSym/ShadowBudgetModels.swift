//
//  ShadowBudgetModels.swift
//  ApPolForgeSym
//
//  The "Nixon Disease" - Black Ops and Espionage Mechanics
//

import Foundation

// MARK: - Shadow Budget Zone

enum ShadowBudgetZone: String, Codable {
    case transparent = "Transparent Operations"
    case aggressive = "Aggressive Research"
    case blackOps = "Black Ops / Espionage"
    
    var color: String {
        switch self {
        case .transparent: return "#4CAF50" // Green
        case .aggressive: return "#FFC107" // Yellow/Orange
        case .blackOps: return "#F44336" // Red
        }
    }
    
    var range: ClosedRange<Double> {
        switch self {
        case .transparent: return 0...5
        case .aggressive: return 6...15
        case .blackOps: return 16...30
        }
    }
    
    static func zone(for percentage: Double) -> ShadowBudgetZone {
        if percentage <= 5 {
            return .transparent
        } else if percentage <= 15 {
            return .aggressive
        } else {
            return .blackOps
        }
    }
}

// MARK: - Shadow Budget State

struct ShadowBudgetState: Codable {
    var allocationPercentage: Double = 0.0
    var turnsInGreenZone: Int = 0
    var hasIntegrityBonus: Bool = false
    var hasTeflonShield: Bool = false
    var detectionRisk: Double = 0.0
    var usesShellCompanies: Bool = false
    var counterIntelLevel: Double = 1.0
    var totalSpentOnShadowOps: Double = 0.0
    
    // Operation results
    var hasStolenOpponentData: Bool = false
    var activeSabotages: [String] = []
    var collectedDirt: [String] = []
    
    // Detection history
    var hasBeenCaught: Bool = false
    var activeScandals: [ShadowBudgetScandal] = []
    
    mutating func reset() {
        allocationPercentage = 0.0
        usesShellCompanies = false
    }
    
    var currentZone: ShadowBudgetZone {
        ShadowBudgetZone.zone(for: allocationPercentage)
    }
}

// MARK: - Shadow Operations

enum ShadowOperationType: String, Codable, CaseIterable, Identifiable {
    case dataTheft = "Data Theft"
    case sabotage = "Technical Sabotage"
    case opponentResearch = "Opposition Dirt"
    case voterSuppression = "Voter Suppression"
    case mediaManipulation = "Media Manipulation"

    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .dataTheft:
            return "Steal opponent's voter data and blind their analytics"
        case .sabotage:
            return "Disrupt opponent's campaign operations for 1 turn"
        case .opponentResearch:
            return "Uncover damaging information about opponent"
        case .voterSuppression:
            return "Suppress turnout in opponent's strong states"
        case .mediaManipulation:
            return "Plant negative stories about opponent"
        }
    }
    
    var baseCost: Double {
        switch self {
        case .dataTheft: return 5_000_000
        case .sabotage: return 3_000_000
        case .opponentResearch: return 4_000_000
        case .voterSuppression: return 6_000_000
        case .mediaManipulation: return 3_500_000
        }
    }
    
    var minimumAllocation: Double {
        switch self {
        case .dataTheft: return 15
        case .sabotage: return 10
        case .opponentResearch: return 12
        case .voterSuppression: return 20
        case .mediaManipulation: return 8
        }
    }
    
    var baseDetectionRisk: Double {
        switch self {
        case .dataTheft: return 0.25
        case .sabotage: return 0.18
        case .opponentResearch: return 0.15
        case .voterSuppression: return 0.35
        case .mediaManipulation: return 0.12
        }
    }
}

struct ShadowOperation: Identifiable, Codable {
    let id: UUID
    let type: ShadowOperationType
    let turn: Int
    let cost: Double
    let detectionRisk: Double
    let success: Bool
    
    init(
        id: UUID = UUID(),
        type: ShadowOperationType,
        turn: Int,
        cost: Double,
        detectionRisk: Double,
        success: Bool
    ) {
        self.id = id
        self.type = type
        self.turn = turn
        self.cost = cost
        self.detectionRisk = detectionRisk
        self.success = success
    }
}

// MARK: - Shadow Budget Scandal

struct ShadowBudgetScandal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let severity: ScandalSeverity
    let turn: Int
    let operationType: ShadowOperationType
    let pollingImpact: Double // Negative number
    let fundingFreeze: Int // Number of turns
    let wasLaundered: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        severity: ScandalSeverity,
        turn: Int,
        operationType: ShadowOperationType,
        pollingImpact: Double,
        fundingFreeze: Int,
        wasLaundered: Bool
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.turn = turn
        self.operationType = operationType
        self.pollingImpact = pollingImpact
        self.fundingFreeze = fundingFreeze
        self.wasLaundered = wasLaundered
    }
}

enum ScandalSeverity: String, Codable {
    case minor = "Minor"
    case major = "Major"
    case campaignEnding = "Campaign-Ending"
    
    var pollingPenalty: Double {
        switch self {
        case .minor: return -5.0
        case .major: return -15.0
        case .campaignEnding: return -30.0
        }
    }
    
    var fundingFreeze: Int {
        switch self {
        case .minor: return 1
        case .major: return 2
        case .campaignEnding: return 4
        }
    }
}

// MARK: - Integrity Bonuses

struct IntegrityBonus: Codable {
    var fundraisingMultiplier: Double = 1.0
    var hasTeflonShield: Bool = false
    var turnsActive: Int = 0
    var reputation: Double = 50.0 // 0-100 scale
    
    mutating func applyBonus() {
        fundraisingMultiplier = 1.2
        hasTeflonShield = true
        reputation = min(100, reputation + 10)
    }
    
    mutating func removeBonus() {
        fundraisingMultiplier = 1.0
        hasTeflonShield = false
    }
    
    mutating func damageReputation(_ amount: Double) {
        reputation = max(0, reputation - amount)
        if reputation < 30 {
            removeBonus()
        }
    }
}

// MARK: - Shell Company System

struct ShellCompanyLayer: Codable {
    var isActive: Bool = false
    var costMultiplier: Double = 2.0
    var detectionReduction: Double = 0.5
    var layersDeep: Int = 1
    
    var setupCost: Double {
        return 2_000_000 * Double(layersDeep)
    }
    
    var monthlyMaintenance: Double {
        return 500_000 * Double(layersDeep)
    }
    
    mutating func addLayer() {
        layersDeep += 1
        detectionReduction = min(0.8, detectionReduction + 0.15)
        costMultiplier += 0.3
    }
}

// MARK: - AI Opponent Personality for Shadow Ops

enum AISpyPersonality: String, Codable {
    case moralist = "The Moralist"
    case machiavellian = "The Machiavellian"
    case cautious = "The Cautious"
    case reckless = "The Reckless"
    
    var description: String {
        switch self {
        case .moralist:
            return "Always keeps slider <5%. Plays victim card when attacked."
        case .machiavellian:
            return "Fluctuates wildly. Spikes to 30% at critical moments."
        case .cautious:
            return "Uses 8-12% consistently. Plays it safe."
        case .reckless:
            return "Frequently operates at 20%+. High risk, high reward."
        }
    }
    
    func determineAllocation(turn: Int, isWinning: Bool, hasBeenCaught: Bool) -> Double {
        if hasBeenCaught {
            return 0.0 // Lie low after scandal
        }
        
        switch self {
        case .moralist:
            return Double.random(in: 0...4)
            
        case .machiavellian:
            // Spike before major events
            if turn % 5 == 0 || !isWinning {
                return Double.random(in: 25...30)
            } else {
                return Double.random(in: 0...3)
            }
            
        case .cautious:
            return Double.random(in: 8...12)
            
        case .reckless:
            if !isWinning {
                return Double.random(in: 22...28)
            } else {
                return Double.random(in: 15...20)
            }
        }
    }
}

// MARK: - Denial System

struct DenialAttempt: Codable {
    let scandalId: UUID
    let turn: Int
    var successChance: Double
    var succeeded: Bool = false
    
    init(scandalId: UUID, turn: Int, integrityScore: Double) {
        self.scandalId = scandalId
        self.turn = turn
        
        // Base 30% chance, +1% per integrity point
        self.successChance = 0.30 + (integrityScore / 100.0 * 0.4)
    }
    
    mutating func attemptDenial() -> Bool {
        succeeded = Double.random(in: 0...1) < successChance
        return succeeded
    }
}
