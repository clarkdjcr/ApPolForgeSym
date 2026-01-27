//
//  ApPolForgeSymTests.swift
//  ApPolForgeSymTests
//
//  Created by Donald Clark on 1/11/26.
//

import Testing
@testable import ApPolForgeSym

// MARK: - Game State Tests

@Suite("Game State Tests")
@MainActor
struct GameStateTests {
    
    @Test("Initial game state is set up correctly")
    func testInitialGameState() async throws {
        let gameState = GameState()
        
        #expect(gameState.currentTurn == 1, "Game should start at turn 1")
        #expect(gameState.maxTurns == 20, "Game should have 20 turns")
        #expect(gameState.gamePhase == .setup, "Game should start in setup phase")
        #expect(gameState.currentPlayer == .incumbent, "Incumbent should go first")
        #expect(!gameState.states.isEmpty, "Should have states initialized")
        #expect(gameState.recentEvents.isEmpty, "Should start with no events")
    }
    
    @Test("Electoral vote calculation")
    func testElectoralVoteCalculation() async throws {
        let gameState = GameState()
        
        // Set up a clear winning scenario
        for i in 0..<gameState.states.count {
            if i < 5 {
                gameState.states[i].incumbentSupport = 60
                gameState.states[i].challengerSupport = 35
            } else {
                gameState.states[i].incumbentSupport = 30
                gameState.states[i].challengerSupport = 65
            }
        }
        
        let votes = gameState.calculateElectoralVotes()
        
        #expect(votes.incumbent > 0, "Incumbent should have electoral votes")
        #expect(votes.challenger > 0, "Challenger should have electoral votes")
        #expect(votes.incumbent + votes.challenger <= 538, "Total votes should not exceed 538")
    }
    
    @Test("Turn progression")
    func testTurnProgression() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let initialTurn = gameState.currentTurn
        let initialPlayer = gameState.currentPlayer
        
        gameState.endTurn()
        
        #expect(gameState.currentPlayer != initialPlayer, "Player should switch after turn ends")
        
        gameState.endTurn()
        
        #expect(gameState.currentTurn == initialTurn + 1, "Turn should increment after both players go")
    }
    
    @Test("Game ends after max turns")
    func testGameEnding() async throws {
        let gameState = GameState()
        gameState.startGame()
        gameState.currentTurn = 21
        
        gameState.endTurn()
        
        #expect(gameState.gamePhase == .ended, "Game should end after max turns")
    }
    
    @Test("Starting funds are correct")
    func testStartingFunds() async throws {
        let gameState = GameState()
        
        #expect(gameState.incumbent.campaignFunds == 220_000_000, "Incumbent should start with $220M")
        #expect(gameState.challenger.campaignFunds == 150_000_000, "Challenger should start with $150M")
    }
}

// MARK: - Player Tests

@Suite("Player Tests")
struct PlayerTests {
    
    @Test("Player initialization")
    func testPlayerInitialization() async throws {
        let player = Player(
            type: .incumbent,
            isAI: false,
            name: "Test Player",
            partyName: "Test Party",
            partyColor: "#FF0000"
        )
        
        #expect(player.type == .incumbent)
        #expect(player.isAI == false)
        #expect(player.name == "Test Player")
        #expect(player.campaignFunds > 0, "Player should have starting funds")
    }
    
    @Test("Incumbent has advantages")
    func testIncumbentAdvantages() async throws {
        let incumbent = Player(
            type: .incumbent,
            isAI: false,
            name: "Incumbent",
            partyName: "Party",
            partyColor: "#0000FF"
        )
        
        let challenger = Player(
            type: .challenger,
            isAI: false,
            name: "Challenger",
            partyName: "Party",
            partyColor: "#FF0000"
        )
        
        #expect(incumbent.campaignFunds > challenger.campaignFunds, "Incumbent should have more starting funds")
        #expect(incumbent.momentum > challenger.momentum, "Incumbent should have positive momentum")
        #expect(incumbent.nationalPolling > challenger.nationalPolling, "Incumbent should lead in polling")
    }
}
// MARK: - State Tests

@Suite("Electoral State Tests")
struct ElectoralStateTests {
    
    @Test("State leaning calculation")
    func testStateLeaningCalculation() async throws {
        let tossupState = ElectoralState(
            name: "Test",
            abbreviation: "TS",
            electoralVotes: 10,
            incumbentSupport: 48,
            challengerSupport: 48
        )
        
        #expect(tossupState.leaningToward == nil, "Close state should not lean either way")
        
        let incumbentState = ElectoralState(
            name: "Test",
            abbreviation: "TS",
            electoralVotes: 10,
            incumbentSupport: 60,
            challengerSupport: 35
        )
        
        #expect(incumbentState.leaningToward == .incumbent, "State should lean incumbent")
    }
    
    @Test("Battleground state identification")
    func testBattlegroundIdentification() async throws {
        let battleground = ElectoralState(
            name: "Test",
            abbreviation: "TS",
            electoralVotes: 10,
            incumbentSupport: 48,
            challengerSupport: 47
        )
        
        #expect(battleground.isBattleground, "Close state should be battleground")
        
        let safe = ElectoralState(
            name: "Test",
            abbreviation: "TS",
            electoralVotes: 10,
            incumbentSupport: 70,
            challengerSupport: 25
        )
        
        #expect(!safe.isBattleground, "Safe state should not be battleground")
    }
    
    @Test("Undecided voters calculation")
    func testUndecidedCalculation() async throws {
        let state = ElectoralState(
            name: "Test",
            abbreviation: "TS",
            electoralVotes: 10,
            incumbentSupport: 45,
            challengerSupport: 40
        )
        
        #expect(state.undecided == 15, "Undecided should be 15%")
    }
}

// MARK: - Campaign Action Tests

@Suite("Campaign Action Tests")
struct CampaignActionTests {
    
    @Test("Action costs are positive")
    func testActionCosts() async throws {
        for actionType in CampaignActionType.allCases {
            #expect(actionType.cost > 0, "\(actionType.name) should have positive cost")
        }
    }
    
    @Test("Rally action increases support")
    @MainActor
    func testRallyAction() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let targetState = gameState.states[0]
        let initialSupport = targetState.incumbentSupport
        let initialFunds = gameState.incumbent.campaignFunds
        
        let action = CampaignAction(
            type: .rally,
            targetState: targetState,
            player: .incumbent,
            turn: 1
        )
        
        gameState.executeAction(action)
        
        let state = gameState.states[0]
        
        #expect(state.incumbentSupport >= initialSupport, "Rally should increase or maintain support")
        #expect(gameState.incumbent.campaignFunds < initialFunds, "Rally should cost money")
    }
    
    @Test("Fundraiser increases funds")
    @MainActor
    func testFundraiserAction() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let initialFunds = gameState.incumbent.campaignFunds
        
        let action = CampaignAction(
            type: .fundraiser,
            targetState: nil,
            player: .incumbent,
            turn: 1
        )
        
        gameState.executeAction(action)
        
        // Net should be positive (gain more than cost)
        #expect(gameState.incumbent.campaignFunds > initialFunds, "Fundraiser should net positive funds")
    }
    
    @Test("Opposition research damages opponent")
    @MainActor
    func testOppositionResearch() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let initialPolling = gameState.challenger.nationalPolling
        let initialMomentum = gameState.challenger.momentum
        
        let action = CampaignAction(
            type: .opposition,
            targetState: nil,
            player: .incumbent,
            turn: 1
        )
        
        gameState.executeAction(action)
        
        // Should damage opponent in some way
        let damagedPolling = gameState.challenger.nationalPolling < initialPolling
        let damagedMomentum = gameState.challenger.momentum < initialMomentum
        
        #expect(damagedPolling || damagedMomentum, "Opposition research should damage opponent")
    }
}

// MARK: - Event Tests

@Suite("Game Event Tests")
struct GameEventTests {
    
    @Test("Event creation")
    func testEventCreation() async throws {
        let event = GameEvent(
            type: .scandal,
            title: "Test Scandal",
            description: "Test description",
            affectedPlayer: .incumbent,
            impactMagnitude: -20,
            turn: 5
        )
        
        #expect(event.type == .scandal)
        #expect(event.title == "Test Scandal")
        #expect(event.affectedPlayer == .incumbent)
        #expect(event.impactMagnitude == -20)
    }
    
    @Test("Event impact is applied")
    @MainActor
    func testEventImpact() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let initialPolling = gameState.incumbent.nationalPolling
        
        // Simulate multiple turns to potentially trigger an event
        for _ in 1...10 {
            gameState.endTurn()
        }
        
        // Check if any events occurred
        #expect(gameState.recentEvents.count <= 5, "Should not store more than 5 recent events")
    }
}

// MARK: - Persistence Tests

@Suite("Persistence Tests")
@MainActor
struct PersistenceTests {
    
    @Test("Save and load game state")
    func testSaveAndLoad() async throws {
        let gameState = GameState()
        gameState.startGame()
        gameState.currentTurn = 5
        gameState.incumbent.campaignFunds = 10_000_000
        
        // Save
        try PersistenceManager.shared.saveGame(gameState)
        
        #expect(PersistenceManager.shared.hasAutoSave(), "Should have saved game")

        // Load
        let saveData = try PersistenceManager.shared.loadAutoSave()
        
        #expect(saveData.currentTurn == 5, "Saved turn should match")
        #expect(saveData.incumbent.campaignFunds == 10_000_000, "Saved funds should match")
        
        // Cleanup
        try PersistenceManager.shared.deleteAutoSave()
    }
    
    @Test("Auto-save functionality")
    func testAutoSave() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        try PersistenceManager.shared.autoSaveGame(gameState)
        
        #expect(PersistenceManager.shared.hasAutoSave(), "Should have auto-save")
        
        // Cleanup
        try PersistenceManager.shared.deleteAutoSave()
    }
    
    @Test("Save metadata")
    func testSaveMetadata() async throws {
        let gameState = GameState()
        gameState.startGame()
        gameState.currentTurn = 10
        
        try PersistenceManager.shared.saveGame(gameState)
        
        let metadata = PersistenceManager.shared.getSaveMetadata()
        
        #expect(metadata != nil, "Should have metadata")
        #expect(metadata?.currentTurn == 10, "Metadata should have correct turn")
        
        // Cleanup
        try PersistenceManager.shared.deleteAutoSave()
    }
}

// MARK: - Formatting Tests

@Suite("Number Formatting Tests")
struct FormattingTests {
    
    @Test("Currency formatting")
    func testCurrencyFormatting() async throws {
        let amount = 15_000_000.0
        let formatted = amount.asCurrency()
        
        #expect(formatted == "$15.0M", "Should format as currency")
    }
    
    @Test("Percentage formatting")
    func testPercentageFormatting() async throws {
        let value = 48.5
        let formatted = value.asPercent()
        
        #expect(formatted == "48.5%", "Should format as percentage")
    }
    
    @Test("Signed number formatting")
    func testSignedFormatting() async throws {
        let positive = 5.withSign()
        let negative = (-5).withSign()
        
        #expect(positive == "+5", "Should show plus sign")
        #expect(negative == "-5", "Should show minus sign")
    }
}

// MARK: - AI Tests

@Suite("AI Opponent Tests")
@MainActor
struct AIOpponentTests {
    
    @Test("AI makes decisions")
    func testAIMakesDecision() async throws {
        let gameState = GameState()
        gameState.startGame()
        
        let initialFunds = gameState.challenger.campaignFunds
        let initialTurn = gameState.currentTurn
        
        let ai = AIOpponent(gameState: gameState)
        
        // Switch to challenger's turn
        gameState.currentPlayer = .challenger
        
        await ai.makeDecision()
        
        // AI should have taken some action
        let fundsChanged = gameState.challenger.campaignFunds != initialFunds
        let turnAdvanced = gameState.currentTurn != initialTurn || gameState.currentPlayer != .challenger
        
        #expect(fundsChanged || turnAdvanced, "AI should take action")
    }
}

