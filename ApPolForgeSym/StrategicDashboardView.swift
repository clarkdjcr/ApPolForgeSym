//
//  StrategicDashboardView.swift
//  ApPolForgeSym
//
//  Strategic recommendations and campaign analytics dashboard
//

import SwiftUI

struct StrategicDashboardView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var advisor: StrategicAdvisor
    
    init(gameState: GameState) {
        self.gameState = gameState
        self._advisor = StateObject(wrappedValue: StrategicAdvisor(gameState: gameState))
    }
    
    var currentPlayer: Player {
        gameState.currentPlayer == .incumbent ? gameState.incumbent : gameState.challenger
    }
    
    var body: some View {
        List {
            // Campaign Analytics Section
            Section("Campaign Analytics") {
                AnalyticsSummaryView(
                    analytics: advisor.calculateAnalytics(for: gameState.currentPlayer),
                    gameState: gameState
                )
            }
            
            // AI Recommendations Section
            Section("Strategic Recommendations") {
                let recommendations = advisor.generateRecommendations(for: gameState.currentPlayer)
                
                if recommendations.isEmpty {
                    ContentUnavailableView(
                        "No Recommendations",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Your campaign is executing well. Keep up the momentum!")
                    )
                } else {
                    ForEach(recommendations) { recommendation in
                        RecommendationCard(
                            recommendation: recommendation,
                            gameState: gameState,
                            advisor: advisor
                        )
                    }
                }
            }
            
            // State Infrastructure Section
            Section("State-by-State Infrastructure") {
                ForEach(gameState.states) { state in
                    StateInfrastructureRow(
                        state: state,
                        data: advisor.incumbentInfrastructure[state.id] ?? 
                              advisor.challengerInfrastructure[state.id]!,
                        playerType: gameState.currentPlayer
                    )
                }
            }
        }
        .navigationTitle("Strategy Center")
        .onAppear {
            advisor.updateStaffingPredictions(for: gameState.currentPlayer)
        }
    }
}

// MARK: - Analytics Summary

struct AnalyticsSummaryView: View {
    let analytics: CampaignAnalytics
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Financial Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Financial Outlook")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Funds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(analytics.currentFunds.asCurrency())
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Projected at Election")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(analytics.projectedEndgameFunds.asCurrency())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(analytics.projectedEndgameFunds >= 0 ? Color.primary : Color.red)
                    }
                }
                
                if let alert = analytics.fundingAlert {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(alert)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Divider()
            
            // Electoral Math
            VStack(alignment: .leading, spacing: 8) {
                Text("Electoral Vote Breakdown")
                    .font(.headline)
                
                ElectoralBreakdownBar(analytics: analytics)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        LegendItem(color: .green, label: "Secure", value: analytics.secureElectoralVotes)
                        LegendItem(color: .blue, label: "Likely", value: analytics.likelyElectoralVotes)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        LegendItem(color: .orange, label: "Leaning", value: analytics.leaningElectoralVotes)
                        LegendItem(color: .gray, label: "Tossup", value: analytics.tossupElectoralVotes)
                    }
                }
                .font(.caption)
                
                let total = analytics.secureElectoralVotes + analytics.likelyElectoralVotes + 
                           analytics.leaningElectoralVotes
                let needed = 270 - total
                
                if needed > 0 {
                    Text("Need \(needed) more electoral votes from tossup/opponent states")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("On track for 270+ electoral votes")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 4)
                }
            }
            
            Divider()
            
            // Paths to Victory
            if !analytics.pathsTo270.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paths to Victory")
                        .font(.headline)
                    
                    if analytics.pathsTo270.first!.isEmpty {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("Already have 270+ electoral votes")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text("Win these states to reach 270:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(analytics.pathsTo270.prefix(1), id: \.self) { path in
                            PathToVictoryView(stateIds: path, gameState: gameState)
                        }
                    }
                }
            }
        }
    }
}

struct ElectoralBreakdownBar: View {
    let analytics: CampaignAnalytics
    
    var total: Int {
        analytics.secureElectoralVotes + analytics.likelyElectoralVotes + 
        analytics.leaningElectoralVotes + analytics.tossupElectoralVotes
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * CGFloat(analytics.secureElectoralVotes) / CGFloat(total))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(analytics.likelyElectoralVotes) / CGFloat(total))
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: geometry.size.width * CGFloat(analytics.leaningElectoralVotes) / CGFloat(total))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: geometry.size.width * CGFloat(analytics.tossupElectoralVotes) / CGFloat(total))
            }
        }
        .frame(height: 30)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            Text("270 to win")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
            Text("(\(value))")
                .foregroundStyle(.secondary)
        }
    }
}

struct PathToVictoryView: View {
    let stateIds: [UUID]
    let gameState: GameState
    
    var states: [ElectoralState] {
        stateIds.compactMap { id in
            gameState.states.first { $0.id == id }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(states) { state in
                HStack {
                    Text("•")
                    Text(state.name)
                    Spacer()
                    Text("\(state.electoralVotes) EV")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: StrategicRecommendation
    let gameState: GameState
    let advisor: StrategicAdvisor
    
    @State private var isExpanded = false
    
    var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
    
    var priorityIcon: String {
        switch recommendation.priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "info.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: priorityIcon)
                    .foregroundStyle(priorityColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.headline)
                    
                    Text(recommendation.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor)
                    .clipShape(Capsule())
            }
            
            // Description
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Target states
                    if !recommendation.targetStates.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target States:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            let states = recommendation.targetStates.compactMap { id in
                                gameState.states.first { $0.id == id }
                            }
                            
                            ForEach(states) { state in
                                HStack {
                                    Text("• \(state.name)")
                                    Spacer()
                                    Text("\(state.electoralVotes) EV")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Suggested actions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Actions:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        ForEach(recommendation.suggestedActions, id: \.self) { action in
                            HStack {
                                Image(systemName: action.systemImage)
                                Text(action.name)
                                Spacer()
                                Text(action.cost.asCurrency())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Expected impact and reasoning
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected Impact:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(recommendation.expectedImpact)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reasoning:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(recommendation.reasoning)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Cost
                    HStack {
                        Text("Estimated Cost:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(recommendation.estimatedCost.asCurrency())
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Expand/collapse button
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - State Infrastructure Row

struct StateInfrastructureRow: View {
    let state: ElectoralState
    let data: StateCampaignData
    let playerType: PlayerType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                
                Text("\(Int(data.infrastructureScore))%")
                    .font(.headline)
                    .foregroundStyle(data.infrastructureScore >= 70 ? .green : 
                                   data.infrastructureScore >= 40 ? .orange : .red)
            }
            
            // Staff info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Staff Positions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(data.currentStaffPositions) / \(data.recommendedStaffPositions)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Volunteers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(data.currentVolunteers) / \(data.recommendedVolunteers)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            // Infrastructure progress bars
            VStack(spacing: 4) {
                ProgressBar(
                    label: "Staffing",
                    current: data.currentStaffPositions,
                    target: data.recommendedStaffPositions
                )
                
                ProgressBar(
                    label: "Volunteers",
                    current: data.currentVolunteers,
                    target: data.recommendedVolunteers
                )
            }
            
            if data.totalSpent > 0 {
                Text("Spent: \(data.totalSpent.asCurrency())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var color: Color {
        if percentage >= 0.8 { return .green }
        if percentage >= 0.5 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.caption2)
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        StrategicDashboardView(gameState: GameState())
    }
}
