//
//  AppSettings.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI
import Combine

/// User preferences for the app
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("autoSaveEnabled") var autoSaveEnabled: Bool = true
    @AppStorage("showTutorial") var showTutorial: Bool = true
    @AppStorage("aiSpeed") var aiSpeed: Double = 1.5
    @AppStorage("confirmActions") var confirmActions: Bool = false
    
    private init() {
        // Private initializer for singleton
    }
}

