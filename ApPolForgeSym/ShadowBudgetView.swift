//
//  ShadowBudgetView.swift
//  ApPolForgeSym
//
//  The "Nixon Disease" UI - Shadow Budget Slider with Ominous Feedback
//

import SwiftUI

struct ShadowBudgetView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var shadowManager: ShadowBudgetManager
    
    @State private var sliderValue: Double = 0.0
    @State private var showingOperations = false
    @State private var showingShellSetup = false
    @State private var showingWarning = false
    @State private var showingScandal = false
    @State private var selectedOperation: ShadowOperationType?
    @State private var glitchOffset: CGFloat = 0
    @State private var showGlitch = false
    @State private var userConfirmedBlackOps = false

    // IMPORTANT FIX: Cache these values to prevent infinite loops
    @State private var cachedShadowState: ShadowBudgetState?
    @State private var cachedIntegrity: IntegrityBonus?
    
    var currentPlayer: Player {
        gameState.currentPlayer == .incumbent ? gameState.incumbent : gameState.challenger
    }
    
    var shadowState: ShadowBudgetState {
        gameState.currentPlayer == .incumbent ? 
            shadowManager.incumbentShadowState : 
            shadowManager.challengerShadowState
    }
    
    var integrity: IntegrityBonus {
        gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentIntegrity :
            shadowManager.challengerIntegrity
    }
    
    var currentZone: ShadowBudgetZone {
        ShadowBudgetZone.zone(for: sliderValue)
    }

    // Platform-specific panel background color
    private var panelBackgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.88)
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with integrity status
                headerSection
                
                // The infamous slider
                sliderSection
                
                // Zone description
                zoneInfoSection
                
                // Integrity bonus display
                if shadowState.hasIntegrityBonus {
                    integrityBonusSection
                }
                
                // Shell company option
                if sliderValue > 10 {
                    shellCompanySection
                }
                
                // Available operations
                if sliderValue > 5 {
                    operationsSection
                }
                
                // Active scandals
                if !shadowState.activeScandals.isEmpty {
                    scandalsSection
                }
                
                // Current effects
                if shadowState.hasStolenOpponentData || !shadowState.collectedDirt.isEmpty {
                    activeEffectsSection
                }
            }
            .padding()
        }
        .navigationTitle("Discretionary Fund Allocation")
        .onAppear {
            sliderValue = shadowState.allocationPercentage
            cachedShadowState = shadowState
            cachedIntegrity = integrity
        }
        .sheet(isPresented: $showingOperations) {
            if let operation = selectedOperation {
                OperationDetailView(
                    operation: operation,
                    shadowManager: shadowManager,
                    gameState: gameState,
                    isPresented: $showingOperations
                )
            }
        }
        .alert("Enter the Red Zone?", isPresented: $showingWarning) {
            Button("Cancel", role: .cancel) {
                sliderValue = 14
            }
            Button("Proceed", role: .destructive) {
                userConfirmedBlackOps = true
                commitAllocation()
            }
        } message: {
            Text("Operating in the Black Ops zone significantly increases detection risk. If caught, your campaign could be destroyed. Are you sure?")
        }
    }
    
    // MARK: - Header Section
    
    var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: integrity.hasTeflonShield ? "shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(integrity.hasTeflonShield ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text("Campaign Integrity")
                        .font(.headline)
                    Text("\(Int(integrity.reputation))% Reputation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if shadowState.turnsInGreenZone > 0 {
                    VStack(alignment: .trailing) {
                        Text("\(shadowState.turnsInGreenZone) turns")
                            .font(.caption)
                        Text("clean")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if integrity.hasTeflonShield {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("TEFLON SHIELD ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Spacer()
                    Text("×\(String(format: "%.1f", integrity.fundraisingMultiplier)) Fundraising")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .padding(8)
                .background(Color.green.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(panelBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Slider Section
    
    var sliderSection: some View {
        VStack(spacing: 16) {
            Text("Shadow Budget Allocation")
                .font(.headline)
            
            // The slider with glitch effect
            ZStack {
                Slider(value: $sliderValue, in: 0...30, step: 1)
                    .tint(zoneColor)
                    .onChange(of: sliderValue) { oldValue, newValue in
                        handleSliderChange(from: oldValue, to: newValue)
                    }
                    .offset(x: showGlitch ? glitchOffset : 0)
                
                if showGlitch {
                    Slider(value: .constant(sliderValue), in: 0...30, step: 1)
                        .tint(zoneColor)
                        .opacity(0.3)
                        .offset(x: -glitchOffset)
                        .allowsHitTesting(false)
                }
            }
            
            // Value display
            HStack {
                Text("0%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(sliderValue))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(zoneColor)
                    .monospacedDigit()
                
                Spacer()
                
                Text("30%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Zone markers
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green.opacity(0.6))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.orange.opacity(0.6))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.red.opacity(0.6))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
            .clipShape(Capsule())
            
            HStack {
                Text("Safe")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Spacer()
                Text("Risky")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Spacer()
                Text("DANGER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }
            
            Button {
                commitAllocation()
            } label: {
                Text("Commit Allocation")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sliderValue != shadowState.allocationPercentage ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(sliderValue == shadowState.allocationPercentage)
        }
        .padding()
        .background(panelBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var zoneColor: Color {
        switch currentZone {
        case .transparent: return .green
        case .aggressive: return .orange
        case .blackOps: return .red
        }
    }
    
    // MARK: - Zone Info Section
    
    var zoneInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(zoneColor)
                    .frame(width: 12, height: 12)
                
                Text(currentZone.rawValue)
                    .font(.headline)
                
                Spacer()
                
                if currentZone == .blackOps {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            
            Text(zoneDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if sliderValue > 0 {
                Divider()
                
                HStack {
                    Text("Detection Risk:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(calculateDetectionRisk())
                        .font(.caption)
                        .foregroundStyle(currentZone == .blackOps ? .red : .orange)
                }
            }
        }
        .padding()
        .background(zoneColor.opacity(0.25))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(zoneColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var zoneDescription: String {
        switch currentZone {
        case .transparent:
            return "All campaign activities are above board and fully transparent. No risk of scandal."
        case .aggressive:
            return "Aggressive but legal opposition research. Moderate risk if discovered."
        case .blackOps:
            return "ILLEGAL OPERATIONS. If exposed, your campaign will face federal investigation and likely collapse."
        }
    }
    
    // MARK: - Integrity Bonus Section
    
    var integrityBonusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Integrity Bonus Active")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                    Text("Fundraising: ×1.2 multiplier")
                    Spacer()
                    Text("+20%")
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.blue)
                    Text("Teflon Shield: Blocks opponent attacks")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)
            
            Text("Keep allocation under 5% to maintain these bonuses.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Shell Company Section
    
    var shellCompanySection: some View {
        let shell = gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentShellCompany :
            shadowManager.challengerShellCompany
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.purple)
                Text("Shell Company Layer")
                    .font(.headline)
                
                Spacer()
                
                if shell.isActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            Text("Route funds through shell companies to reduce detection risk by 50%, but doubles all operation costs.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !shell.isActive {
                Button {
                    showingShellSetup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Setup Shell Company - \(shell.setupCost.asCurrency())")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentPlayer.campaignFunds >= shell.setupCost ? Color.purple : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(currentPlayer.campaignFunds < shell.setupCost)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Detection Reduction:")
                        Spacer()
                        Text("-\(Int(shell.detectionReduction * 100))%")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("Cost Multiplier:")
                        Spacer()
                        Text("×\(String(format: "%.1f", shell.costMultiplier))")
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Establish Shell Company?", isPresented: $showingShellSetup) {
            Button("Cancel", role: .cancel) { }
            Button("Setup - \(shell.setupCost.asCurrency())") {
                setupShellCompany()
            }
        } message: {
            Text("This will route your shadow operations through a complex network of shell companies, reducing detection risk but doubling costs. If caught, you'll face additional money laundering charges.")
        }
    }
    
    // MARK: - Operations Section
    
    var operationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Shadow Operations")
                .font(.headline)
            
            ForEach(ShadowOperationType.allCases, id: \.self) { operation in
                OperationRow(
                    operation: operation,
                    canExecute: sliderValue >= operation.minimumAllocation,
                    hasFunds: currentPlayer.campaignFunds >= operation.baseCost
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if sliderValue >= operation.minimumAllocation {
                        selectedOperation = operation
                        showingOperations = true
                    }
                }
            }
        }
        .padding()
        .background(panelBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Scandals Section
    
    var scandalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
                Text("Active Scandals")
                    .font(.headline)
            }
            
            ForEach(shadowState.activeScandals) { scandal in
                ScandalCard(
                    scandal: scandal,
                    shadowManager: shadowManager,
                    gameState: gameState
                )
            }
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Active Effects Section
    
    var activeEffectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Shadow Operations")
                .font(.headline)
            
            if shadowState.hasStolenOpponentData {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.purple)
                    Text("Opponent's data stolen - their analytics blinded")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.caption)
            }
            
            ForEach(shadowState.collectedDirt, id: \.self) { dirt in
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(.orange)
                    Text(dirt)
                    Spacer()
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func handleSliderChange(from oldValue: Double, to newValue: Double) {
        // Entering red zone
        if oldValue <= 15 && newValue > 15 {
            // Trigger ominous haptics
            HapticsManager.shared.playErrorFeedback()
            
            // Trigger glitch effect
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3)) {
                showGlitch = true
                glitchOffset = 3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showGlitch = false
                glitchOffset = 0
            }
        }
        
        // Any change in zones
        if ShadowBudgetZone.zone(for: oldValue) != ShadowBudgetZone.zone(for: newValue) {
            HapticsManager.shared.playSelectionFeedback()
        }
    }
    
    // CRITICAL FIX: Batch update to prevent infinite publish loops
    private func commitAllocation() {
        // Warning for entering red zone (skip if user already confirmed)
        if currentZone == .blackOps && shadowState.currentZone != .blackOps && !userConfirmedBlackOps {
            showingWarning = true
            return
        }

        // Reset confirmation flag after use
        userConfirmedBlackOps = false
        
        // Create a copy of the state, modify it, then assign back
        // This prevents intermediate publishes that can trigger infinite loops
        var updatedState = gameState.currentPlayer == .incumbent ? 
            shadowManager.incumbentShadowState : 
            shadowManager.challengerShadowState
        
        updatedState.allocationPercentage = sliderValue
        
        // Single atomic update
        if gameState.currentPlayer == .incumbent {
            shadowManager.incumbentShadowState = updatedState
        } else {
            shadowManager.challengerShadowState = updatedState
        }
        
        HapticsManager.shared.playSuccessFeedback()
    }
    
    // CRITICAL FIX: Batch update for shell company setup
    private func setupShellCompany() {
        var shell = gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentShellCompany :
            shadowManager.challengerShellCompany
        
        let setupCost = shell.setupCost
        
        // Deduct funds and activate shell
        shell.isActive = true
        
        if gameState.currentPlayer == .incumbent {
            gameState.incumbent.campaignFunds -= setupCost
            shadowManager.incumbentShellCompany = shell
        } else {
            gameState.challenger.campaignFunds -= setupCost
            shadowManager.challengerShellCompany = shell
        }
        
        HapticsManager.shared.playSuccessFeedback()
    }
    
    private func calculateDetectionRisk() -> String {
        let baseDetection = sliderValue / 100.0
        let shell = gameState.currentPlayer == .incumbent ?
            shadowManager.incumbentShellCompany :
            shadowManager.challengerShellCompany
        
        let reduction = shell.isActive ? shell.detectionReduction : 0.0
        let finalRisk = baseDetection * (1.0 - reduction) * 100
        
        return String(format: "%.1f%% per turn", finalRisk)
    }
}

// MARK: - Operation Row

struct OperationRow: View {
    let operation: ShadowOperationType
    let canExecute: Bool
    let hasFunds: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(operation.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(canExecute && hasFunds ? .primary : .secondary)
                
                Text(operation.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(operation.baseCost.asCurrency())
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("Requires \(Int(operation.minimumAllocation))% allocation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: canExecute && hasFunds ? "chevron.right" : "lock.fill")
                .foregroundStyle(canExecute && hasFunds ? .blue : .gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Scandal Card

struct ScandalCard: View {
    let scandal: ShadowBudgetScandal
    let shadowManager: ShadowBudgetManager
    let gameState: GameState
    
    @State private var showingDenial = false
    
    var severityColor: Color {
        switch scandal.severity {
        case .minor: return .orange
        case .major: return .red
        case .campaignEnding: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                Text(scandal.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(scandal.severity.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor)
                    .clipShape(Capsule())
            }
            
            Text(scandal.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("Polling: \(scandal.pollingImpact, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Text("•")
                
                Text("Funding freeze: \(scandal.fundingFreeze) turns")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            Button {
                showingDenial = true
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill")
                    Text("Attempt to Deny")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Deny Allegations?", isPresented: $showingDenial) {
            Button("Cancel", role: .cancel) { }
            Button("Deny") {
                let success = shadowManager.attemptDenial(
                    scandalId: scandal.id,
                    for: gameState.currentPlayer
                )
                if success {
                    HapticsManager.shared.playSuccessFeedback()
                } else {
                    HapticsManager.shared.playErrorFeedback()
                }
            }
        } message: {
            let integrity = gameState.currentPlayer == .incumbent ?
                shadowManager.incumbentIntegrity :
                shadowManager.challengerIntegrity
            
            let successChance = Int((0.30 + (integrity.reputation / 100.0 * 0.4)) * 100)
            
            Text("Attempt to deny the allegations? Your integrity score gives you a \(successChance)% chance of success. Failure will make the scandal worse.")
        }
    }
}

// MARK: - Operation Detail View

struct OperationDetailView: View {
    let operation: ShadowOperationType
    let shadowManager: ShadowBudgetManager
    let gameState: GameState
    @Binding var isPresented: Bool

    private var panelBackgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.88)
        #endif
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                
                Text(operation.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(operation.description)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Cost:")
                        Spacer()
                        Text(operation.baseCost.asCurrency())
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Detection Risk:")
                        Spacer()
                        Text("\(Int(operation.baseDetectionRisk * 100))%")
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(panelBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    executeOperation()
                } label: {
                    Text("Execute Operation")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .padding()
            .navigationTitle("Shadow Operation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func executeOperation() {
        let success = shadowManager.executeOperation(
            operation,
            for: gameState.currentPlayer
        )
        
        if success {
            HapticsManager.shared.playSuccessFeedback()
            isPresented = false
        } else {
            HapticsManager.shared.playErrorFeedback()
        }
    }
}

#Preview {
    NavigationStack {
        ShadowBudgetView(
            gameState: GameState(),
            shadowManager: ShadowBudgetManager(gameState: GameState())
        )
    }
}
