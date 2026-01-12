//
//  AppSettings.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI
import Combine

/// AI difficulty levels
enum AIDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    
    var description: String {
        switch self {
        case .easy:
            return "Makes basic decisions, sometimes inefficient"
        case .medium:
            return "Balanced strategy, good for beginners"
        case .hard:
            return "Smart decisions, competitive opponent"
        case .expert:
            return "Ruthless efficiency, maximum challenge"
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "tortoise.fill"
        case .medium: return "figure.walk"
        case .hard: return "hare.fill"
        case .expert: return "brain.fill"
        }
    }
}

/// User preferences for the app
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("autoSaveEnabled") var autoSaveEnabled: Bool = true
    @AppStorage("showTutorial") var showTutorial: Bool = true
    @AppStorage("aiSpeed") var aiSpeed: Double = 1.5
    @AppStorage("confirmActions") var confirmActions: Bool = false
    @AppStorage("aiDifficulty") private var aiDifficultyRawValue: String = AIDifficulty.medium.rawValue
    
    // External AI Agent settings
    @AppStorage("externalAIEnabled") var externalAIEnabled: Bool = false
    @AppStorage("externalAIEndpoint") var externalAIEndpoint: String = "https://api.openai.com/v1/chat/completions"
    
    var aiDifficulty: AIDifficulty {
        get {
            AIDifficulty(rawValue: aiDifficultyRawValue) ?? .medium
        }
        set {
            aiDifficultyRawValue = newValue.rawValue
        }
    }
    
    private init() {
        // Private initializer for singleton
    }
}

