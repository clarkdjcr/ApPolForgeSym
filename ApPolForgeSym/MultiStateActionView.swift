//
//  MultiStateActionView.swift
//  ApPolForgeSym
//
//  Enhanced action view supporting multiple state selection
//

import SwiftUI

struct MultiStateActionView: View {
    @ObservedObject var gameState: GameState
    let actionType: CampaignActionType
    @Binding var isPresented: Bool
    
    @State private var selectedStates: Set<UUID> = []
    @State private var showingConfirmation = false
    
    var currentPlayer: Player {
        gameState.currentPlayer == .incumbent ? gameState.incumbent : gameState.challenger
    }
    
    var eligibleStates: [ElectoralState] {
        // Sort by relevance - battlegrounds first, then by EV
        gameState.states.sorted { state1, state2 in
            if state1.isBattleground != state2.isBattleground {
                return state1.isBattleground
            }
            return state1.electoralVotes > state2.electoralVotes
        }
    }
    
    var totalCost: Double {
        guard !selectedStates.isEmpty else { return actionType.cost }
        let baseCost = actionType.cost
        let extraStates = selectedStates.count - 1
        return baseCost * (1.0 + Double(extraStates) * 0.2)
    }
    
    var canAfford: Bool {
        currentPlayer.campaignFunds >= totalCost
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: actionType.systemImage)
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text(actionType.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(actionType.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(.quaternary)
                HStack {
                    Label("Total Cost", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(totalCost.asCurrency())
                            .font(.headline)
                            .foregroundColor(canAfford ? .primary : .red)
                        
                        if selectedStates.count > 1 {
                            Text("\(selectedStates.count) states × pricing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                
                Divider()
                
                // State selection list
                List {
                    Section {
                        ForEach(eligibleStates) { state in
                            MultiStateSelectionRow(
                                state: state,
                                isSelected: selectedStates.contains(state.id),
                                playerType: gameState.currentPlayer
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleStateSelection(state.id)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Select Target States")
                            Spacer()
                            if !selectedStates.isEmpty {
                                Text("\(selectedStates.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    } footer: {
                        Text("Select multiple states for a coordinated campaign. Each additional state adds 20% to the base cost but increases total impact.")
                            .font(.caption)
                    }
                }
                
                // Action button
                VStack(spacing: 8) {
                    if !canAfford {
                        Text("⚠️ Insufficient funds")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        HapticsManager.shared.playSelectionFeedback()
                        showingConfirmation = true
                    } label: {
                        Text("Execute in \(selectedStates.count) State\(selectedStates.count == 1 ? "" : "s") - \(totalCost.asCurrency())")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canExecute ? Color.blue : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canExecute)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Plan Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Confirm Action", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Execute") {
                    executeMultiStateAction()
                }
            } message: {
                Text("Execute \(actionType.name) in \(selectedStates.count) state(s) for \(totalCost.asCurrency())?")
            }
        }
    }
    
    private var canExecute: Bool {
        !selectedStates.isEmpty && canAfford
    }
    
    private func toggleStateSelection(_ stateId: UUID) {
        HapticsManager.shared.playSelectionFeedback()
        
        if selectedStates.contains(stateId) {
            selectedStates.remove(stateId)
        } else {
            selectedStates.insert(stateId)
        }
    }
    
    private func executeMultiStateAction() {
        let targetStates = gameState.states.filter { selectedStates.contains($0.id) }
        
        // Deduct total cost
        if gameState.currentPlayer == .incumbent {
            gameState.incumbent.campaignFunds -= totalCost
        } else {
            gameState.challenger.campaignFunds -= totalCost
        }
        
        // Execute action in each state with slight efficiency bonus for multi-state
        let efficiencyBonus = selectedStates.count > 1 ? 1.1 : 1.0
        
        for state in targetStates {
            guard let index = gameState.states.firstIndex(where: { $0.id == state.id }) else { continue }
            
            // Apply effects based on action type
            switch actionType {
            case .rally:
                if gameState.currentPlayer == .incumbent {
                    gameState.states[index].incumbentSupport += Double.random(in: 1...4) * efficiencyBonus
                    gameState.incumbent.momentum += Int(Double.random(in: 2...5) * efficiencyBonus)
                } else {
                    gameState.states[index].challengerSupport += Double.random(in: 1...4) * efficiencyBonus
                    gameState.challenger.momentum += Int(Double.random(in: 2...5) * efficiencyBonus)
                }
                
            case .adCampaign:
                if gameState.currentPlayer == .incumbent {
                    gameState.states[index].incumbentSupport += Double.random(in: 2...6) * efficiencyBonus
                } else {
                    gameState.states[index].challengerSupport += Double.random(in: 2...6) * efficiencyBonus
                }
                
            case .townHall:
                if gameState.currentPlayer == .incumbent {
                    gameState.states[index].incumbentSupport += Double.random(in: 1...3) * efficiencyBonus
                    gameState.incumbent.nationalPolling += 0.5 * efficiencyBonus
                } else {
                    gameState.states[index].challengerSupport += Double.random(in: 1...3) * efficiencyBonus
                    gameState.challenger.nationalPolling += 0.5 * efficiencyBonus
                }
                
            case .grassroots:
                if gameState.currentPlayer == .incumbent {
                    gameState.states[index].incumbentSupport += Double.random(in: 1...2) * efficiencyBonus
                } else {
                    gameState.states[index].challengerSupport += Double.random(in: 1...2) * efficiencyBonus
                }
                
            default:
                break
            }
        }
        
        // National actions
        if actionType == .fundraiser {
            let fundraiseAmount = Double.random(in: 1_000_000...3_000_000)
            if gameState.currentPlayer == .incumbent {
                gameState.incumbent.campaignFunds += fundraiseAmount
            } else {
                gameState.challenger.campaignFunds += fundraiseAmount
            }
        } else if actionType == .debate {
            if gameState.currentPlayer == .incumbent {
                gameState.incumbent.momentum += Int.random(in: 3...8)
            } else {
                gameState.challenger.momentum += Int.random(in: 3...8)
            }
        } else if actionType == .opposition {
            if gameState.currentPlayer == .incumbent {
                gameState.challenger.nationalPolling -= Double.random(in: 0.5...2.0)
                gameState.challenger.momentum -= Int.random(in: 3...8)
            } else {
                gameState.incumbent.nationalPolling -= Double.random(in: 0.5...2.0)
                gameState.incumbent.momentum -= Int.random(in: 3...8)
            }
        }
        
        HapticsManager.shared.playSuccessFeedback()
        
        withAnimation {
            if !gameState.canAffordAnyAction(for: gameState.currentPlayer) {
                gameState.forceEndTurn()
            } else {
                gameState.useAction()
            }
        }

        isPresented = false
    }
}

struct MultiStateSelectionRow: View {
    let state: ElectoralState
    let isSelected: Bool
    let playerType: PlayerType
    
    var ourSupport: Double {
        playerType == .incumbent ? state.incumbentSupport : state.challengerSupport
    }
    
    var theirSupport: Double {
        playerType == .incumbent ? state.challengerSupport : state.incumbentSupport
    }
    
    var margin: Double {
        ourSupport - theirSupport
    }
    
    var statusIcon: String {
        if margin > 10 {
            return "checkmark.shield.fill"
        } else if margin > 5 {
            return "checkmark.circle.fill"
        } else if margin > 0 {
            return "circle.fill"
        } else if margin > -5 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        if margin > 5 {
            return .green
        } else if margin > -5 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.blue : Color.gray.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(state.name)
                        .font(.headline)
                    
                    if state.isBattleground {
                        Text("BATTLEGROUND")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                }
                
                HStack {
                    Text("\(state.electoralVotes) EV")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("Us: \(ourSupport, specifier: "%.1f")%")
                            .font(.caption)
                        
                        Text("Them: \(theirSupport, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MultiStateActionView(
        gameState: GameState(),
        actionType: .adCampaign,
        isPresented: .constant(true)
    )
}
