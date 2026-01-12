//
//  HapticsManager.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Manages haptic feedback throughout the app
class HapticsManager {
    static let shared = HapticsManager()
    
    #if canImport(UIKit)
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    #endif
    
    private init() {
        #if canImport(UIKit)
        // Prepare generators for reduced latency
        impact.prepare()
        notification.prepare()
        selection.prepare()
        #endif
    }
    
    /// Play haptic when user takes an action
    func playActionFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        impact.impactOccurred()
        #endif
    }
    
    /// Play haptic for successful action
    func playSuccessFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        notification.notificationOccurred(.success)
        #endif
    }
    
    /// Play haptic for warning/negative event
    func playWarningFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        notification.notificationOccurred(.warning)
        #endif
    }
    
    /// Play haptic for errors
    func playErrorFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        notification.notificationOccurred(.error)
        #endif
    }
    
    /// Play light haptic for selections
    func playSelectionFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        selection.selectionChanged()
        #endif
    }
    
    /// Play haptic for turn ending
    func playTurnEndFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
    
    /// Play dramatic haptic for game end
    func playGameEndFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        
        #if canImport(UIKit)
        // Play a sequence of haptics
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            heavy.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notification.notificationOccurred(.success)
        }
        #endif
    }
}
