//
//  AccessibilityExtensions.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility Labels and Hints

extension View {
    /// Adds comprehensive accessibility support for campaign actions
    func campaignActionAccessibility(
        action: CampaignActionType,
        canAfford: Bool
    ) -> some View {
        self
            .accessibilityLabel("\(action.name), costs \(action.cost / 1_000_000, specifier: "%.1f") million dollars")
            .accessibilityHint(canAfford ? action.description : "Insufficient funds")
            .accessibilityAddTraits(canAfford ? [] : .isButton)
    }
    
    /// Adds accessibility support for state information
    func stateAccessibility(state: ElectoralState) -> some View {
        let incumbentLead = state.incumbentSupport - state.challengerSupport
        let leadDescription: String
        
        if abs(incumbentLead) < 3 {
            leadDescription = "Toss-up"
        } else if incumbentLead > 0 {
            leadDescription = "Incumbent leads by \(incumbentLead, specifier: "%.1f") points"
        } else {
            leadDescription = "Challenger leads by \(abs(incumbentLead), specifier: "%.1f") points"
        }
        
        return self
            .accessibilityLabel("\(state.name), \(state.electoralVotes) electoral votes")
            .accessibilityValue(leadDescription)
            .accessibilityHint(state.isBattleground ? "Battleground state" : "")
    }
    
    /// Adds accessibility support for electoral vote displays
    func electoralVoteAccessibility(
        incumbentVotes: Int,
        challengerVotes: Int,
        incumbentName: String,
        challengerName: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Electoral vote count")
            .accessibilityValue("\(incumbentName) has \(incumbentVotes) votes, \(challengerName) has \(challengerVotes) votes. 270 needed to win.")
    }
}

// MARK: - Accessibility Helpers for Game Elements

extension Player {
    var accessibilityDescription: String {
        """
        \(name) of the \(partyName). \
        \(type == .incumbent ? "Incumbent" : "Challenger"). \
        Campaign funds: \(campaignFunds.asCurrency()). \
        Momentum: \(momentum.withSign()). \
        National polling: \(nationalPolling.asPercent())
        """
    }
}

extension GameEvent {
    var accessibilityDescription: String {
        let affectedText = affectedPlayer != nil 
            ? "Affects \(affectedPlayer == .incumbent ? "incumbent" : "challenger")" 
            : "Affects both candidates"
        
        let impactText = impactMagnitude >= 0 
            ? "Positive impact of \(impactMagnitude) points" 
            : "Negative impact of \(abs(impactMagnitude)) points"
        
        return """
        \(title). \
        \(description). \
        \(affectedText). \
        \(impactText). \
        Occurred in week \(turn)
        """
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Ensures text scales appropriately with Dynamic Type
    static func scaledTitle() -> Font {
        .system(.title, design: .default, weight: .bold)
    }
    
    static func scaledHeadline() -> Font {
        .system(.headline, design: .default)
    }
    
    static func scaledBody() -> Font {
        .system(.body, design: .default)
    }
    
    static func scaledCaption() -> Font {
        .system(.caption, design: .default)
    }
}

// MARK: - VoiceOver Announcements

/// Helper to make VoiceOver announcements
struct AccessibilityAnnouncement {
    static func announce(_ message: String, priority: AccessibilityNotificationPriority = .medium) {
        #if canImport(UIKit)
        // Use .announcement for general notifications
        UIAccessibility.post(notification: .announcement, argument: message)
        #elseif canImport(AppKit)
        NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium])
        #endif
    }
    
    static func announceScreenChange(_ message: String) {
        #if canImport(UIKit)
        // Use when major screen changes occur
        UIAccessibility.post(notification: .screenChanged, argument: message)
        #elseif canImport(AppKit)
        NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high])
        #endif
    }
    
    static func announceLayoutChange(_ message: String) {
        #if canImport(UIKit)
        // Use when layout significantly changes
        UIAccessibility.post(notification: .layoutChanged, argument: message)
        #elseif canImport(AppKit)
        NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium])
        #endif
    }
}

enum AccessibilityNotificationPriority {
    case low
    case medium
    case high
}
