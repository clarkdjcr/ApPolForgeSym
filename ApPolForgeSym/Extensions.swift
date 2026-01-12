//
//  Extensions.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    static let incumbentBlue = Color.blue
    static let challengerRed = Color.red
    
    static func stateColor(for state: ElectoralState) -> Color {
        let margin = state.incumbentSupport - state.challengerSupport
        
        if abs(margin) < 3 {
            return .purple // Toss-up
        } else if margin > 0 {
            // Incumbent leading
            if margin < 10 {
                return .blue.opacity(0.6) // Lean incumbent
            } else {
                return .blue // Solid incumbent
            }
        } else {
            // Challenger leading
            if abs(margin) < 10 {
                return .red.opacity(0.6) // Lean challenger
            } else {
                return .red // Solid challenger
            }
        }
    }
}

// MARK: - Number Formatters

extension Double {
    func asCurrency() -> String {
        let millions = self / 1_000_000
        return String(format: "$%.1fM", millions)
    }
    
    func asPercent() -> String {
        return String(format: "%.1f%%", self)
    }
}

extension Int {
    func withSign() -> String {
        if self > 0 {
            return "+\(self)"
        } else {
            return "\(self)"
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            #if canImport(UIKit)
            .background(Color(uiColor: .systemBackground))
            #elseif canImport(AppKit)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(white: 1.0))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2)
    }
    
    func electoralVoteAccessibility(
        incumbentVotes: Int,
        challengerVotes: Int,
        incumbentName: String,
        challengerName: String
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel("Electoral Votes")
            .accessibilityValue("\(incumbentName) has \(incumbentVotes) votes, \(challengerName) has \(challengerVotes) votes. 270 needed to win.")
    }
    
    func stateAccessibility(state: ElectoralState) -> some View {
        let leader = state.incumbentSupport > state.challengerSupport ? "Incumbent" : "Challenger"
        let margin = abs(state.incumbentSupport - state.challengerSupport)
        let marginDescription = margin < 3 ? "toss-up" : margin < 10 ? "competitive" : "strong lead"
        
        return self.accessibilityElement(children: .combine)
            .accessibilityLabel("\(state.name), \(state.electoralVotes) electoral votes")
            .accessibilityValue("\(leader) leading by \(margin.asPercent()), \(marginDescription). Incumbent \(state.incumbentSupport.asPercent()), Challenger \(state.challengerSupport.asPercent()), Undecided \(state.undecided.asPercent())")
    }
    
    func campaignActionAccessibility(action: CampaignActionType, canAfford: Bool) -> some View {
        let affordabilityMessage = canAfford ? "Available" : "Cannot afford"
        
        return self.accessibilityElement(children: .combine)
            .accessibilityLabel("\(action.name). Costs \(action.cost.asCurrency())")
            .accessibilityHint(action.description)
            .accessibilityValue(affordabilityMessage)
    }
}
// MARK: - Accessibility Helpers

struct AccessibilityAnnouncement {
    static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
    
    static func announceScreenChange(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .screenChanged, argument: message)
        #endif
    }
}

// MARK: - Model Accessibility Descriptions

extension Player {
    var accessibilityDescription: String {
        let role = type == .incumbent ? "Incumbent" : "Challenger"
        let aiStatus = isAI ? "AI controlled" : "Human player"
        return "\(role), \(name) of the \(partyName). \(aiStatus). Campaign funds: \(campaignFunds.asCurrency()), Momentum: \(momentum.withSign()), National polling: \(nationalPolling.asPercent())"
    }
}

extension GameEvent {
    var accessibilityDescription: String {
        var description = "\(title). \(self.description)"
        
        if let affected = affectedPlayer {
            let playerName = affected == .incumbent ? "Incumbent" : "Challenger"
            let impact = impactMagnitude >= 0 ? "positive" : "negative"
            description += " This has a \(impact) impact on the \(playerName), with magnitude \(abs(impactMagnitude))."
        }
        
        description += " Occurred in week \(turn)."
        return description
    }
}

extension CampaignActionType {
    var accessibilityLabel: String {
        return "\(name). Costs \(cost.asCurrency()). \(description)"
    }
}

