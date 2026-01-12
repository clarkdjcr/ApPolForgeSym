//
//  HapticsManager.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

#if canImport(UIKit)
import UIKit

class HapticsManager {
    static let shared = HapticsManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Haptic Feedback Methods
    
    func playSelectionFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    func playActionFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    func playSuccessFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func playErrorFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    func playWarningFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    func playTurnEndFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        impactLight.impactOccurred()
        impactLight.prepare()
    }
    
    func playGameEndFeedback() {
        guard AppSettings.shared.hapticsEnabled else { return }
        // Play a sequence of haptics for game end
        impactHeavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.impactMedium.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.notificationGenerator.notificationOccurred(.success)
            self?.impactHeavy.prepare()
            self?.notificationGenerator.prepare()
        }
    }
}

#else
// macOS fallback - no haptics
class HapticsManager {
    static let shared = HapticsManager()
    private init() {}
    
    func playSelectionFeedback() {}
    func playActionFeedback() {}
    func playSuccessFeedback() {}
    func playErrorFeedback() {}
    func playWarningFeedback() {}
    func playTurnEndFeedback() {}
    func playGameEndFeedback() {}
}
#endif
