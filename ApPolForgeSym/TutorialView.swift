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

// MARK: - Quick Tips View (Comprehensive Help Guide)

struct QuickTipsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Game Overview
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Campaign Manager 2026 is a turn-based strategy game where you run a presidential campaign. Compete against an AI opponent to win the election by securing 270 or more electoral votes.")
                            .font(.subheadline)

                        Text("If neither candidate reaches 270 electoral votes, the candidate with the most electoral votes wins.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Game Overview", systemImage: "flag.fill")
                }

                // MARK: - How to Win
                Section {
                    TipRow(
                        icon: "trophy.fill",
                        title: "Win Condition",
                        description: "Secure 270+ electoral votes by winning individual states. Each state awards all its electoral votes to the candidate with the most support."
                    )

                    TipRow(
                        icon: "calendar",
                        title: "20 Weeks",
                        description: "You have 20 turns (weeks) until Election Day. The incumbent always goes first, then players alternate turns."
                    )

                    TipRow(
                        icon: "person.2.fill",
                        title: "Choose Your Role",
                        description: "Play as the Incumbent (starts with more funds and slight momentum advantage) or the Challenger (starts as underdog but can build momentum)."
                    )
                } header: {
                    Label("How to Win", systemImage: "star.fill")
                }

                // MARK: - Your Resources
                Section {
                    TipRow(
                        icon: "dollarsign.circle.fill",
                        title: "Campaign Funds",
                        description: "Money powers your campaign. Every action costs funds. Incumbent starts with $220M, Challenger with $150M. Run out of money and your options become severely limited."
                    )

                    TipRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Momentum (-100 to +100)",
                        description: "Reflects campaign energy. Positive momentum boosts all your actions. Negative momentum weakens them. Winning debates, successful rallies, and positive events build momentum."
                    )

                    TipRow(
                        icon: "percent",
                        title: "National Polling",
                        description: "Your overall national support percentage. Affects how undecided voters in states lean. Higher polling makes it easier to win battleground states."
                    )
                } header: {
                    Label("Your Resources", systemImage: "cube.box.fill")
                }

                // MARK: - Understanding States
                Section {
                    TipRow(
                        icon: "map.fill",
                        title: "14 States in Play",
                        description: "The game features 14 key states: 8 battleground states (FL, PA, MI, WI, AZ, NC, GA, NV), 3 blue-leaning states (CA, NY, IL), and 3 red-leaning states (TX, OH, IN)."
                    )

                    TipRow(
                        icon: "target",
                        title: "Battleground States",
                        description: "States where the margin is within 10 points. These are where elections are won or lost. Focus your resources here."
                    )

                    TipRow(
                        icon: "circle.lefthalf.filled",
                        title: "State Colors",
                        description: "Blue = Incumbent leads. Red = Challenger leads. Purple = Toss-up (within 5 points). The darker the color, the stronger the lead."
                    )

                    TipRow(
                        icon: "number",
                        title: "Electoral Votes by State",
                        description: "CA(55), TX(38), FL(29), NY(29), PA(20), IL(20), OH(18), GA(16), MI(16), NC(15), AZ(11), IN(11), WI(10), NV(6). Total: 294 votes in play."
                    )
                } header: {
                    Label("Understanding States", systemImage: "map")
                }

                // MARK: - Campaign Actions
                Section {
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
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .clipShape(Capsule())
                            }

                            Text(action.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(actionDetailedEffect(action))
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Campaign Actions", systemImage: "hand.point.up.fill")
                } footer: {
                    Text("Each turn, choose one action. Most actions target a specific state, except Fundraiser and Debate Prep which have national effects.")
                }

                // MARK: - Random Events
                Section {
                    TipRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Scandal",
                        description: "Negative event that damages one candidate's support across all states and hurts momentum."
                    )

                    TipRow(
                        icon: "chart.bar.fill",
                        title: "Economic News",
                        description: "Good or bad economic news affects the incumbent's standing. Good news helps, bad news hurts."
                    )

                    TipRow(
                        icon: "hand.thumbsup.fill",
                        title: "Major Endorsement",
                        description: "A celebrity, union, or influential figure endorses a candidate, boosting their support in key states."
                    )

                    TipRow(
                        icon: "bubble.left.and.exclamationmark.bubble.right.fill",
                        title: "Campaign Gaffe",
                        description: "A candidate makes an embarrassing mistake, damaging their momentum and state support."
                    )

                    TipRow(
                        icon: "exclamationmark.shield.fill",
                        title: "National Crisis",
                        description: "A major event (natural disaster, international incident) that typically benefits the incumbent who can appear presidential."
                    )

                    TipRow(
                        icon: "sparkles",
                        title: "Viral Moment",
                        description: "A campaign moment goes viral on social media, dramatically boosting one candidate's momentum and youth support."
                    )
                } header: {
                    Label("Random Events", systemImage: "dice.fill")
                } footer: {
                    Text("Events occur randomly (about 40% of turns) and can dramatically shift the race. Adapt your strategy accordingly.")
                }

                // MARK: - AI Opponent
                Section {
                    TipRow(
                        icon: "brain",
                        title: "Adaptive AI",
                        description: "The AI opponent adjusts its strategy based on the state of the race. It plays differently when winning vs. losing."
                    )

                    TipRow(
                        icon: "flame.fill",
                        title: "When Losing",
                        description: "AI becomes aggressive - targets battleground states with expensive actions, uses opposition research, takes risks."
                    )

                    TipRow(
                        icon: "shield.fill",
                        title: "When Winning",
                        description: "AI plays defensively - protects leads in key states, builds war chest, avoids risky moves."
                    )

                    TipRow(
                        icon: "slider.horizontal.3",
                        title: "Difficulty Levels",
                        description: "Easy: AI makes suboptimal choices. Medium: Balanced play. Hard: Strategic and efficient. Expert: Near-perfect decisions."
                    )
                } header: {
                    Label("AI Opponent", systemImage: "cpu")
                }

                // MARK: - Strategy Guide
                Section {
                    TipRow(
                        icon: "1.circle.fill",
                        title: "Early Game (Weeks 1-7)",
                        description: "Build your war chest with fundraisers. Establish grassroots presence in key battlegrounds. React to early events. Don't overspend."
                    )

                    TipRow(
                        icon: "2.circle.fill",
                        title: "Mid Game (Weeks 8-14)",
                        description: "Shift to offense. Use ad campaigns in battlegrounds. Prepare for debates. Counter opponent moves. Build momentum."
                    )

                    TipRow(
                        icon: "3.circle.fill",
                        title: "Late Game (Weeks 15-20)",
                        description: "All-out push. Calculate your path to 270. Go all-in on must-win states. Use remaining funds aggressively. Every turn counts."
                    )
                } header: {
                    Label("Strategy by Phase", systemImage: "clock.fill")
                }

                // MARK: - Pro Tips
                Section {
                    TipRow(
                        icon: "lightbulb.fill",
                        title: "Don't Neglect Fundraising",
                        description: "Running low on funds is devastating. Keep at least $5M in reserve for emergencies."
                    )

                    TipRow(
                        icon: "lightbulb.fill",
                        title: "Momentum Matters",
                        description: "High momentum (+50 or more) makes all your actions more effective. Low momentum weakens them."
                    )

                    TipRow(
                        icon: "lightbulb.fill",
                        title: "Watch the Map",
                        description: "Check electoral vote counts frequently. Know exactly which states you need to win."
                    )

                    TipRow(
                        icon: "lightbulb.fill",
                        title: "Counter the AI",
                        description: "If AI is investing heavily in a state, consider matching them or pivoting to uncontested states."
                    )

                    TipRow(
                        icon: "lightbulb.fill",
                        title: "Electoral Math",
                        description: "You need 270 to win. With 294 votes in play, you can lose 24 electoral votes worth of states and still win."
                    )
                } header: {
                    Label("Pro Tips", systemImage: "star.circle.fill")
                }
            }
            .navigationTitle("Game Guide")
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

    private func actionDetailedEffect(_ action: CampaignActionType) -> String {
        switch action {
        case .rally:
            return "Effect: +3-5% state support, +5-10 momentum"
        case .adCampaign:
            return "Effect: +5-8% state support, +2-5 national polling"
        case .fundraiser:
            return "Effect: Raises $3-8M depending on momentum"
        case .townHall:
            return "Effect: +2-4% state support, converts undecided voters"
        case .debate:
            return "Effect: +10-20 momentum, +1-3 national polling"
        case .grassroots:
            return "Effect: +2-3% state support, long-lasting effect"
        case .opposition:
            return "Effect: -3-6% opponent support in state, risk of backfire"
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
