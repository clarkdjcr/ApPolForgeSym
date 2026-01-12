//
//  ShadowBudgetManager.swift
//  ApPolForgeSym
//
//  Manages the "Nixon Disease" - Black Ops and Detection System
//

import Foundation
import Combine

@MainActor
class ShadowBudgetManager: ObservableObject {
    let gameState: GameState
    
    @Published var incumbentShadowState = ShadowBudgetState()
    @Published var challengerShadowState = ShadowBudgetState()
    
    @Published var incumbentIntegrity = IntegrityBonus()
    @Published var challengerIntegrity = IntegrityBonus()
    
    @Published var incumbentShellCompany = ShellCompanyLayer()
    @Published var challengerShellCompany = ShellCompanyLayer()
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    // MARK: - Turn Processing
    
    func processTurn(for playerType: PlayerType) {
        // Get fresh state at the start to avoid retriggering during updates
        let state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        
        // Batch all updates together to minimize publish events
        let shouldCheckDetection = state.allocationPercentage > 0
        
        // Check integrity bonus
        updateIntegrityStatus(for: playerType)
        
        // Check if operations are detected
        if shouldCheckDetection {
            checkForDetection(playerType: playerType)
        }
        
        // Apply any active scandals
        applyActiveScandals(for: playerType)
        
        // Decay opponent's stolen data
        decayOperationEffects(for: playerType)
    }
    
    // MARK: - Integrity System
    
    private func updateIntegrityStatus(for playerType: PlayerType) {
        var state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        var integrity = playerType == .incumbent ? incumbentIntegrity : challengerIntegrity
        
        if state.currentZone == .transparent {
            state.turnsInGreenZone += 1
            
            // Award integrity bonus after 3 consecutive clean turns
            if state.turnsInGreenZone >= 3 && !integrity.hasTeflonShield {
                integrity.applyBonus()
                state.hasIntegrityBonus = true
                state.hasTeflonShield = true
                
                // Create positive news event
                let event = GameEvent(
                    type: .endorsement,
                    title: "Campaign Praised for Transparency",
                    description: "\(playerName(for: playerType))'s campaign wins praise for clean operations. Major donors show increased confidence.",
                    affectedPlayer: playerType,
                    impactMagnitude: 5,
                    turn: gameState.currentTurn
                )
                gameState.recentEvents.insert(event, at: 0)
            }
        } else {
            // Reset counter if they leave green zone
            state.turnsInGreenZone = 0
            
            if state.currentZone == .blackOps {
                state.hasIntegrityBonus = false
                integrity.removeBonus()
            }
        }
        
        // Update state
        if playerType == .incumbent {
            incumbentShadowState = state
            incumbentIntegrity = integrity
        } else {
            challengerShadowState = state
            challengerIntegrity = integrity
        }
    }
    
    // MARK: - Detection System
    
    func checkForDetection(playerType: PlayerType) {
        let state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        let opponentState = playerType == .incumbent ? challengerShadowState : incumbentShadowState
        let shell = playerType == .incumbent ? incumbentShellCompany : challengerShellCompany
        
        // Calculate detection chance
        let baseDetection = state.allocationPercentage / 100.0
        let opponentCounterIntel = opponentState.counterIntelLevel
        let shellReduction = shell.isActive ? shell.detectionReduction : 0.0
        
        let detectionChance = baseDetection * opponentCounterIntel * (1.0 - shellReduction)
        
        // Roll for detection
        let roll = Double.random(in: 0...1)
        
        if roll < detectionChance {
            triggerWhistleblowerEvent(for: playerType, wasLaundered: shell.isActive)
        }
    }
    
    private func triggerWhistleblowerEvent(for playerType: PlayerType, wasLaundered: Bool) {
        var state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        
        // Determine scandal severity based on allocation level
        let severity: ScandalSeverity
        if state.allocationPercentage >= 25 {
            severity = .campaignEnding
        } else if state.allocationPercentage >= 18 {
            severity = .major
        } else {
            severity = .minor
        }
        
        let scandal = generateScandal(
            playerType: playerType,
            severity: severity,
            wasLaundered: wasLaundered
        )
        
        state.activeScandals.append(scandal)
        state.hasBeenCaught = true
        
        // Update game state
        if playerType == .incumbent {
            incumbentShadowState = state
        } else {
            challengerShadowState = state
        }
        
        // Apply immediate effects
        applyScandalEffects(scandal, to: playerType)
    }
    
    private func generateScandal(
        playerType: PlayerType,
        severity: ScandalSeverity,
        wasLaundered: Bool
    ) -> ShadowBudgetScandal {
        let playerNameStr = playerName(for: playerType)
        
        let title: String
        let description: String
        let operationType: ShadowOperationType = .dataTheft // Simplified
        
        switch severity {
        case .minor:
            title = "Campaign Finance Questions Raised"
            description = "Watchdog groups question \(playerNameStr)'s use of discretionary funds. Campaign promises full transparency review."
            
        case .major:
            if wasLaundered {
                title = "Money Laundering Allegations Surface"
                description = "FBI investigates complex web of shell companies linked to \(playerNameStr)'s campaign. Federal prosecutors reviewing evidence."
            } else {
                title = "Illegal Opposition Research Exposed"
                description = "\(playerNameStr) campaign caught funding illegal surveillance operation. Multiple staffers resign amid scandal."
            }
            
        case .campaignEnding:
            if wasLaundered {
                title = "BREAKING: Federal Indictments in Campaign Finance Scheme"
                description = "Department of Justice announces indictments against \(playerNameStr) campaign officials for money laundering and wire fraud. Campaign headquarters raided by FBI."
            } else {
                title = "WATERGATE 2.0: Massive Espionage Operation Uncovered"
                description = "Whistleblower reveals \(playerNameStr) campaign paid hackers to infiltrate opponent systems. DOJ opens criminal investigation."
            }
        }
        
        return ShadowBudgetScandal(
            title: title,
            description: description,
            severity: severity,
            turn: gameState.currentTurn,
            operationType: operationType,
            pollingImpact: severity.pollingPenalty,
            fundingFreeze: severity.fundingFreeze,
            wasLaundered: wasLaundered
        )
    }
    
    private func applyScandalEffects(_ scandal: ShadowBudgetScandal, to playerType: PlayerType) {
        var player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        var integrity = playerType == .incumbent ? incumbentIntegrity : challengerIntegrity
        
        // Apply polling damage
        player.nationalPolling += scandal.pollingImpact
        player.nationalPolling = max(15, min(85, player.nationalPolling))
        
        // Damage all state polling
        for i in 0..<gameState.states.count {
            if playerType == .incumbent {
                gameState.states[i].incumbentSupport += scandal.pollingImpact * 0.8
            } else {
                gameState.states[i].challengerSupport += scandal.pollingImpact * 0.8
            }
        }
        
        // Damage integrity
        integrity.damageReputation(abs(scandal.pollingImpact) * 2)
        
        // Create scandal event
        let event = GameEvent(
            type: .scandal,
            title: scandal.title,
            description: scandal.description,
            affectedPlayer: playerType,
            impactMagnitude: Int(scandal.pollingImpact),
            turn: gameState.currentTurn
        )
        gameState.recentEvents.insert(event, at: 0)
        
        // Update player
        if playerType == .incumbent {
            gameState.incumbent = player
            incumbentIntegrity = integrity
        } else {
            gameState.challenger = player
            challengerIntegrity = integrity
        }
        
        HapticsManager.shared.playErrorFeedback()
    }
    
    // MARK: - Shadow Operations
    
    func executeOperation(
        _ operationType: ShadowOperationType,
        for playerType: PlayerType
    ) -> Bool {
        let state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let shell = playerType == .incumbent ? incumbentShellCompany : challengerShellCompany
        
        // Check if allocation is sufficient
        guard state.allocationPercentage >= operationType.minimumAllocation else {
            return false
        }
        
        // Calculate cost
        let cost = shell.isActive ? operationType.baseCost * shell.costMultiplier : operationType.baseCost
        
        guard player.campaignFunds >= cost else {
            return false
        }
        
        // Deduct funds
        if playerType == .incumbent {
            gameState.incumbent.campaignFunds -= cost
        } else {
            gameState.challenger.campaignFunds -= cost
        }
        
        // Apply operation effects
        applyOperationEffects(operationType, to: playerType)
        
        return true
    }
    
    private func applyOperationEffects(_ operationType: ShadowOperationType, to playerType: PlayerType) {
        var state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        let opponentType: PlayerType = playerType == .incumbent ? .challenger : .incumbent
        var opponent = opponentType == .incumbent ? gameState.incumbent : gameState.challenger
        
        switch operationType {
        case .dataTheft:
            state.hasStolenOpponentData = true
            // Opponent's polling becomes less accurate (handled in UI)
            
        case .sabotage:
            state.activeSabotages.append("Operations Disrupted")
            // Opponent loses next turn (simplified implementation)
            opponent.momentum -= 10
            
        case .opponentResearch:
            let dirtTitle = generateDirt(for: opponentType)
            state.collectedDirt.append(dirtTitle)
            
            // Create negative event for opponent
            let event = GameEvent(
                type: .scandal,
                title: dirtTitle,
                description: "Leaked documents reveal damaging information about \(playerName(for: opponentType)).",
                affectedPlayer: opponentType,
                impactMagnitude: -8,
                turn: gameState.currentTurn
            )
            gameState.recentEvents.insert(event, at: 0)
            
            // Apply polling damage to opponent
            opponent.nationalPolling -= Double.random(in: 3...7)
            
        case .voterSuppression:
            // Reduce opponent support in their strong states
            for i in 0..<gameState.states.count {
                let opponentStrong = opponentType == .incumbent ?
                    gameState.states[i].incumbentSupport > 55 :
                    gameState.states[i].challengerSupport > 55
                
                if opponentStrong {
                    if opponentType == .incumbent {
                        gameState.states[i].incumbentSupport -= Double.random(in: 2...5)
                    } else {
                        gameState.states[i].challengerSupport -= Double.random(in: 2...5)
                    }
                }
            }
            
        case .mediaManipulation:
            // Plant negative stories
            let event = GameEvent(
                type: .gaffe,
                title: "Controversial Comments Surface",
                description: "\(playerName(for: opponentType)) caught on hot mic making controversial statements.",
                affectedPlayer: opponentType,
                impactMagnitude: -6,
                turn: gameState.currentTurn
            )
            gameState.recentEvents.insert(event, at: 0)
            opponent.momentum -= 5
        }
        
        // Update states
        if playerType == .incumbent {
            incumbentShadowState = state
        } else {
            challengerShadowState = state
        }
        
        if opponentType == .incumbent {
            gameState.incumbent = opponent
        } else {
            gameState.challenger = opponent
        }
    }
    
    private func generateDirt(for playerType: PlayerType) -> String {
        let templates = [
            "Leaked Audio: Candidate Insults Key Voter Group",
            "Financial Records Show Questionable Donations",
            "Former Staffers Allege Hostile Work Environment",
            "Tax Returns Reveal Offshore Accounts",
            "Past Business Dealings Under Scrutiny"
        ]
        return templates.randomElement()!
    }
    
    // MARK: - Teflon Shield
    
    func shouldBlockOpponentAttack(for playerType: PlayerType) -> Bool {
        let integrity = playerType == .incumbent ? incumbentIntegrity : challengerIntegrity
        
        if integrity.hasTeflonShield {
            // Create backfire event
            let opponentType: PlayerType = playerType == .incumbent ? .challenger : .incumbent
            let event = GameEvent(
                type: .gaffe,
                title: "Desperate Attacks Backfire",
                description: "Voters reject \(playerName(for: opponentType))'s smear campaign against 'honest' \(playerName(for: playerType)). Attack seen as desperate.",
                affectedPlayer: opponentType,
                impactMagnitude: -4,
                turn: gameState.currentTurn
            )
            gameState.recentEvents.insert(event, at: 0)
            
            return true
        }
        
        return false
    }
    
    // MARK: - Denial System
    
    func attemptDenial(scandalId: UUID, for playerType: PlayerType) -> Bool {
        let integrity = playerType == .incumbent ? incumbentIntegrity : challengerIntegrity
        var attempt = DenialAttempt(
            scandalId: scandalId,
            turn: gameState.currentTurn,
            integrityScore: integrity.reputation
        )
        
        let succeeded = attempt.attemptDenial()
        
        if succeeded {
            // Remove scandal
            var state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
            state.activeScandals.removeAll { $0.id == scandalId }
            
            // Create event
            let event = GameEvent(
                type: .viral,
                title: "Campaign Successfully Defends Against Allegations",
                description: "\(playerName(for: playerType)) provides evidence clearing campaign of wrongdoing. Polling rebounds.",
                affectedPlayer: playerType,
                impactMagnitude: 3,
                turn: gameState.currentTurn
            )
            gameState.recentEvents.insert(event, at: 0)
            
            // Update state
            if playerType == .incumbent {
                incumbentShadowState = state
            } else {
                challengerShadowState = state
            }
        } else {
            // Denial failed - makes it worse
            let event = GameEvent(
                type: .scandal,
                title: "Denial Rings Hollow",
                description: "\(playerName(for: playerType))'s attempts to deny allegations fall flat. 'Cover-up worse than the crime,' say analysts.",
                affectedPlayer: playerType,
                impactMagnitude: -5,
                turn: gameState.currentTurn
            )
            gameState.recentEvents.insert(event, at: 0)
        }
        
        return succeeded
    }
    
    // MARK: - Helper Methods
    
    private func applyActiveScandals(for playerType: PlayerType) {
        let state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        var player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        
        for scandal in state.activeScandals {
            // Apply funding freeze
            if gameState.currentTurn - scandal.turn < scandal.fundingFreeze {
                // Block fundraising
                player.campaignFunds -= player.campaignFunds * 0.05 // Ongoing drain
            }
        }
        
        // Update player
        if playerType == .incumbent {
            gameState.incumbent = player
        } else {
            gameState.challenger = player
        }
    }
    
    private func decayOperationEffects(for playerType: PlayerType) {
        var state = playerType == .incumbent ? incumbentShadowState : challengerShadowState
        
        // Stolen data expires after 3 turns
        // Sabotages last 1 turn
        // Dirt is permanent
        
        state.activeSabotages.removeAll()
        
        if playerType == .incumbent {
            incumbentShadowState = state
        } else {
            challengerShadowState = state
        }
    }
    
    private func playerName(for playerType: PlayerType) -> String {
        playerType == .incumbent ? gameState.incumbent.name : gameState.challenger.name
    }
    
    // MARK: - Fundraising Multiplier
    
    func getFundraisingMultiplier(for playerType: PlayerType) -> Double {
        let integrity = playerType == .incumbent ? incumbentIntegrity : challengerIntegrity
        return integrity.fundraisingMultiplier
    }
}
