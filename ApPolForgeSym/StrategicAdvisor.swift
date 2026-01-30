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
        let weeksRemaining = gameState.maxTurns - gameState.currentTurn

        for state in gameState.states {
            guard var data = (playerType == .incumbent ? incumbentInfrastructure : challengerInfrastructure)[state.id] else { continue }

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

        // Also update current staffing levels
        updateCurrentInfrastructure(for: playerType)
    }

    /// Update current staff and volunteer counts based on game progression
    /// This simulates realistic campaign infrastructure buildup over time
    func updateCurrentInfrastructure(for playerType: PlayerType) {
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let currentTurn = gameState.currentTurn
        let maxTurns = gameState.maxTurns

        // Campaign progression factor (0.0 at start, 1.0 at end)
        let progressFactor = Double(currentTurn) / Double(maxTurns)

        // Campaign health factor based on funds and momentum
        let startingFunds = playerType == .incumbent ? 220_000_000.0 : 150_000_000.0
        let fundHealthFactor = min(player.campaignFunds / startingFunds, 1.5) // Can exceed 1.0 if fundraising went well
        let momentumFactor = (Double(player.momentum) + 100.0) / 200.0 // Normalize -100..100 to 0..1
        let campaignHealthFactor = (fundHealthFactor * 0.6 + momentumFactor * 0.4)

        for state in gameState.states {
            guard var data = (playerType == .incumbent ? incumbentInfrastructure : challengerInfrastructure)[state.id] else { continue }

            // Base staffing grows with campaign progression
            // Campaigns typically start with skeleton crews and ramp up toward election
            let baseProgress = progressFactor * 0.7 + 0.15 // Start at 15%, grow to 85% by election

            // Battleground states get more attention earlier
            let battlegroundBonus = state.isBattleground ? 0.2 : 0.0

            // Calculate current staff positions
            let staffProgress = min(baseProgress + battlegroundBonus, 1.0) * campaignHealthFactor
            let targetStaff = Double(data.recommendedStaffPositions)
            // Add some randomness for realism (±10%)
            let staffVariance = Double.random(in: 0.9...1.1)
            data.currentStaffPositions = max(1, Int(targetStaff * staffProgress * staffVariance))

            // Volunteers are typically 5-10x staff numbers and build more organically
            // They grow faster in later weeks as enthusiasm builds
            let volunteerProgress = min(baseProgress * 1.2 + battlegroundBonus, 1.0) * campaignHealthFactor
            let targetVolunteers = Double(data.recommendedVolunteers)
            let volunteerVariance = Double.random(in: 0.85...1.15)
            data.currentVolunteers = max(5, Int(targetVolunteers * volunteerProgress * volunteerVariance))

            // Field offices, phonebanks, and canvassing teams also grow
            let infrastructureProgress = progressFactor * campaignHealthFactor
            let baseOffices = state.isBattleground ? 3 : 1
            data.fieldOffices = max(1, Int(Double(baseOffices + state.electoralVotes / 10) * infrastructureProgress))
            data.phonebanks = max(1, Int(Double(state.electoralVotes / 5) * infrastructureProgress * (state.isBattleground ? 1.5 : 1.0)))
            data.canvassingTeams = max(2, Int(Double(state.electoralVotes) * infrastructureProgress * (state.isBattleground ? 2.0 : 1.0)))

            // Update the infrastructure dictionary
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
    
    /// Returns the recommended number of actions for this turn based on Critical/High recommendations.
    func recommendedActionCount(for playerType: PlayerType) -> Int {
        let recommendations = generateRecommendations(for: playerType)
        let criticalCount = min(recommendations.filter({ $0.priority == .critical }).count, 2)
        let highCount = min(recommendations.filter({ $0.priority == .high }).count, 1)
        return min(1 + criticalCount + highCount, 4)
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

