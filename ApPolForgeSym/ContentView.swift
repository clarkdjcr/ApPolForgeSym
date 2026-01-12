//
//  ContentView.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var settings = AppSettings.shared
    @State private var showingTutorial = false
    @State private var showingLoadAlert = false
    
    var body: some View {
        Group {
            switch gameState.gamePhase {
            case .setup:
                SetupView(gameState: gameState)
            case .playing:
                GamePlayView(gameState: gameState)
            case .ended:
                ResultsView(gameState: gameState)
            }
        }
        .onAppear {
            checkForSavedGame()
        }
        .sheet(isPresented: $showingTutorial) {
            TutorialView()
        }
        .alert("Continue Last Game?", isPresented: $showingLoadAlert) {
            Button("New Game", role: .cancel) {
                if settings.showTutorial {
                    showingTutorial = true
                }
            }
            Button("Continue") {
                loadSavedGame()
            }
        } message: {
            if let metadata = PersistenceManager.shared.getSaveMetadata() {
                Text("You have a saved game from \(metadata.formattedDate) at \(metadata.turnDescription).")
            } else {
                Text("Continue your previous campaign?")
            }
        }
    }
    
    private func checkForSavedGame() {
        if PersistenceManager.shared.hasAutoSave() {
            showingLoadAlert = true
        } else if settings.showTutorial {
            showingTutorial = true
        }
    }
    
    private func loadSavedGame() {
        do {
            let saveData = try PersistenceManager.shared.loadAutoSave()
            saveData.apply(to: gameState)
            HapticsManager.shared.playSuccessFeedback()
        } catch {
            print("Failed to load game: \(error)")
            HapticsManager.shared.playErrorFeedback()
        }
    }
}

// MARK: - Setup View

struct SetupView: View {
    @ObservedObject var gameState: GameState
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.red.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 10) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Campaign Manager 2026")
                        
                        Text("Campaign Manager 2026")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("The Race for the White House")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        CandidateCard(player: gameState.incumbent)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(gameState.incumbent.accessibilityDescription)
                        
                        Text("VS")
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                        
                        CandidateCard(player: gameState.challenger)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(gameState.challenger.accessibilityDescription)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("Manage your campaign through 20 intense weeks")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            HapticsManager.shared.playActionFeedback()
                            withAnimation {
                                gameState.startGame()
                            }
                            AccessibilityAnnouncement.announceScreenChange("Campaign started. Week 1.")
                        } label: {
                            Text("Start Campaign")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .accessibilityLabel("Start Campaign")
                        .accessibilityHint("Begin a new campaign for the presidency")
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Setup")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingHelp = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingHelp = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                #endif
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                QuickTipsView()
            }
        }
    }
}

struct CandidateCard: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(player.partyName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(player.type == .incumbent ? "Incumbent" : "Challenger")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                if player.isAI {
                    Label("AI", systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(white: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

// MARK: - Game Play View

struct GamePlayView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedTab = 0
    @State private var showingActionSheet = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingSaveConfirmation = false
    @State private var aiOpponent: AIOpponent?
    
    var isPlayerTurn: Bool {
        if gameState.currentPlayer == .incumbent {
            return !gameState.incumbent.isAI
        } else {
            return !gameState.challenger.isAI
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with turn and electoral count
                HeaderView(gameState: gameState)
                
                // Current player indicator
                if !isPlayerTurn {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("AI is taking its turn...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(white: 1.0))
                    .accessibilityLabel("AI opponent is thinking")
                }
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Map").tag(0)
                    Text("Actions").tag(1)
                    Text("Events").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedTab) { _, _ in
                    HapticsManager.shared.playSelectionFeedback()
                }
                
                // Content
                TabView(selection: $selectedTab) {
                    MapView(gameState: gameState)
                        .tag(0)
                    
                    ActionsView(gameState: gameState, showingActionSheet: $showingActionSheet)
                        .tag(1)
                    
                    EventsView(gameState: gameState)
                        .tag(2)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Week \(gameState.currentTurn) of \(gameState.maxTurns)")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingHelp = true
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        
                        Button {
                            saveGame()
                        } label: {
                            Label("Save Game", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            showingHelp = true
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        
                        Button {
                            saveGame()
                        } label: {
                            Label("Save Game", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
                #endif
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingActionSheet = true
                    } label: {
                        Label("Take Action", systemImage: "flag.fill")
                    }
                    .disabled(!isPlayerTurn)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingActionSheet = true
                    } label: {
                        Label("Take Action", systemImage: "flag.fill")
                    }
                    .disabled(!isPlayerTurn)
                }
                #endif
            }
            .onAppear {
                aiOpponent = AIOpponent(gameState: gameState)
                checkForAITurn()
            }
            .onChange(of: gameState.currentPlayer) { _, _ in
                HapticsManager.shared.playTurnEndFeedback()
                checkForAITurn()
                
                // Auto-save
                if AppSettings.shared.autoSaveEnabled {
                    try? PersistenceManager.shared.autoSaveGame(gameState)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                QuickTipsView()
            }
            .alert("Game Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") { }
            } message: {
                Text("Your game has been saved successfully.")
            }
        }
    }
    
    private func checkForAITurn() {
        guard !isPlayerTurn else { return }
        
        Task {
            await aiOpponent?.makeDecision()
        }
    }
    
    private func saveGame() {
        do {
            try PersistenceManager.shared.saveGame(gameState)
            HapticsManager.shared.playSuccessFeedback()
            showingSaveConfirmation = true
        } catch {
            print("Failed to save game: \(error)")
            HapticsManager.shared.playErrorFeedback()
        }
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        let votes = gameState.calculateElectoralVotes()
        
        HStack(spacing: 20) {
            VStack {
                Text("\(votes.incumbent)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                Text(gameState.incumbent.name)
                    .font(.caption)
            }
            
            VStack {
                Text("Electoral Votes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("270 to Win")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            VStack {
                Text("\(votes.challenger)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                
                Text(gameState.challenger.name)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .electoralVoteAccessibility(
            incumbentVotes: votes.incumbent,
            challengerVotes: votes.challenger,
            incumbentName: gameState.incumbent.name,
            challengerName: gameState.challenger.name
        )
    }
}

// MARK: - Map View

struct MapView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        List {
            Section("Battleground States") {
                ForEach(gameState.states.filter { $0.isBattleground }) { state in
                    StateRow(state: state)
                }
            }
            
            Section("Other States") {
                ForEach(gameState.states.filter { !$0.isBattleground }) { state in
                    StateRow(state: state)
                }
            }
        }
    }
}

struct StateRow: View {
    let state: ElectoralState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.stateColor(for: state))
                    .frame(width: 12, height: 12)
                
                Text(state.name)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(state.electoralVotes) EV")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if state.isBattleground {
                        Text("Battleground")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            HStack(spacing: 4) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.incumbentBlue)
                            .frame(width: geometry.size.width * (state.incumbentSupport / 100))
                        
                        Rectangle()
                            .fill(Color.challengerRed)
                            .frame(width: geometry.size.width * (state.challengerSupport / 100))
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.incumbentBlue)
                        .frame(width: 8, height: 8)
                    Text(state.incumbentSupport.asPercent())
                        .font(.caption)
                }
                
                Spacer()
                
                Text("Undecided: \(state.undecided.asPercent())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(state.challengerSupport.asPercent())
                        .font(.caption)
                    Circle()
                        .fill(Color.challengerRed)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 4)
        .stateAccessibility(state: state)
    }
}

// MARK: - Actions View

struct ActionsView: View {
    @ObservedObject var gameState: GameState
    @Binding var showingActionSheet: Bool
    @State private var selectedAction: CampaignActionType?
    @State private var selectedState: ElectoralState?
    
    var currentPlayer: Player {
        gameState.currentPlayer == .incumbent ? gameState.incumbent : gameState.challenger
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("Campaign Funds", systemImage: "dollarsign.circle.fill")
                    Spacer()
                    Text(currentPlayer.campaignFunds.asCurrency())
                        .fontWeight(.semibold)
                        .foregroundStyle(currentPlayer.campaignFunds < 1_000_000 ? .red : .primary)
                }
                
                HStack {
                    Label("Momentum", systemImage: "arrow.up.right.circle.fill")
                    Spacer()
                    HStack(spacing: 4) {
                        Text(currentPlayer.momentum.withSign())
                            .fontWeight(.semibold)
                            .foregroundStyle(currentPlayer.momentum >= 0 ? .green : .red)
                        
                        Image(systemName: currentPlayer.momentum >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundStyle(currentPlayer.momentum >= 0 ? .green : .red)
                    }
                }
                
                HStack {
                    Label("National Polling", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    Text(currentPlayer.nationalPolling.asPercent())
                        .fontWeight(.semibold)
                }
            } header: {
                Text("Resources - \(currentPlayer.name)")
            }
            
            Section("Available Actions") {
                ForEach(CampaignActionType.allCases, id: \.self) { actionType in
                    Button {
                        selectedAction = actionType
                        showingActionSheet = true
                    } label: {
                        ActionRow(actionType: actionType, canAfford: currentPlayer.campaignFunds >= actionType.cost)
                    }
                    .disabled(currentPlayer.campaignFunds < actionType.cost)
                }
            }
        }
        .sheet(isPresented: $showingActionSheet) {
            if let action = selectedAction {
                ActionDetailView(
                    gameState: gameState,
                    actionType: action,
                    isPresented: $showingActionSheet
                )
            }
        }
    }
}

struct ActionRow: View {
    let actionType: CampaignActionType
    let canAfford: Bool
    
    var body: some View {
        HStack {
            Image(systemName: actionType.systemImage)
                .font(.title3)
                .foregroundStyle(canAfford ? .blue : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(actionType.name)
                    .foregroundStyle(canAfford ? .primary : .secondary)
                
                Text("$\(actionType.cost / 1_000_000, specifier: "%.1f")M")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .campaignActionAccessibility(action: actionType, canAfford: canAfford)
    }
}

struct ActionDetailView: View {
    @ObservedObject var gameState: GameState
    let actionType: CampaignActionType
    @Binding var isPresented: Bool
    @State private var selectedState: ElectoralState?
    
    var needsStateSelection: Bool {
        switch actionType {
        case .fundraiser, .debate, .opposition:
            return false
        default:
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: actionType.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text(actionType.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(actionType.description)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if needsStateSelection {
                    VStack(alignment: .leading) {
                        Text("Select Target State")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        List(gameState.states) { state in
                            Button {
                                selectedState = state
                            } label: {
                                HStack {
                                    Text(state.name)
                                    Spacer()
                                    if selectedState?.id == state.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    executeAction()
                } label: {
                    Text("Execute Action - $\(actionType.cost / 1_000_000, specifier: "%.1f")M")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canExecute ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canExecute)
                .padding()
            }
            .navigationTitle("Campaign Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    var canExecute: Bool {
        if needsStateSelection {
            return selectedState != nil
        }
        return true
    }
    
    func executeAction() {
        let action = CampaignAction(
            type: actionType,
            targetState: selectedState,
            player: gameState.currentPlayer,
            turn: gameState.currentTurn
        )
        
        HapticsManager.shared.playActionFeedback()
        
        withAnimation {
            gameState.executeAction(action)
            gameState.endTurn()
        }
        
        HapticsManager.shared.playSuccessFeedback()
        AccessibilityAnnouncement.announce("\(actionType.name) executed successfully")
        
        isPresented = false
    }
}

// MARK: - Events View

struct EventsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        List {
            if gameState.recentEvents.isEmpty {
                ContentUnavailableView(
                    "No Events Yet",
                    systemImage: "newspaper",
                    description: Text("Campaign events will appear here as they occur.")
                )
            } else {
                ForEach(gameState.recentEvents) { event in
                    EventRow(event: event)
                }
            }
        }
    }
}

struct EventRow: View {
    let event: GameEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: eventIcon)
                    .foregroundStyle(impactColor)
                
                Text("Week \(event.turn)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(event.title)
                .font(.headline)
            
            Text(event.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let affected = event.affectedPlayer {
                Text("Affects: \(affected == .incumbent ? "Incumbent" : "Challenger")")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(impactColor.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(event.accessibilityDescription)
    }
    
    var eventIcon: String {
        switch event.type {
        case .scandal: return "exclamationmark.triangle.fill"
        case .economicNews: return "chart.bar.fill"
        case .endorsement: return "hand.thumbsup.fill"
        case .gaffe: return "quote.bubble.fill"
        case .crisis: return "bolt.fill"
        case .viral: return "sparkles"
        }
    }
    
    var impactColor: Color {
        event.impactMagnitude >= 0 ? .green : .red
    }
}

// MARK: - Results View

struct ResultsView: View {
    @ObservedObject var gameState: GameState
    @State private var showingStats = false
    @State private var showingShareSheet = false
    
    var body: some View {
        let votes = gameState.calculateElectoralVotes()
        let winner: String = votes.incumbent >= 270 ? gameState.incumbent.name : gameState.challenger.name
        let playerWon = (votes.incumbent >= 270 && !gameState.incumbent.isAI) || 
                       (votes.challenger >= 270 && !gameState.challenger.isAI)
        
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.red.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: playerWon ? "trophy.fill" : "flag.checkered")
                            .font(.system(size: 80))
                            .foregroundStyle(playerWon ? Color.yellow : Color.blue)
                            .accessibilityLabel(playerWon ? "Victory trophy" : "Race finished flag")
                        
                        VStack(spacing: 8) {
                            Text(playerWon ? "Victory!" : "Campaign Over")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Election Results")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 20) {
                            Text("Winner")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            
                            Text(winner)
                                .font(.system(size: 44))
                                .fontWeight(.bold)
                            
                            HStack(spacing: 40) {
                                VStack {
                                    Text("\(votes.incumbent)")
                                        .font(.system(size: 50))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                    
                                    Text(gameState.incumbent.name)
                                        .font(.headline)
                                    
                                    if votes.incumbent >= 270 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .accessibilityLabel("Winner")
                                    }
                                }
                                
                                VStack {
                                    Text("\(votes.challenger)")
                                        .font(.system(size: 50))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                    
                                    Text(gameState.challenger.name)
                                        .font(.headline)
                                    
                                    if votes.challenger >= 270 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .accessibilityLabel("Winner")
                                    }
                                }
                            }
                            .padding()
                            .background(Color(white: 1.0))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Campaign Stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Campaign Statistics")
                                .font(.headline)
                            
                            StatRow(label: "Total Weeks", value: "\(gameState.maxTurns)")
                            StatRow(label: "Events Occurred", value: "\(gameState.recentEvents.count)")
                            StatRow(
                                label: "Final Polling",
                                value: "\(gameState.incumbent.nationalPolling.asPercent()) vs \(gameState.challenger.nationalPolling.asPercent())"
                            )
                        }
                        .padding()
                        .background(Color(white: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button {
                                HapticsManager.shared.playActionFeedback()
                                shareResults(votes: votes, winner: winner)
                            } label: {
                                Label("Share Results", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                HapticsManager.shared.playActionFeedback()
                                resetGame()
                            } label: {
                                Text("New Campaign")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationTitle("Campaign Complete")
            .onAppear {
                HapticsManager.shared.playGameEndFeedback()
                AccessibilityAnnouncement.announceScreenChange("\(winner) wins the election with \(votes.incumbent >= 270 ? votes.incumbent : votes.challenger) electoral votes")
                
                // Clear auto-save
                try? PersistenceManager.shared.deleteAutoSave()
            }
        }
    }
    
    private func resetGame() {
        withAnimation {
            gameState.gamePhase = .setup
            gameState.currentTurn = 1
            gameState.currentPlayer = .incumbent
            gameState.states = GameState.createInitialStates()
            gameState.recentEvents = []
            
            // Reset players
            gameState.incumbent = Player(
                type: .incumbent,
                isAI: false,
                name: "President Morgan",
                partyName: "Liberty Party",
                partyColor: "#3498db"
            )
            
            gameState.challenger = Player(
                type: .challenger,
                isAI: true,
                name: "Senator Davis",
                partyName: "Progress Party",
                partyColor: "#e74c3c"
            )
        }
    }
    
    private func shareResults(votes: (incumbent: Int, challenger: Int), winner: String) {
        let text = """
        🏛️ Campaign Manager 2026 Results
        
        Winner: \(winner)
        
        Final Electoral Votes:
        \(gameState.incumbent.name): \(votes.incumbent)
        \(gameState.challenger.name): \(votes.challenger)
        
        Play Campaign Manager 2026!
        """
        
        #if canImport(UIKit)
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ContentView()
}
