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
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    /// AI makes a decision about what action to take
    func makeDecision() async {
        // Wait a moment to simulate thinking (use user's setting)
        let aiSpeed = AppSettings.shared.aiSpeed
        try? await Task.sleep(for: .seconds(aiSpeed))
        
        // AI Strategy Logic
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
        }
    }
    
    enum AIStrategy {
        case aggressive   // Focus on attacking and swing states
        case defensive    // Protect current leads
        case balanced     // Mix of offense and defense
        case fundraising  // Need money
    }
    
    private func determineStrategy() -> AIStrategy {
        let challenger = gameState.challenger
        let votes = gameState.calculateElectoralVotes()
        
        // If low on funds, prioritize fundraising
        if challenger.campaignFunds < 2_000_000 {
            return .fundraising
        }
        
        // If winning by a lot, play defensive
        if votes.challenger > votes.incumbent + 50 {
            return .defensive
        }
        
        // If losing badly, go aggressive
        if votes.challenger < votes.incumbent - 50 {
            return .aggressive
        }
        
        // Otherwise, balanced approach
        return .balanced
    }
    
    private func executeAggressiveStrategy() async {
        let challenger = gameState.challenger
        
        // Target swing states or states where incumbent is weak
        let targetStates = gameState.states
            .filter { $0.isBattleground || ($0.incumbentSupport < 52 && $0.challengerSupport > 40) }
            .sorted { $0.electoralVotes > $1.electoralVotes }
        
        guard let targetState = targetStates.first else {
            await executeBalancedStrategy()
            return
        }
        
        // Choose aggressive actions
        let aggressiveActions: [CampaignActionType] = [.adCampaign, .rally, .opposition]
        let availableActions = aggressiveActions.filter { challenger.campaignFunds >= $0.cost }
        
        guard let actionType = availableActions.randomElement() else {
            // Can't afford aggressive moves, fundraise instead
            await executeFundraisingStrategy()
            return
        }
        
        let action = CampaignAction(
            type: actionType,
            targetState: actionType == .opposition ? nil : targetState,
            player: .challenger,
            turn: gameState.currentTurn
        )
        
        gameState.executeAction(action)
        gameState.endTurn()
    }
    
    private func executeDefensiveStrategy() async {
        let challenger = gameState.challenger
        
        // Find states where we're leading but margin is narrow
        let vulnerableStates = gameState.states
            .filter { state in
                state.challengerSupport > state.incumbentSupport &&
                (state.challengerSupport - state.incumbentSupport) < 8
            }
            .sorted { $0.electoralVotes > $1.electoralVotes }
        
        guard let targetState = vulnerableStates.first else {
            await executeBalancedStrategy()
            return
        }
        
        // Choose defensive actions - town halls and grassroots
        let defensiveActions: [CampaignActionType] = [.townHall, .grassroots, .rally]
        let availableActions = defensiveActions.filter { challenger.campaignFunds >= $0.cost }
        
        guard let actionType = availableActions.randomElement() else {
            await executeFundraisingStrategy()
            return
        }
        
        let action = CampaignAction(
            type: actionType,
            targetState: targetState,
            player: .challenger,
            turn: gameState.currentTurn
        )
        
        gameState.executeAction(action)
        gameState.endTurn()
    }
    
    private func executeBalancedStrategy() async {
        let challenger = gameState.challenger
        
        // Mix of targets - prioritize swing states
        let targetStates = gameState.states
            .filter { $0.isBattleground }
            .sorted { $0.electoralVotes > $1.electoralVotes }
        
        // If we have battlegrounds, target them
        if let targetState = targetStates.first {
            let balancedActions: [CampaignActionType] = [.rally, .adCampaign, .townHall, .grassroots]
            let availableActions = balancedActions.filter { challenger.campaignFunds >= $0.cost }
            
            if let actionType = availableActions.randomElement() {
                let action = CampaignAction(
                    type: actionType,
                    targetState: targetState,
                    player: .challenger,
                    turn: gameState.currentTurn
                )
                
                gameState.executeAction(action)
                gameState.endTurn()
                return
            }
        }
        
        // If no good targets or can't afford actions, fundraise
        await executeFundraisingStrategy()
    }
    
    private func executeFundraisingStrategy() async {
        let challenger = gameState.challenger
        
        // Always choose fundraiser if we can afford it
        if challenger.campaignFunds >= CampaignActionType.fundraiser.cost {
            let action = CampaignAction(
                type: .fundraiser,
                targetState: nil,
                player: .challenger,
                turn: gameState.currentTurn
            )
            
            gameState.executeAction(action)
            gameState.endTurn()
        } else {
            // If we can't even afford a fundraiser, try the cheapest available action
            let cheapestAction = CampaignActionType.allCases
                .filter { challenger.campaignFunds >= $0.cost }
                .min { $0.cost < $1.cost }
            
            if let actionType = cheapestAction {
                // Pick a random state for actions that need one
                let needsState: Bool = {
                    switch actionType {
                    case .fundraiser, .debate, .opposition:
                        return false
                    default:
                        return true
                    }
                }()
                
                let targetState = needsState ? gameState.states.randomElement() : nil
                
                let action = CampaignAction(
                    type: actionType,
                    targetState: targetState,
                    player: .challenger,
                    turn: gameState.currentTurn
                )
                
                gameState.executeAction(action)
                gameState.endTurn()
            } else {
                // Completely broke - skip turn
                gameState.endTurn()
            }
        }
    }
}
