//
//  TutorialView.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let pages: [TutorialPage] = [
        TutorialPage(
            icon: "flag.fill",
            title: "Welcome to Campaign Manager",
            description: "Manage a presidential campaign over 20 intense weeks. Your goal: secure 270 electoral votes to win the election.",
            color: .blue
        ),
        TutorialPage(
            icon: "dollarsign.circle.fill",
            title: "Manage Resources",
            description: "Track your campaign funds, momentum, and national polling. Every action costs money, so budget wisely!",
            color: .green
        ),
        TutorialPage(
            icon: "map.fill",
            title: "Win States",
            description: "Focus on battleground states where the race is close. Each state has electoral votes — win states to reach 270!",
            color: .purple
        ),
        TutorialPage(
            icon: "megaphone.fill",
            title: "Take Actions",
            description: "Choose from 7 campaign actions each turn: rallies, ads, town halls, and more. Each has different costs and effects.",
            color: .orange
        ),
        TutorialPage(
            icon: "sparkles",
            title: "Handle Events",
            description: "Random events occur throughout the campaign — scandals, endorsements, crises. Adapt your strategy to changing circumstances!",
            color: .red
        ),
        TutorialPage(
            icon: "trophy.fill",
            title: "Victory Awaits",
            description: "The player with 270+ electoral votes on Election Day wins. Good luck, and may the best campaign win!",
            color: .yellow
        )
    ]
    
    var body: some View {
        VStack {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top)
            
            // Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    TutorialPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .padding(.top, 60)
            
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct TutorialPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Quick Tips View (In-Game Help)

struct QuickTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Game Basics") {
                    TipRow(
                        icon: "flag.fill",
                        title: "Goal",
                        description: "Secure 270 electoral votes by winning states"
                    )
                    TipRow(
                        icon: "calendar",
                        title: "Turns",
                        description: "You have 20 weeks (turns) to win the election"
                    )
                    TipRow(
                        icon: "person.2.fill",
                        title: "Players",
                        description: "Alternate turns with the AI opponent"
                    )
                }
                
                Section("Strategy Tips") {
                    TipRow(
                        icon: "target",
                        title: "Focus on Battlegrounds",
                        description: "States within 10 points are battlegrounds — these decide elections"
                    )
                    TipRow(
                        icon: "dollarsign.circle",
                        title: "Budget Carefully",
                        description: "Running out of money limits your options. Use fundraisers strategically"
                    )
                    TipRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Watch Momentum",
                        description: "Positive momentum helps all your actions perform better"
                    )
                    TipRow(
                        icon: "clock.fill",
                        title: "Timing Matters",
                        description: "Save expensive actions (ads, opposition research) for crucial moments"
                    )
                }
                
                Section("Campaign Actions") {
                    ForEach(CampaignActionType.allCases, id: \.self) { action in
                        TipRow(
                            icon: action.systemImage,
                            title: action.name,
                            description: action.description
                        )
                    }
                }
                
                Section("Understanding the Map") {
                    TipRow(
                        icon: "circle.fill",
                        title: "State Colors",
                        description: "Blue = Incumbent leads, Red = Challenger leads, Purple = Toss-up"
                    )
                    TipRow(
                        icon: "chart.bar.fill",
                        title: "Support Bars",
                        description: "Show the percentage of support each candidate has in a state"
                    )
                    TipRow(
                        icon: "number",
                        title: "Electoral Votes",
                        description: "Larger states have more electoral votes and are more valuable"
                    )
                }
            }
            .navigationTitle("Tips & Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Tutorial") {
    TutorialView()
}

#Preview("Quick Tips") {
    QuickTipsView()
}
