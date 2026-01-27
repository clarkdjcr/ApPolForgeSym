//
//  AIOpponent.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import Foundation

@MainActor
class AIOpponent {
    let gameState: GameState
    private let difficulty: AIDifficulty
    
    init(gameState: GameState, difficulty: AIDifficulty? = nil) {
        self.gameState = gameState
        self.difficulty = difficulty ?? AppSettings.shared.aiDifficulty
    }
    
    /// AI makes a decision about what action to take
    func makeDecision() async {
        // Wait a moment to simulate thinking (use user's setting)
        let aiSpeed = AppSettings.shared.aiSpeed
        try? await Task.sleep(for: .seconds(aiSpeed))
        
        // AI Strategy Logic based on difficulty
        let strategy = determineStrategy()
        
        switch strategy {
        case .aggressive:
            await executeAggressiveStrategy()
        case .defensive:
            await executeDefensiveStrategy()
        case .balanced:
            await executeBalancedStrategy()
        case .fundraising:
            await executeFundraisingStrategy()
        case .multiState:
            await executeMultiStateStrategy()
        }
    }
    
    enum AIStrategy {
        case aggressive   // Focus on attacking and swing states
        case defensive    // Protect current leads
        case balanced     // Mix of offense and defense
        case fundraising  // Need money
        case multiState   // Coordinate multi-state actions (higher difficulty)
    }
    
    private func determineStrategy() -> AIStrategy {
        let challenger = gameState.challenger
        let votes = gameState.calculateElectoralVotes()
        let turnsRemaining = gameState.maxTurns - gameState.currentTurn
        
        // Higher difficulty = smarter fund management
        let fundThreshold: Double = switch difficulty {
        case .easy: 1_000_000
        case .medium: 2_000_000
        case .hard: 3_000_000
        case .expert: 4_000_000
        }
        
        // If low on funds, prioritize fundraising
        if challenger.campaignFunds < fundThreshold {
            return .fundraising
        }
        
        // Expert and Hard AI can use multi-state strategy
        if difficulty == .expert || difficulty == .hard {
            // Late game with enough funds? Go multi-state
            if turnsRemaining < 8 && challenger.campaignFunds > 10_000_000 {
                return .multiState
            }
        }
        
        // If winning by a lot, play defensive
        if votes.challenger > votes.incumbent + 50 {
            return .defensive
        }
        
        // If losing badly and late in game, go aggressive
        if votes.challenger < votes.incumbent - 30 && turnsRemaining < 10 {
            return .aggressive
        }
        
        // Early game and behind? Build up
        if turnsRemaining > 15 && votes.challenger < votes.incumbent {
            return .balanced
        }
        
        // Otherwise, assess competitiveness
        let margin = abs(votes.challenger - votes.incumbent)
        if margin < 30 {
            return .aggressive
        }
        
        return .balanced
    }
    
    private func executeAggressiveStrategy() async {
        let challenger = gameState.challenger
        
        // Smart targeting based on difficulty
        let targetStates = gameState.states
            .filter { state in
                let margin = state.challengerSupport - state.incumbentSupport
                let isCompetitive = margin > -15 && margin < 10
                let isValuable = state.electoralVotes >= (difficulty == .easy ? 6 : 4)
                
                return (state.isBattleground || isCompetitive) && isValuable
            }
            .sorted { state1, state2 in
                // Prioritize by efficiency: EV per point of support needed
                let margin1 = max(0, state1.incumbentSupport - state1.challengerSupport)
                let margin2 = max(0, state2.incumbentSupport - state2.challengerSupport)
                let efficiency1 = Double(state1.electoralVotes) / (margin1 + 1)
                let efficiency2 = Double(state2.electoralVotes) / (margin2 + 1)
                return efficiency1 > efficiency2
            }
        
        guard let targetState = targetStates.first else {
            await executeBalancedStrategy()
            return
        }
        
        // Choose actions based on effectiveness and difficulty
        let aggressiveActions: [CampaignActionType]
        switch difficulty {
        case .easy:
            aggressiveActions = [.rally, .adCampaign]
        case .medium:
            aggressiveActions = [.adCampaign, .rally, .townHall]
        case .hard, .expert:
            aggressiveActions = [.adCampaign, .opposition, .rally]
        }
        
        let availableActions = aggressiveActions.filter { challenger.campaignFunds >= $0.cost * 1.2 }
        
        guard let actionType = availableActions.first else {
            await executeFundraisingStrategy()
            return
        }
        
        let action = CampaignAction(
            type: actionType,
            targetState: actionType == .opposition ? nil : targetState,
            player: .challenger,
            turn: gameState.currentTurn
        )

        reportAction(actionType: actionType, targetState: actionType == .opposition ? nil : targetState, strategy: .aggressive)
        gameState.executeAction(action)
        gameState.endTurn()
    }

    private func executeDefensiveStrategy() async {
        let challenger = gameState.challenger
        
        // Find vulnerable states with smart prioritization
        let vulnerableStates = gameState.states
            .filter { state in
                let margin = state.challengerSupport - state.incumbentSupport
                return margin > 0 && margin < 12
            }
            .sorted { state1, state2 in
                // Prioritize by electoral value and vulnerability
                let margin1 = state1.challengerSupport - state1.incumbentSupport
                let margin2 = state2.challengerSupport - state2.incumbentSupport
                let priority1 = Double(state1.electoralVotes) * (15.0 - margin1)
                let priority2 = Double(state2.electoralVotes) * (15.0 - margin2)
                return priority1 > priority2
            }
        
        guard let targetState = vulnerableStates.first else {
            await executeBalancedStrategy()
            return
        }
        
        // Choose defensive actions
        let defensiveActions: [CampaignActionType] = [.townHall, .grassroots, .rally, .adCampaign]
        let availableActions = defensiveActions.filter { challenger.campaignFunds >= $0.cost * 1.2 }
        
        guard let actionType = availableActions.first else {
            await executeFundraisingStrategy()
            return
        }
        
        let action = CampaignAction(
            type: actionType,
            targetState: targetState,
            player: .challenger,
            turn: gameState.currentTurn
        )

        reportAction(actionType: actionType, targetState: targetState, strategy: .defensive)
        gameState.executeAction(action)
        gameState.endTurn()
    }

    private func executeBalancedStrategy() async {
        let challenger = gameState.challenger
        
        // Smart mix of targets
        let targetStates = gameState.states
            .filter { state in
                let margin = abs(state.challengerSupport - state.incumbentSupport)
                return margin < 15 && state.electoralVotes >= 4
            }
            .sorted { state1, state2 in
                // Weighted scoring
                let score1 = calculateStateValue(state1)
                let score2 = calculateStateValue(state2)
                return score1 > score2
            }
        
        if let targetState = targetStates.first {
            let balancedActions: [CampaignActionType] = [.adCampaign, .rally, .townHall, .grassroots]
            let availableActions = balancedActions.filter { challenger.campaignFunds >= $0.cost * 1.5 }

            if let actionType = availableActions.first {
                let action = CampaignAction(
                    type: actionType,
                    targetState: targetState,
                    player: .challenger,
                    turn: gameState.currentTurn
                )

                reportAction(actionType: actionType, targetState: targetState, strategy: .balanced)
                gameState.executeAction(action)
                gameState.endTurn()
                return
            }
        }

        await executeFundraisingStrategy()
    }

    private func executeMultiStateStrategy() async {
        // Expert strategy: target multiple similar states at once
        let challenger = gameState.challenger
        let costPerState = CampaignActionType.adCampaign.cost * 1.2
        let maxStates = min(3, Int(challenger.campaignFunds / costPerState))
        
        guard maxStates >= 2 else {
            await executeBalancedStrategy()
            return
        }
        
        // Find cluster of competitive states
        let targetStates = gameState.states
            .filter { state in
                let margin = state.challengerSupport - state.incumbentSupport
                return margin > -10 && margin < 8 && state.electoralVotes >= 6
            }
            .sorted { calculateStateValue($0) > calculateStateValue($1) }
            .prefix(maxStates)
        
        guard !targetStates.isEmpty else {
            await executeAggressiveStrategy()
            return
        }
        
        // Execute coordinated campaign
        let totalCost = costPerState * Double(targetStates.count)
        gameState.challenger.campaignFunds -= totalCost
        
        let efficiencyBonus = 1.15 // 15% bonus for coordination
        
        for state in targetStates {
            guard let index = gameState.states.firstIndex(where: { $0.id == state.id }) else { continue }
            gameState.states[index].challengerSupport += Double.random(in: 3...7) * efficiencyBonus
        }
        
        gameState.challenger.momentum += 8

        // Add event to recent events
        let event = GameEvent(
            id: UUID(),
            type: .viral,
            title: "Coordinated Multi-State Campaign",
            description: "Launched synchronized campaign across \(targetStates.count) key states",
            affectedPlayer: .challenger,
            impactMagnitude: 5,
            turn: gameState.currentTurn
        )
        gameState.recentEvents.append(event)

        reportMultiStateAction(stateCount: targetStates.count, totalCost: totalCost)
        gameState.endTurn()
    }

    private func executeFundraisingStrategy() async {
        let challenger = gameState.challenger

        if challenger.campaignFunds >= CampaignActionType.fundraiser.cost {
            let action = CampaignAction(
                type: .fundraiser,
                targetState: nil,
                player: .challenger,
                turn: gameState.currentTurn
            )

            reportAction(actionType: .fundraiser, targetState: nil, strategy: .fundraising)
            gameState.executeAction(action)
            gameState.endTurn()
        } else {
            // Find cheapest effective action
            let cheapestAction = CampaignActionType.allCases
                .filter { challenger.campaignFunds >= $0.cost }
                .min { $0.cost < $1.cost }

            if let actionType = cheapestAction {
                let needsState: Bool = {
                    switch actionType {
                    case .fundraiser, .debate, .opposition:
                        return false
                    default:
                        return true
                    }
                }()

                let targetState = needsState ? gameState.states
                    .filter { $0.isBattleground }
                    .randomElement() ?? gameState.states.randomElement() : nil

                let action = CampaignAction(
                    type: actionType,
                    targetState: targetState,
                    player: .challenger,
                    turn: gameState.currentTurn
                )

                reportAction(actionType: actionType, targetState: targetState, strategy: .fundraising)
                gameState.executeAction(action)
                gameState.endTurn()
            } else {
                // Completely broke - skip turn
                gameState.lastAIAction = nil // No action taken
                gameState.endTurn()
            }
        }
    }
    
    // MARK: - Helper Methods

    private func calculateStateValue(_ state: ElectoralState) -> Double {
        let margin = state.challengerSupport - state.incumbentSupport
        let competitiveness = max(0, 15.0 - abs(margin)) / 15.0
        let evWeight = Double(state.electoralVotes) / 3.0
        let battlegroundBonus = state.isBattleground ? 1.5 : 1.0

        return (competitiveness * evWeight * battlegroundBonus)
    }

    private func reportAction(actionType: CampaignActionType, targetState: ElectoralState?, strategy: AIStrategy) {
        let strategyName: String = switch strategy {
        case .aggressive: "Aggressive"
        case .defensive: "Defensive"
        case .balanced: "Balanced"
        case .fundraising: "Fundraising"
        case .multiState: "Multi-State Blitz"
        }

        gameState.lastAIAction = AIActionReport(
            actionType: actionType,
            targetState: targetState,
            strategy: strategyName,
            turn: gameState.currentTurn,
            cost: actionType.cost
        )
    }

    private func reportMultiStateAction(stateCount: Int, totalCost: Double) {
        // For multi-state strategy, create a special report
        gameState.lastAIAction = AIActionReport(
            actionType: .adCampaign,
            targetState: nil,
            strategy: "Multi-State Blitz (\(stateCount) states)",
            turn: gameState.currentTurn,
            cost: totalCost
        )
    }
}
