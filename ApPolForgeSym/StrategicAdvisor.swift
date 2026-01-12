//
//  StrategicAdvisor.swift
//  ApPolForgeSym
//
//  AI-powered strategic recommendations for campaign management
//

import Foundation
import Combine

@MainActor
class StrategicAdvisor: ObservableObject {
    let gameState: GameState
    
    // Campaign infrastructure tracking
    @Published var incumbentInfrastructure: [UUID: StateCampaignData] = [:]
    @Published var challengerInfrastructure: [UUID: StateCampaignData] = [:]
    
    init(gameState: GameState) {
        self.gameState = gameState
        initializeInfrastructure()
    }
    
    private func initializeInfrastructure() {
        for state in gameState.states {
            let incumbentData = StateCampaignData(
                stateId: state.id,
                electoralVotes: state.electoralVotes,
                isBattleground: state.isBattleground
            )
            let challengerData = StateCampaignData(
                stateId: state.id,
                electoralVotes: state.electoralVotes,
                isBattleground: state.isBattleground
            )
            
            incumbentInfrastructure[state.id] = incumbentData
            challengerInfrastructure[state.id] = challengerData
        }
    }
    
    /// Update AI predictions for staffing based on current game state
    func updateStaffingPredictions(for playerType: PlayerType) {
        let infrastructure = playerType == .incumbent ? incumbentInfrastructure : challengerInfrastructure
        let weeksRemaining = gameState.maxTurns - gameState.currentTurn
        
        for state in gameState.states {
            guard var data = infrastructure[state.id] else { continue }
            
            // AI prediction: more staff needed in competitive states and as election nears
            let competitivenessMultiplier = state.isBattleground ? 2.0 : 1.0
            let urgencyMultiplier = 1.0 + (1.0 - Double(weeksRemaining) / Double(gameState.maxTurns))
            
            // Base calculation on state size and competitiveness
            let baseStaff = state.electoralVotes * 8
            data.recommendedStaffPositions = Int(Double(baseStaff) * competitivenessMultiplier * urgencyMultiplier)
            
            let baseVolunteers = state.electoralVotes * 80
            data.recommendedVolunteers = Int(Double(baseVolunteers) * competitivenessMultiplier * urgencyMultiplier)
            
            // Update infrastructure
            if playerType == .incumbent {
                incumbentInfrastructure[state.id] = data
            } else {
                challengerInfrastructure[state.id] = data
            }
        }
    }
    
    /// Generate strategic recommendations based on polling and game state
    func generateRecommendations(for playerType: PlayerType) -> [StrategicRecommendation] {
        var recommendations: [StrategicRecommendation] = []
        
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let votes = gameState.calculateElectoralVotes()
        let playerVotes = playerType == .incumbent ? votes.incumbent : votes.challenger
        let opponentVotes = playerType == .incumbent ? votes.challenger : votes.incumbent
        
        // 1. Defensive recommendations - protect states we're winning narrowly
        let vulnerableStates = identifyVulnerableStates(for: playerType)
        if !vulnerableStates.isEmpty {
            recommendations.append(createDefensiveRecommendation(
                states: vulnerableStates,
                playerType: playerType
            ))
        }
        
        // 2. Offensive recommendations - target states we can flip
        let flippableStates = identifyFlippableStates(for: playerType)
        if !flippableStates.isEmpty {
            recommendations.append(createOffensiveRecommendation(
                states: flippableStates,
                playerType: playerType
            ))
        }
        
        // 3. Infrastructure recommendations - states with poor ground game
        let infrastructureGaps = identifyInfrastructureGaps(for: playerType)
        if !infrastructureGaps.isEmpty {
            recommendations.append(createInfrastructureRecommendation(
                states: infrastructureGaps,
                playerType: playerType
            ))
        }
        
        // 4. Fundraising recommendation if funds are low
        if player.campaignFunds < 10_000_000 {
            recommendations.append(createFundraisingRecommendation(
                playerType: playerType,
                currentFunds: player.campaignFunds
            ))
        }
        
        // 5. Momentum recommendation if losing badly
        if playerVotes < opponentVotes - 50 {
            recommendations.append(createMomentumRecommendation(
                playerType: playerType,
                deficit: opponentVotes - playerVotes
            ))
        }
        
        // Sort by priority
        return recommendations.sorted { rec1, rec2 in
            priorityValue(rec1.priority) > priorityValue(rec2.priority)
        }
    }
    
    private func identifyVulnerableStates(for playerType: PlayerType) -> [ElectoralState] {
        return gameState.states.filter { state in
            let ourSupport = playerType == .incumbent ? state.incumbentSupport : state.challengerSupport
            let theirSupport = playerType == .incumbent ? state.challengerSupport : state.incumbentSupport
            
            // We're winning but by less than 7 points
            return ourSupport > theirSupport && (ourSupport - theirSupport) < 7
        }.sorted { $0.electoralVotes > $1.electoralVotes }
    }
    
    private func identifyFlippableStates(for playerType: PlayerType) -> [ElectoralState] {
        return gameState.states.filter { state in
            let ourSupport = playerType == .incumbent ? state.incumbentSupport : state.challengerSupport
            let theirSupport = playerType == .incumbent ? state.challengerSupport : state.incumbentSupport
            
            // We're losing but within reach (less than 8 points behind)
            return theirSupport > ourSupport && (theirSupport - ourSupport) < 8
        }.sorted { $0.electoralVotes > $1.electoralVotes }
    }
    
    private func identifyInfrastructureGaps(for playerType: PlayerType) -> [ElectoralState] {
        let infrastructure = playerType == .incumbent ? incumbentInfrastructure : challengerInfrastructure
        
        return gameState.states.filter { state in
            guard let data = infrastructure[state.id] else { return false }
            return data.infrastructureScore < 60 && state.isBattleground
        }.sorted { $0.electoralVotes > $1.electoralVotes }
    }
    
    private func createDefensiveRecommendation(
        states: [ElectoralState],
        playerType: PlayerType
    ) -> StrategicRecommendation {
        let topStates = Array(states.prefix(3))
        let totalEV = topStates.reduce(0) { $0 + $1.electoralVotes }
        
        return StrategicRecommendation(
            type: .defensive,
            priority: .critical,
            title: "Shore Up Vulnerable States",
            description: "You're leading in \(topStates.count) key state(s) but margins are thin. Defensive action needed.",
            targetStates: topStates.map { $0.id },
            suggestedActions: [.grassroots, .townHall, .adCampaign],
            estimatedCost: Double(topStates.count) * 2_000_000,
            expectedImpact: "Secure \(totalEV) electoral votes",
            reasoning: "These states have narrow margins (<7 points). Grassroots organizing and town halls will solidify support."
        )
    }
    
    private func createOffensiveRecommendation(
        states: [ElectoralState],
        playerType: PlayerType
    ) -> StrategicRecommendation {
        let topStates = Array(states.prefix(3))
        let totalEV = topStates.reduce(0) { $0 + $1.electoralVotes }
        
        return StrategicRecommendation(
            type: .offensive,
            priority: .high,
            title: "Flip Competitive States",
            description: "Target \(topStates.count) winnable state(s) worth \(totalEV) electoral votes.",
            targetStates: topStates.map { $0.id },
            suggestedActions: [.rally, .adCampaign, .townHall],
            estimatedCost: Double(topStates.count) * 2_500_000,
            expectedImpact: "Potential to gain \(totalEV) electoral votes",
            reasoning: "You're within striking distance (<8 points behind). Rallies and ad campaigns can close the gap."
        )
    }
    
    private func createInfrastructureRecommendation(
        states: [ElectoralState],
        playerType: PlayerType
    ) -> StrategicRecommendation {
        let topStates = Array(states.prefix(2))
        
        return StrategicRecommendation(
            type: .infrastructure,
            priority: .high,
            title: "Build Ground Game",
            description: "Your field organization is weak in \(topStates.count) battleground state(s).",
            targetStates: topStates.map { $0.id },
            suggestedActions: [.grassroots, .townHall],
            estimatedCost: Double(topStates.count) * 800_000,
            expectedImpact: "Improved turnout and long-term support",
            reasoning: "Infrastructure score is below 60%. Building field offices and recruiting volunteers will pay off."
        )
    }
    
    private func createFundraisingRecommendation(
        playerType: PlayerType,
        currentFunds: Double
    ) -> StrategicRecommendation {
        StrategicRecommendation(
            type: .fundraising,
            priority: currentFunds < 5_000_000 ? .critical : .high,
            title: "Replenish Campaign Funds",
            description: "Treasury is running low at \(currentFunds.asCurrency()). Fundraising needed.",
            targetStates: [],
            suggestedActions: [.fundraiser],
            estimatedCost: 100_000,
            expectedImpact: "Raise $1-3M to continue operations",
            reasoning: "Current funds won't sustain campaign through election. Hold multiple fundraisers."
        )
    }
    
    private func createMomentumRecommendation(
        playerType: PlayerType,
        deficit: Int
    ) -> StrategicRecommendation {
        StrategicRecommendation(
            type: .momentum,
            priority: .critical,
            title: "Change Campaign Narrative",
            description: "You're down \(deficit) electoral votes. Need to shift momentum.",
            targetStates: [],
            suggestedActions: [.debate, .opposition, .rally],
            estimatedCost: 2_000_000,
            expectedImpact: "Boost national profile and momentum",
            reasoning: "Facing significant deficit. Debate prep and opposition research can change the race dynamics."
        )
    }
    
    /// Calculate detailed analytics for a player
    func calculateAnalytics(for playerType: PlayerType) -> CampaignAnalytics {
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let weeksRemaining = gameState.maxTurns - gameState.currentTurn
        
        // Simple burn rate estimation
        let averageActionCost = 1_500_000.0
        let burnRate = averageActionCost
        let projectedEndgameFunds = player.campaignFunds - (burnRate * Double(weeksRemaining))
        
        // Calculate electoral vote breakdown
        var secure = 0
        var likely = 0
        var leaning = 0
        var tossup = 0
        
        for state in gameState.states {
            let ourSupport = playerType == .incumbent ? state.incumbentSupport : state.challengerSupport
            let theirSupport = playerType == .incumbent ? state.challengerSupport : state.incumbentSupport
            let margin = ourSupport - theirSupport
            
            if margin > 10 {
                secure += state.electoralVotes
            } else if margin > 5 {
                likely += state.electoralVotes
            } else if margin > 0 {
                leaning += state.electoralVotes
            } else if margin > -5 {
                tossup += state.electoralVotes
            }
        }
        
        // Calculate paths to 270 (simplified - just show we have some paths)
        let pathsTo270 = findPathsTo270(for: playerType)
        
        return CampaignAnalytics(
            playerType: playerType,
            currentFunds: player.campaignFunds,
            projectedEndgameFunds: projectedEndgameFunds,
            burnRate: burnRate,
            weeksRemaining: weeksRemaining,
            secureElectoralVotes: secure,
            likelyElectoralVotes: likely,
            leaningElectoralVotes: leaning,
            tossupElectoralVotes: tossup,
            pathsTo270: pathsTo270
        )
    }
    
    private func findPathsTo270(for playerType: PlayerType) -> [[UUID]] {
        // Simplified: find combinations of tossup/leaning states that get us to 270
        var paths: [[UUID]] = []
        
        let votes = gameState.calculateElectoralVotes()
        let currentVotes = playerType == .incumbent ? votes.incumbent : votes.challenger
        
        if currentVotes >= 270 {
            // Already winning
            paths.append([])
        } else {
            // Find winnable states
            let winnableStates = gameState.states.filter { state in
                let ourSupport = playerType == .incumbent ? state.incumbentSupport : state.challengerSupport
                let theirSupport = playerType == .incumbent ? state.challengerSupport : state.incumbentSupport
                return theirSupport > ourSupport && (theirSupport - ourSupport) < 10
            }.sorted { $0.electoralVotes > $1.electoralVotes }
            
            // Simple greedy path: take largest states until we hit 270
            var neededVotes = 270 - currentVotes
            var currentPath: [UUID] = []
            
            for state in winnableStates {
                if neededVotes > 0 {
                    currentPath.append(state.id)
                    neededVotes -= state.electoralVotes
                }
            }
            
            if neededVotes <= 0 {
                paths.append(currentPath)
            }
        }
        
        return paths
    }
    
    private func priorityValue(_ priority: RecommendationPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

