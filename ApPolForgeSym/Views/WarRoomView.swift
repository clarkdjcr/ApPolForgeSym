import SwiftUI
import Charts

struct WarRoomView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0a0a0a").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Main Stats Row
                        statsGrid
                        
                        // Electoral College Progress
                        electoralProgressBar
                        
                        // Charts and Map Section
                        HStack(alignment: .top, spacing: 20) {
                            // Momentum Chart
                            momentumCard
                            
                            // Battleground Highlights
                            battlegroundCard
                        }
                        .padding(.horizontal)
                        
                        // Recent News Ticker
                        newsTicker
                    }
                    .padding(.vertical)
                }
            }
            
            // AI Advisor Floating Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Aura9AvatarView()
                        .padding()
                        .onTapGesture {
                            // Show AI Advisor Sheet
                        }
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ELECTION WAR ROOM")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                Text("CAMPAIGN '24 STATUS: ACTIVE")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
            }
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("TURN \(gameState.currentTurn) OF \(gameState.maxTurns)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                Text("TIME TO ELECTION: \((gameState.maxTurns - gameState.currentTurn) + 1) WEEKS")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
    
    private var statsGrid: some View {
        HStack(spacing: 15) {
            StatCard(title: "TOTAL FUNDS", value: gameState.incumbent.campaignFunds.asCurrency(), color: .blue)
            StatCard(title: "MOMENTUM", value: "\(gameState.incumbent.momentum)%", color: .cyan)
            StatCard(title: "POLLING AVG", value: String(format: "%.1f%%", gameState.incumbent.nationalPolling), color: .purple)
        }
        .padding(.horizontal)
    }
    
    private var electoralProgressBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            let votes = gameState.calculateElectoralVotes()
            HStack {
                Text("ELECTORAL COLLEGE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(votes.incumbent) vs \(votes.challenger)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(Double(votes.incumbent) / 538.0))
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geo.size.width * CGFloat(Double(538 - votes.incumbent - votes.challenger) / 538.0))
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(Double(votes.challenger) / 538.0))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
            .overlay(
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 20)
                    .offset(x: 0) // Should be at 270 center
            )
            
            HStack {
                Text("270 TO WIN")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var momentumCard: some View {
        VStack(alignment: .leading) {
            Text("NATIONAL MOMENTUM")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            Chart {
                ForEach(gameState.electoralVoteHistory) { snapshot in
                    LineMark(
                        x: .value("Turn", snapshot.turn),
                        y: .value("EV", snapshot.incumbentEV)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Turn", snapshot.turn),
                        y: .value("EV", snapshot.incumbentEV)
                    )
                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
            .frame(height: 150)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var battlegroundCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KEY BATTLEGROUNDS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            let battlegrounds = gameState.states.filter { $0.isBattleground }.prefix(4)
            
            ForEach(battlegrounds) { state in
                HStack {
                    Text(state.abbreviation)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 30)
                    
                    let actualInc = state.demographics.calculateWeightedSupport(baseSupport: state.incumbentSupport)
                    let actualCha = state.demographics.calculateWeightedSupport(baseSupport: state.challengerSupport)
                    let diff = actualInc - actualCha
                    
                    Text(String(format: "%+.1f", diff))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(diff >= 0 ? .blue : .red)
                    
                    Spacer()
                    
                    Capsule()
                        .fill(diff >= 0 ? Color.blue.opacity(0.3) : Color.red.opacity(0.3))
                        .frame(width: 60, height: 4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .frame(width: 180)
    }
    
    private var newsTicker: some View {
        VStack(alignment: .leading) {
            HStack {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("LIVE INTEL FEED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    if gameState.recentEvents.isEmpty {
                        Text("Monitoring national discourse...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    } else {
                        ForEach(gameState.recentEvents) { event in
                            HStack {
                                Text(event.title)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text(event.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    WarRoomView()
        .environmentObject(GameState())
}

