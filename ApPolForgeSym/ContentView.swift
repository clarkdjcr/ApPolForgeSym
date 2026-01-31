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
// MARK: - CodeAI Output
// *** PLEASE SUBSCRIBE TO GAIN CodeAI ACCESS! ***
/// To subscribe, open CodeAI MacOS app and tap SUBSCRIBE
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
    @StateObject private var settings = AppSettings.shared
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingAIDifficulty = false
    
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
                        // AI Difficulty Selection
                        Button {
                            HapticsManager.shared.playSelectionFeedback()
                            showingAIDifficulty = true
                        } label: {
                            HStack {
                                Image(systemName: settings.aiDifficulty.icon)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Difficulty: \(settings.aiDifficulty.rawValue)")
                                        .font(.headline)
                                    
                                    Text(settings.aiDifficulty.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                                                        .background {
                                                            #if os(iOS)
                                                            Color(uiColor: .systemGray6)
                                                            #else
                                                            Color(nsColor: .quaternaryLabelColor)
                                                            #endif
                                                        }
                                                        .clipShape(RoundedRectangle(cornerRadius: 12)).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
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
            .confirmationDialog("Select AI Difficulty", isPresented: $showingAIDifficulty, titleVisibility: .visible) {
                ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                    Button(difficulty.rawValue) {
                        settings.aiDifficulty = difficulty
                        HapticsManager.shared.playSelectionFeedback()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose the AI opponent's difficulty level")
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
                        .foregroundColor(.primary)
                    
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
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
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
    @State private var showingAIActionReport = false
    @State private var aiOpponent: AIOpponent?
    @StateObject private var shadowManager: ShadowBudgetManager
    @StateObject private var strategicAdvisor: StrategicAdvisor

    var isPlayerTurn: Bool {
        if gameState.currentPlayer == .incumbent {
            return !gameState.incumbent.isAI
        } else {
            return !gameState.challenger.isAI
        }
    }

    init(gameState: GameState) {
        self._gameState = ObservedObject(wrappedValue: gameState)
        self._shadowManager = StateObject(wrappedValue: ShadowBudgetManager(gameState: gameState))
        self._strategicAdvisor = StateObject(wrappedValue: StrategicAdvisor(gameState: gameState))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with turn and electoral count
                HeaderView(gameState: gameState, shadowManager: shadowManager)
                
                // Current player indicator / AI action report
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
                    .background {
                        #if canImport(UIKit)
                        Color(uiColor: .systemBackground)
                        #elseif canImport(AppKit)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                    .accessibilityLabel("AI opponent is thinking")
                } else if showingAIActionReport, let aiAction = gameState.lastAIAction {
                    // Show what the AI did on their last turn
                    AIActionReportBanner(action: aiAction) {
                        withAnimation {
                            showingAIActionReport = false
                        }
                    }
                }

                // Action counter for multi-action turns
                if isPlayerTurn && gameState.maxActionsThisTurn > 1 {
                    HStack(spacing: 12) {
                        Label("Actions: \(gameState.actionsRemainingThisTurn)/\(gameState.maxActionsThisTurn)",
                              systemImage: "bolt.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Button("End Turn Early") {
                            HapticsManager.shared.playTurnEndFeedback()
                            gameState.forceEndTurn()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .disabled(gameState.actionsRemainingThisTurn == gameState.maxActionsThisTurn)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Actions remaining: \(gameState.actionsRemainingThisTurn) of \(gameState.maxActionsThisTurn)")
                }

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Map").tag(0)
                    Text("Actions").tag(1)
                    Text("Strategy").tag(2)
                    Text("Shadow").tag(3)
                    Text("Events").tag(4)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedTab) { _, _ in
                    HapticsManager.shared.playSelectionFeedback()
                }
                
                // Content
                // Content - Only render selected tab to avoid performance issues
                Group {
                    switch selectedTab {
                    case 0:
                        MapView(gameState: gameState)
                    case 1:
                        ActionsView(gameState: gameState, showingActionSheet: $showingActionSheet)
                    case 2:
                        StrategicDashboardView(gameState: gameState)
                    case 3:
                        ShadowBudgetView(gameState: gameState, shadowManager: shadowManager)
                    case 4:
                        EventsView(gameState: gameState)
                    default:
                        MapView(gameState: gameState)
                    }
                }
                .animation(.default, value: selectedTab)
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
                        selectedTab = 1 // Switch to Actions tab
                    } label: {
                        Label("Take Action", systemImage: "flag.fill")
                    }
                    .disabled(!isPlayerTurn)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        selectedTab = 1 // Switch to Actions tab
                    } label: {
                        Label("Take Action", systemImage: "flag.fill")
                    }
                    .disabled(!isPlayerTurn)
                }
                #endif
            }
            .onAppear {
                aiOpponent = AIOpponent(gameState: gameState)
                gameState.calculateActionsForTurn(advisor: strategicAdvisor)
                checkForAITurn()
            }
            .onChange(of: gameState.currentPlayer) { oldPlayer, newPlayer in
                HapticsManager.shared.playTurnEndFeedback()

                // Process shadow budget for this turn
                shadowManager.processTurn(for: gameState.currentPlayer)

                // Calculate action budget for the new player's turn
                gameState.calculateActionsForTurn(advisor: strategicAdvisor)

                // Show AI action report if AI just finished their turn
                if isPlayerTurn && gameState.lastAIAction != nil {
                    withAnimation {
                        showingAIActionReport = true
                    }
                    // Auto-dismiss after 5 seconds
                    Task {
                        try? await Task.sleep(for: .seconds(5))
                        await MainActor.run {
                            withAnimation {
                                showingAIActionReport = false
                            }
                        }
                    }
                }

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

// MARK: - AI Action Report Banner

struct AIActionReportBanner: View {
    let action: AIActionReport
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.red)
                Text("AI Opponent's Move")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Image(systemName: action.actionType.systemImage)
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.summary)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text(action.strategy)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())

                        Text(action.cost.asCurrency())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI opponent used \(action.actionType.name)\(action.targetState != nil ? " in \(action.targetState!.name)" : "")")
    }
}

struct HeaderView: View {
    @ObservedObject var gameState: GameState
    var shadowManager: ShadowBudgetManager?

    var body: some View {
        let votes = gameState.calculateElectoralVotes()

        VStack(spacing: 0) {
            HStack(spacing: 20) {
                VStack {
                    Text("\(votes.incumbent)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)

                    Text(gameState.incumbent.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
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
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .padding()

            // Shadow Operations Status Indicator
            if let shadowManager = shadowManager {
                ShadowStatusIndicator(gameState: gameState, shadowManager: shadowManager)
            }
        }
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(uiColor: .systemGray6))
        #endif
        .electoralVoteAccessibility(
            incumbentVotes: votes.incumbent,
            challengerVotes: votes.challenger,
            incumbentName: gameState.incumbent.name,
            challengerName: gameState.challenger.name
        )
    }
}

// MARK: - Shadow Status Indicator

struct ShadowStatusIndicator: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var shadowManager: ShadowBudgetManager

    var shadowState: ShadowBudgetState {
        gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentShadowState :
            shadowManager.challengerShadowState
    }

    var currentZone: ShadowBudgetZone {
        ShadowBudgetZone.zone(for: shadowState.allocationPercentage)
    }

    var detectionRisk: Double {
        let shell = gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentShellCompany :
            shadowManager.challengerShellCompany
        let baseDetection = shadowState.allocationPercentage / 100.0
        let reduction = shell.isActive ? shell.detectionReduction : 0.0
        return baseDetection * (1.0 - reduction) * 100
    }

    var body: some View {
        // Only show if allocation is above transparent zone
        if shadowState.allocationPercentage > 5 {
            HStack(spacing: 12) {
                // Zone indicator
                HStack(spacing: 6) {
                    Image(systemName: currentZone == .blackOps ? "exclamationmark.triangle.fill" : "eye.fill")
                        .font(.caption)
                    Text(currentZone == .blackOps ? "BLACK OPS" : "SHADOW OPS")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(currentZone == .blackOps ? .white : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(currentZone == .blackOps ? Color.red : Color.orange.opacity(0.3))
                .clipShape(Capsule())

                // Detection risk
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption2)
                    Text("Detection: \(String(format: "%.1f", detectionRisk))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(detectionRisk > 15 ? .red : .orange)

                Spacer()

                // Allocation level
                Text("\(Int(shadowState.allocationPercentage))% allocated")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(currentZone == .blackOps ? Color.red.opacity(0.15) : Color.orange.opacity(0.1))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Shadow operations active at \(Int(shadowState.allocationPercentage)) percent. Detection risk \(String(format: "%.1f", detectionRisk)) percent")
        } else if !shadowState.activeScandals.isEmpty {
            // Show active scandal warning even if allocation is low
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("SCANDAL ACTIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                Spacer()
                Text("\(shadowState.activeScandals.count) active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.1))
        }
    }
}

// MARK: - Map View

struct MapView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedTierFilter: Int? = nil
    @State private var searchText = ""

    private var filteredStates: [ElectoralState] {
        var result = gameState.states

        // Apply tier filter
        if let tier = selectedTierFilter {
            result = result.filter { $0.competitivenessTier == tier }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.abbreviation.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var battlegroundStates: [ElectoralState] {
        filteredStates.filter { $0.isBattleground }
    }

    private var otherStates: [ElectoralState] {
        filteredStates.filter { !$0.isBattleground }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tier filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TierFilterPill(label: "All", isSelected: selectedTierFilter == nil) {
                        selectedTierFilter = nil
                    }
                    TierFilterPill(label: "Battleground", tier: 1, isSelected: selectedTierFilter == 1) {
                        selectedTierFilter = 1
                    }
                    TierFilterPill(label: "Competitive", tier: 2, isSelected: selectedTierFilter == 2) {
                        selectedTierFilter = 2
                    }
                    TierFilterPill(label: "Leaning", tier: 3, isSelected: selectedTierFilter == 3) {
                        selectedTierFilter = 3
                    }
                    TierFilterPill(label: "Safe", tier: 4, isSelected: selectedTierFilter == 4) {
                        selectedTierFilter = 4
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            List {
                if !battlegroundStates.isEmpty {
                    Section("Battleground States (\(battlegroundStates.count))") {
                        ForEach(battlegroundStates) { state in
                            StateRow(state: state)
                        }
                    }
                }

                if !otherStates.isEmpty {
                    Section("Other States (\(otherStates.count))") {
                        ForEach(otherStates) { state in
                            StateRow(state: state)
                        }
                    }
                }

                if filteredStates.isEmpty {
                    ContentUnavailableView("No States Found", systemImage: "map", description: Text("Try adjusting your filter or search."))
                }
            }
            .searchable(text: $searchText, prompt: "Search states")
        }
    }
}

struct TierFilterPill: View {
    let label: String
    var tier: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    private var tierColor: Color {
        switch tier {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .blue
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? tierColor.opacity(0.3) : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? tierColor : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? tierColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct StateRow: View {
    let state: ElectoralState

    private func tierBadgeColor(for tier: Int) -> Color {
        switch tier {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.stateColor(for: state))
                    .frame(width: 12, height: 12)
                
                Text(state.name)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(state.electoralVotes) EV")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(state.tierLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tierBadgeColor(for: state.competitivenessTier).opacity(0.2))
                        .foregroundStyle(tierBadgeColor(for: state.competitivenessTier))
                        .clipShape(Capsule())
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

                HStack {
                    Label("Actions Remaining", systemImage: "bolt.circle.fill")
                    Spacer()
                    Text("\(gameState.actionsRemainingThisTurn) of \(gameState.maxActionsThisTurn)")
                        .fontWeight(.semibold)
                        .foregroundStyle(gameState.actionsRemainingThisTurn > 0 ? .blue : .gray)
                }
            } header: {
                Text("Resources - \(currentPlayer.name)")
            }
            
            Section("Available Actions") {
                ForEach(CampaignActionType.allCases, id: \.self) { actionType in
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        selectedAction = actionType
                        showingActionSheet = true
                    } label: {
                        ActionRow(actionType: actionType, canAfford: currentPlayer.campaignFunds >= actionType.cost)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPlayer.campaignFunds < actionType.cost || gameState.actionsRemainingThisTurn <= 0)
                }
            }
        }
        .sheet(item: $selectedAction) { action in
            ActionDetailView(
                gameState: gameState,
                actionType: action,
                isPresented: $showingActionSheet,
                onDismiss: {
                    selectedAction = nil
                }
            )
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 600)
            #endif
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
    var onDismiss: (() -> Void)?
    @State private var selectedStates: Set<UUID> = []
    
    var needsStateSelection: Bool {
        switch actionType {
        case .fundraiser, .debate, .opposition:
            return false
        default:
            return true
        }
    }
    
    var currentPlayer: Player {
        gameState.currentPlayer == .incumbent ? gameState.incumbent : gameState.challenger
    }
    
    var maxSelectableStates: Int {
        // Allow selecting multiple states based on budget
        let costPerState = actionType.cost
        return max(1, Int(currentPlayer.campaignFunds / costPerState))
    }
    
    var totalCost: Double {
        if needsStateSelection {
            return Double(selectedStates.count) * actionType.cost
        }
        return actionType.cost
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: actionType.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top)
                
                Text(actionType.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(actionType.description)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                
                if needsStateSelection {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Select Target State(s)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(selectedStates.count) of \(maxSelectableStates) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        List(gameState.states) { state in
                            Button {
                                HapticsManager.shared.playSelectionFeedback()
                                toggleStateSelection(state)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(state.name)
                                            .foregroundStyle(.primary)
                                        
                                        HStack {
                                            Text("\(state.electoralVotes) EV")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)

                                            Text("• \(state.tierLabel)")
                                                .font(.caption2)
                                                .foregroundStyle(state.competitivenessTier <= 2 ? .orange : .secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedStates.contains(state.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.gray.opacity(0.5))
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedStates.count >= maxSelectableStates && !selectedStates.contains(state.id))
                            .opacity((selectedStates.count >= maxSelectableStates && !selectedStates.contains(state.id)) ? 0.5 : 1.0)
                        }
                        #if os(macOS)
                        .listStyle(.bordered(alternatesRowBackgrounds: true))
                        #endif
                    }
                } else {
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    if needsStateSelection && selectedStates.count > 1 {
                        Text("Total Cost: \(totalCost.asCurrency())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        executeAction()
                    } label: {
                        let costText = needsStateSelection && selectedStates.count > 1 
                            ? "Execute on \(selectedStates.count) States - \(totalCost.asCurrency())"
                            : "Execute Action - \(actionType.cost.asCurrency())"
                        
                        Text(costText)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canExecute ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canExecute)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .navigationTitle("Campaign Action")
            #if os(macOS)
            .navigationSubtitle(actionType.name)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        onDismiss?()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                if needsStateSelection && !selectedStates.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear All") {
                            HapticsManager.shared.playSelectionFeedback()
                            selectedStates.removeAll()
                        }
                    }
                }
            }
        }
    }
    
    private func toggleStateSelection(_ state: ElectoralState) {
        if selectedStates.contains(state.id) {
            selectedStates.remove(state.id)
        } else if selectedStates.count < maxSelectableStates {
            selectedStates.insert(state.id)
        }
    }
    
    var canExecute: Bool {
        if needsStateSelection {
            return !selectedStates.isEmpty && totalCost <= currentPlayer.campaignFunds
        }
        return currentPlayer.campaignFunds >= actionType.cost
    }
    
    func executeAction() {
        HapticsManager.shared.playActionFeedback()

        withAnimation {
            if needsStateSelection {
                // Execute action on each selected state
                for stateId in selectedStates {
                    if let state = gameState.states.first(where: { $0.id == stateId }) {
                        let action = CampaignAction(
                            type: actionType,
                            targetState: state,
                            player: gameState.currentPlayer,
                            turn: gameState.currentTurn
                        )
                        gameState.executeAction(action)
                        gameState.actionsUsedThisTurn.append(action)
                    }
                }
            } else {
                // Execute non-state action once
                let action = CampaignAction(
                    type: actionType,
                    targetState: nil,
                    player: gameState.currentPlayer,
                    turn: gameState.currentTurn
                )
                gameState.executeAction(action)
                gameState.actionsUsedThisTurn.append(action)
            }

            // Check if player can afford anything else; if not, force end
            if !gameState.canAffordAnyAction(for: gameState.currentPlayer) {
                gameState.forceEndTurn()
            } else {
                gameState.useAction() // decrements; auto-ends turn if 0
            }
        }

        HapticsManager.shared.playSuccessFeedback()

        let message = selectedStates.count > 1
            ? "\(actionType.name) executed in \(selectedStates.count) states"
            : "\(actionType.name) executed successfully"
        AccessibilityAnnouncement.announce(message)

        isPresented = false
        onDismiss?()
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
        // Determine winner: 270+ wins outright, otherwise whoever has more votes wins
        let incumbentWins = votes.incumbent >= 270 || (votes.challenger < 270 && votes.incumbent > votes.challenger)
        let winner: String = incumbentWins ? gameState.incumbent.name : gameState.challenger.name
        let playerWon = (incumbentWins && !gameState.incumbent.isAI) ||
                       (!incumbentWins && !gameState.challenger.isAI)
        
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
                                    
                                    if incumbentWins {
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

                                    if !incumbentWins {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .accessibilityLabel("Winner")
                                    }
                                }
                            }
                            .padding()
                            .background {
                                #if canImport(UIKit)
                                Color(uiColor: .systemBackground)
                                #elseif canImport(AppKit)
                                Color(nsColor: .windowBackgroundColor)
                                #endif
                            }
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
                        .background {
                            #if canImport(UIKit)
                            Color(uiColor: .systemBackground)
                            #elseif canImport(AppKit)
                            Color(nsColor: .windowBackgroundColor)
                            #endif
                        }
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
                AccessibilityAnnouncement.announceScreenChange("\(winner) wins the election with \(incumbentWins ? votes.incumbent : votes.challenger) electoral votes")
                
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

            // Reset players (funds come from CampaignDataLoader via Player.init)
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
