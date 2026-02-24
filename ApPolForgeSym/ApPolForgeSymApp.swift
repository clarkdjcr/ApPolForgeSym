//
//  ApPolForgeSymApp.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
import SwiftUI
import FirebaseCore

@main
struct ApPolForgeSymApp: App {

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }

        // Register bi-weekly background refresh task.
        // Must be called before the first scene is presented.
        BiweeklyRefreshManager.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
