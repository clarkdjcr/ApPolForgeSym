//
//  GameModels.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Player

enum PlayerType: String, Codable {
    case incumbent
    case challenger
}

struct Player: Identifiable, Codable {
    let id: UUID
    var type: PlayerType
    var isAI: Bool
    var name: String
    var partyName: String
    var partyColor: String // Store as hex
    var personality: String // Store CandidatePersonality.rawValue
    
    // Resources
    var campaignFunds: Double
    var momentum: Int // -100 to 100
    var nationalPolling: Double // 0 to 100
    
    init(id: UUID = UUID(), type: PlayerType, isAI: Bool, name: String, partyName: String, partyColor: String, personality: String = "The Uniter") {
        self.id = id
        self.type = type
        self.isAI = isAI
        self.name = name
        self.partyName = partyName
        self.partyColor = partyColor
        self.personality = personality
        
        // Starting values - Based on 2020 election cycle
        // Incumbent had ~$1.1B, Challenger had ~$768M
        // Starting at 20% of those amounts for game balance
        self.campaignFunds = type == .incumbent ? 220_000_000 : 150_000_000
        self.momentum = type == .incumbent ? 5 : -5
        self.nationalPolling = type == .incumbent ? 48.0 : 46.0
    }
}

// MARK: - State

struct ElectoralState: Identifiable, Codable {
    let id: UUID
    let name: String
    let abbreviation: String
    let electoralVotes: Int
    
    // Current state of competition
    var incumbentSupport: Double // 0 to 100
    var challengerSupport: Double // 0 to 100
    var undecided: Double // Remainder
    
    var leaningToward: PlayerType? {
        if incumbentSupport > challengerSupport + 5 {
            return .incumbent
        } else if challengerSupport > incumbentSupport + 5 {
            return .challenger
        }
        return nil
    }
    
    var isBattleground: Bool {
        abs(incumbentSupport - challengerSupport) < 10
    }
    
    init(id: UUID = UUID(), name: String, abbreviation: String, electoralVotes: Int, 
         incumbentSupport: Double, challengerSupport: Double) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.electoralVotes = electoralVotes
        self.incumbentSupport = incumbentSupport
        self.challengerSupport = challengerSupport
        self.undecided = 100 - incumbentSupport - challengerSupport
    }
}

// MARK: - Campaign Action

enum CampaignActionType: String, Codable, CaseIterable, Identifiable {
    case rally
    case adCampaign
    case fundraiser
    case townHall
    case debate
    case grassroots
    case opposition
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .rally: return "Hold Rally"
        case .adCampaign: return "Ad Campaign"
        case .fundraiser: return "Fundraiser"
        case .townHall: return "Town Hall"
        case .debate: return "Debate Prep"
        case .grassroots: return "Grassroots Organizing"
        case .opposition: return "Opposition Research"
        }
    }
    
    var cost: Double {
        switch self {
        case .rally: return 500_000
        case .adCampaign: return 2_000_000
        case .fundraiser: return 100_000
        case .townHall: return 250_000
        case .debate: return 750_000
        case .grassroots: return 300_000
        case .opposition: return 1_000_000
        }
    }
    
    var description: String {
        switch self {
        case .rally:
            return "Energize your base with a high-energy rally. Boosts momentum and state support."
        case .adCampaign:
            return "Saturate the airwaves with political ads. Major polling impact in target state."
        case .fundraiser:
            return "Host a fundraising event to replenish campaign coffers."
        case .townHall:
            return "Connect with voters directly. Improves favorability and undecided voters."
        case .debate:
            return "Prepare for upcoming debates. Increases chance of strong debate performance."
        case .grassroots:
            return "Build ground game infrastructure. Long-term support in target state."
        case .opposition:
            return "Dig up dirt on your opponent. Potential to damage their support."
        }
    }
    
    var systemImage: String {
        switch self {
        case .rally: return "megaphone.fill"
        case .adCampaign: return "tv.fill"
        case .fundraiser: return "dollarsign.circle.fill"
        case .townHall: return "person.3.fill"
        case .debate: return "mic.fill"
        case .grassroots: return "network"
        case .opposition: return "doc.text.magnifyingglass"
        }
    }
}

struct CampaignAction: Identifiable {
    let id: UUID
    let type: CampaignActionType
    let targetState: ElectoralState?
    let player: PlayerType
    let turn: Int
    
    init(id: UUID = UUID(), type: CampaignActionType, targetState: ElectoralState?, player: PlayerType, turn: Int) {
        self.id = id
        self.type = type
        self.targetState = targetState
        self.player = player
        self.turn = turn
    }
}

// MARK: - Event

enum EventType: String, Codable {
    case scandal
    case economicNews
    case endorsement
    case gaffe
    case crisis
    case viral
    
    var name: String {
        switch self {
        case .scandal: return "Scandal"
        case .economicNews: return "Economic News"
        case .endorsement: return "Major Endorsement"
        case .gaffe: return "Campaign Gaffe"
        case .crisis: return "National Crisis"
        case .viral: return "Viral Moment"
        }
    }
}

struct GameEvent: Identifiable, Codable {
    let id: UUID
    let type: EventType
    let title: String
    let description: String
    let affectedPlayer: PlayerType?
    let impactMagnitude: Int // -50 to 50
    let turn: Int
    
    init(id: UUID = UUID(), type: EventType, title: String, description: String, 
         affectedPlayer: PlayerType?, impactMagnitude: Int, turn: Int) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.affectedPlayer = affectedPlayer
        self.impactMagnitude = impactMagnitude
        self.turn = turn
    }
}

// MARK: - AI Action Report

struct AIActionReport: Identifiable {
    let id = UUID()
    let actionType: CampaignActionType
    let targetState: ElectoralState?
    let strategy: String
    let turn: Int
    let cost: Double

    var summary: String {
        if let state = targetState {
            return "\(actionType.name) in \(state.name)"
        } else {
            return "\(actionType.name)"
        }
    }

    var details: String {
        var text = "Strategy: \(strategy)\n"
        text += "Action: \(actionType.name)\n"
        if let state = targetState {
            text += "Target: \(state.name) (\(state.electoralVotes) EVs)\n"
        }
        text += "Cost: \(cost.asCurrency())"
        return text
    }
}

// MARK: - Game State

@MainActor
class GameState: ObservableObject {
    @Published var incumbent: Player
    @Published var challenger: Player
    @Published var states: [ElectoralState]
    @Published var currentTurn: Int
    @Published var maxTurns: Int
    @Published var currentPlayer: PlayerType
    @Published var recentEvents: [GameEvent]
    @Published var gamePhase: GamePhase
    @Published var lastAIAction: AIActionReport?
    @Published var actionsRemainingThisTurn: Int = 1
    @Published var maxActionsThisTurn: Int = 1
    @Published var actionsUsedThisTurn: [CampaignAction] = []

    enum GamePhase: String {
        case setup
        case playing
        case ended
    }
    
    init() {
        // Initialize players
        self.incumbent = Player(
            type: .incumbent,
            isAI: false,
            name: "President Morgan",
            partyName: "Liberty Party",
            partyColor: "#3498db",
            personality: "The Uniter"
        )
        
        self.challenger = Player(
            type: .challenger,
            isAI: true,
            name: "Senator Davis",
            partyName: "Progress Party",
            partyColor: "#e74c3c",
            personality: "The Populist"
        )
        
        // Initialize states (simplified set for gameplay)
        self.states = Self.createInitialStates()
        
        self.currentTurn = 1
        self.maxTurns = 20 // 20 weeks until election
        self.currentPlayer = .incumbent
        self.recentEvents = []
        self.gamePhase = .setup
    }
    
    static func createInitialStates() -> [ElectoralState] {
        return [
            // Swing States
            ElectoralState(name: "Florida", abbreviation: "FL", electoralVotes: 29, incumbentSupport: 47, challengerSupport: 48),
            ElectoralState(name: "Pennsylvania", abbreviation: "PA", electoralVotes: 20, incumbentSupport: 48, challengerSupport: 47),
            ElectoralState(name: "Michigan", abbreviation: "MI", electoralVotes: 16, incumbentSupport: 46, challengerSupport: 48),
            ElectoralState(name: "Wisconsin", abbreviation: "WI", electoralVotes: 10, incumbentSupport: 48, challengerSupport: 47),
            ElectoralState(name: "Arizona", abbreviation: "AZ", electoralVotes: 11, incumbentSupport: 47, challengerSupport: 48),
            ElectoralState(name: "North Carolina", abbreviation: "NC", electoralVotes: 15, incumbentSupport: 48, challengerSupport: 47),
            ElectoralState(name: "Georgia", abbreviation: "GA", electoralVotes: 16, incumbentSupport: 47, challengerSupport: 48),
            ElectoralState(name: "Nevada", abbreviation: "NV", electoralVotes: 6, incumbentSupport: 48, challengerSupport: 47),
            
            // Blue states
            ElectoralState(name: "California", abbreviation: "CA", electoralVotes: 55, incumbentSupport: 58, challengerSupport: 36),
            ElectoralState(name: "New York", abbreviation: "NY", electoralVotes: 29, incumbentSupport: 56, challengerSupport: 38),
            ElectoralState(name: "Illinois", abbreviation: "IL", electoralVotes: 20, incumbentSupport: 54, challengerSupport: 40),
            
            // Red states
            ElectoralState(name: "Texas", abbreviation: "TX", electoralVotes: 38, incumbentSupport: 43, challengerSupport: 52),
            ElectoralState(name: "Ohio", abbreviation: "OH", electoralVotes: 18, incumbentSupport: 44, challengerSupport: 51),
            ElectoralState(name: "Indiana", abbreviation: "IN", electoralVotes: 11, incumbentSupport: 40, challengerSupport: 55),
        ]
    }
    
    func startGame() {
        gamePhase = .playing
    }
    
    func calculateElectoralVotes() -> (incumbent: Int, challenger: Int) {
        var incumbentVotes = 0
        var challengerVotes = 0
        
        for state in states {
            if state.incumbentSupport > state.challengerSupport {
                incumbentVotes += state.electoralVotes
            } else if state.challengerSupport > state.incumbentSupport {
                challengerVotes += state.electoralVotes
            }
        }
        
        return (incumbentVotes, challengerVotes)
    }
    
    /// Calculate how many actions the current player gets this turn based on strategic recommendations.
    func calculateActionsForTurn(advisor: StrategicAdvisor) {
        let recommendations = advisor.generateRecommendations(for: currentPlayer)

        // Base: 1 action per turn
        // +1 per Critical recommendation (max +2)
        // +1 per High recommendation (max +1)
        // Cap: 4 actions per turn
        let criticalCount = min(recommendations.filter({ $0.priority == .critical }).count, 2)
        let highCount = min(recommendations.filter({ $0.priority == .high }).count, 1)

        let calculatedActions = 1 + criticalCount + highCount
        maxActionsThisTurn = min(calculatedActions, 4)
        actionsRemainingThisTurn = maxActionsThisTurn
        actionsUsedThisTurn = []
    }

    /// Consume one action. Automatically ends the turn when no actions remain.
    func useAction() {
        actionsRemainingThisTurn -= 1
        if actionsRemainingThisTurn <= 0 {
            endTurn()
        }
    }

    /// Check if the player can afford the cheapest available action.
    func canAffordAnyAction(for playerType: PlayerType) -> Bool {
        let player = playerType == .incumbent ? incumbent : challenger
        let cheapest = CampaignActionType.allCases.map(\.cost).min() ?? 0
        return player.campaignFunds >= cheapest
    }

    /// Force-end the turn immediately (e.g. player pressed End Turn Early, or out of funds).
    func forceEndTurn() {
        actionsRemainingThisTurn = 0
        endTurn()
    }

    func endTurn() {
        // Reset action tracking
        actionsUsedThisTurn = []
        actionsRemainingThisTurn = 0

        // Generate random event
        if Int.random(in: 1...100) <= 40 { // 40% chance of event each turn
            generateRandomEvent()
        }

        // Switch players
        currentPlayer = currentPlayer == .incumbent ? .challenger : .incumbent

        // If both players have gone, advance turn
        if currentPlayer == .incumbent {
            currentTurn += 1
        }

        // Check for game end
        if currentTurn > maxTurns {
            gamePhase = .ended
        }
    }
    
    private func generateRandomEvent() {
        let eventTypes: [EventType] = [.scandal, .economicNews, .endorsement, .gaffe, .crisis, .viral]
        let type = eventTypes.randomElement()!
        let affectedPlayer: PlayerType? = Bool.random() ? .incumbent : .challenger
        let magnitude = Int.random(in: -30...30)
        
        let event = GameEvent(
            type: type,
            title: generateEventTitle(type: type),
            description: generateEventDescription(type: type),
            affectedPlayer: affectedPlayer,
            impactMagnitude: magnitude,
            turn: currentTurn
        )
        
        recentEvents.insert(event, at: 0)
        if recentEvents.count > 5 {
            recentEvents = Array(recentEvents.prefix(5))
        }
        
        applyEventEffects(event)
    }
    
    private func generateEventTitle(type: EventType) -> String {
        switch type {
        case .scandal: return "Breaking: Campaign Scandal Emerges"
        case .economicNews: return "Major Economic Report Released"
        case .endorsement: return "High-Profile Endorsement"
        case .gaffe: return "Candidate Makes Controversial Statement"
        case .crisis: return "National Crisis Unfolds"
        case .viral: return "Campaign Moment Goes Viral"
        }
    }
    
    private func generateEventDescription(type: EventType) -> String {
        switch type {
        case .scandal: return "New allegations surface that could impact the campaign."
        case .economicNews: return "Economic indicators shift public opinion on key issues."
        case .endorsement: return "A major figure announces their support for a candidate."
        case .gaffe: return "An off-script moment creates controversy."
        case .crisis: return "A sudden crisis tests leadership credentials."
        case .viral: return "A campaign moment captures the nation's attention."
        }
    }
    
    private func applyEventEffects(_ event: GameEvent) {
        guard let affected = event.affectedPlayer else { return }
        
        if affected == .incumbent {
            incumbent.nationalPolling += Double(event.impactMagnitude) * 0.1
            incumbent.momentum += event.impactMagnitude / 5
        } else {
            challenger.nationalPolling += Double(event.impactMagnitude) * 0.1
            challenger.momentum += event.impactMagnitude / 5
        }
        
        // Clamp values
        incumbent.nationalPolling = max(20, min(80, incumbent.nationalPolling))
        challenger.nationalPolling = max(20, min(80, challenger.nationalPolling))
        incumbent.momentum = max(-100, min(100, incumbent.momentum))
        challenger.momentum = max(-100, min(100, challenger.momentum))
    }
    
    func executeAction(_ action: CampaignAction) {
        // Deduct cost
        if action.player == .incumbent {
            incumbent.campaignFunds -= action.type.cost
        } else {
            challenger.campaignFunds -= action.type.cost
        }
        
        // Apply effects based on action type
        switch action.type {
        case .rally:
            if let state = action.targetState, let index = states.firstIndex(where: { $0.id == state.id }) {
                if action.player == .incumbent {
                    states[index].incumbentSupport += Double.random(in: 1...4)
                    incumbent.momentum += Int.random(in: 2...5)
                } else {
                    states[index].challengerSupport += Double.random(in: 1...4)
                    challenger.momentum += Int.random(in: 2...5)
                }
            }
            
        case .adCampaign:
            if let state = action.targetState, let index = states.firstIndex(where: { $0.id == state.id }) {
                if action.player == .incumbent {
                    states[index].incumbentSupport += Double.random(in: 2...6)
                } else {
                    states[index].challengerSupport += Double.random(in: 2...6)
                }
            }
            
        case .fundraiser:
            if action.player == .incumbent {
                incumbent.campaignFunds += Double.random(in: 1_000_000...3_000_000)
            } else {
                challenger.campaignFunds += Double.random(in: 1_000_000...3_000_000)
            }
            
        case .townHall:
            if let state = action.targetState, let index = states.firstIndex(where: { $0.id == state.id }) {
                if action.player == .incumbent {
                    states[index].incumbentSupport += Double.random(in: 1...3)
                    incumbent.nationalPolling += 0.5
                } else {
                    states[index].challengerSupport += Double.random(in: 1...3)
                    challenger.nationalPolling += 0.5
                }
            }
            
        case .debate:
            if action.player == .incumbent {
                incumbent.momentum += Int.random(in: 3...8)
            } else {
                challenger.momentum += Int.random(in: 3...8)
            }
            
        case .grassroots:
            if let state = action.targetState, let index = states.firstIndex(where: { $0.id == state.id }) {
                if action.player == .incumbent {
                    states[index].incumbentSupport += Double.random(in: 1...2)
                } else {
                    states[index].challengerSupport += Double.random(in: 1...2)
                }
            }
            
        case .opposition:
            if action.player == .incumbent {
                challenger.nationalPolling -= Double.random(in: 0.5...2.0)
                challenger.momentum -= Int.random(in: 3...8)
            } else {
                incumbent.nationalPolling -= Double.random(in: 0.5...2.0)
                incumbent.momentum -= Int.random(in: 3...8)
            }
        }
    }
}
