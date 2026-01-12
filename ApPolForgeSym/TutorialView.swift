//
//  TutorialView.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    let pages: [TutorialPage] = [
        TutorialPage(
            icon: "target",
            title: "Win the Election",
            description: "Secure 270 or more electoral votes by winning individual states. Each state has different electoral votes and voter preferences."
        ),
        TutorialPage(
            icon: "calendar",
            title: "20 Weeks to Victory",
            description: "You have 20 turns (weeks) until Election Day. Use each turn wisely to campaign in key states and build support."
        ),
        TutorialPage(
            icon: "dollarsign.circle",
            title: "Manage Resources",
            description: "Balance your campaign funds, momentum, and national polling. Running out of money limits your options!"
        ),
        TutorialPage(
            icon: "megaphone.fill",
            title: "Campaign Actions",
            description: "Choose from 7 different campaign actions each turn: rallies, ad campaigns, fundraisers, town halls, debate prep, grassroots organizing, and opposition research."
        ),
        TutorialPage(
            icon: "map",
            title: "Target Battleground States",
            description: "Focus on competitive states where the race is close. States within 10 points are battleground states with the highest impact potential."
        ),
        TutorialPage(
            icon: "newspaper",
            title: "React to Events",
            description: "Random events can shake up the race! Scandals, economic news, endorsements, and viral moments all affect voter sentiment."
        ),
        TutorialPage(
            icon: "brain",
            title: "Face the AI",
            description: "Your AI opponent adapts its strategy based on the state of the race. When losing, it becomes aggressive. When winning, it plays defensively."
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        TutorialPageView(page: page)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                #endif
                
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Button {
                            AppSettings.shared.showTutorial = false
                            dismiss()
                        } label: {
                            Text("Get Started!")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button {
                        AppSettings.shared.showTutorial = false
                        dismiss()
                    } label: {
                        Text("Skip Tutorial")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("How to Play")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        AppSettings.shared.showTutorial = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        AppSettings.shared.showTutorial = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
            }
        }
    }
}

struct TutorialPage {
    let icon: String
    let title: String
    let description: String
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Quick Tips View

struct QuickTipsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Strategy Tips") {
                    TipRow(
                        icon: "dollarsign.circle.fill",
                        title: "Watch Your Funds",
                        description: "Running out of money limits your options. Do fundraisers regularly."
                    )
                    
                    TipRow(
                        icon: "map.fill",
                        title: "Target Battleground States",
                        description: "Focus on states within 10 points. Safe states are hard to flip."
                    )
                    
                    TipRow(
                        icon: "clock.fill",
                        title: "Time Your Actions",
                        description: "Save expensive moves like ad campaigns for critical moments."
                    )
                    
                    TipRow(
                        icon: "newspaper.fill",
                        title: "Adapt to Events",
                        description: "Respond quickly to game-changing events. Use momentum to your advantage."
                    )
                }
                
                Section("Action Guide") {
                    ForEach(CampaignActionType.allCases, id: \.self) { action in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: action.systemImage)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                Text(action.name)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text(action.cost.asCurrency())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(action.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Phases") {
                    TipRow(
                        icon: "1.circle.fill",
                        title: "Early Game (Weeks 1-7)",
                        description: "Build your war chest, establish ground game, and react to early events."
                    )
                    
                    TipRow(
                        icon: "2.circle.fill",
                        title: "Mid Game (Weeks 8-14)",
                        description: "Focus on battleground states, use ad campaigns strategically, and prepare for debates."
                    )
                    
                    TipRow(
                        icon: "3.circle.fill",
                        title: "Late Game (Weeks 15-20)",
                        description: "Go all-in on must-win states. Calculate electoral paths to 270."
                    )
                }
            }
            .navigationTitle("Quick Tips")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
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
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Toggle("Auto-Save Enabled", isOn: $settings.autoSaveEnabled)
                    Toggle("Confirm Actions", isOn: $settings.confirmActions)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AI Speed")
                            Spacer()
                            Text(String(format: "%.1f seconds", settings.aiSpeed))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $settings.aiSpeed, in: 0.5...3.0, step: 0.5)
                    }
                }
                
                Section("Feedback") {
                    Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                }
                
                Section("Help") {
                    Toggle("Show Tutorial on New Game", isOn: $settings.showTutorial)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2026.01")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

#Preview("Tutorial") {
    TutorialView()
}

#Preview("Quick Tips") {
    QuickTipsView()
}

#Preview("Settings") {
    SettingsView()
}
