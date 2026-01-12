//
//  SettingsView.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Gameplay Section
                Section {
                    Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                    Toggle("Confirm Actions", isOn: $settings.confirmActions)
                } header: {
                    Text("Gameplay")
                } footer: {
                    Text("Confirm actions will ask for confirmation before executing campaign actions.")
                }
                
                // AI Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AI Speed")
                            Spacer()
                            Text("\(settings.aiSpeed, specifier: "%.1f")s")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $settings.aiSpeed, in: 0.5...3.0, step: 0.5)
                    }
                } header: {
                    Text("AI Settings")
                } footer: {
                    Text("How long the AI takes to think before making a move.")
                }
                
                // Save Settings
                Section {
                    Toggle("Auto-Save", isOn: $settings.autoSaveEnabled)
                    
                    HStack {
                        Text("Saved Games")
                        Spacer()
                        if PersistenceManager.shared.hasSavedGame() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("None")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete All Saves", systemImage: "trash")
                    }
                } header: {
                    Text("Save Data")
                } footer: {
                    Text("Auto-save keeps your progress safe. Games are saved at the end of each turn.")
                }
                
                // Tutorial
                Section {
                    Toggle("Show Tutorial on New Game", isOn: $settings.showTutorial)
                    
                    NavigationLink {
                        TutorialView()
                    } label: {
                        Label("View Tutorial", systemImage: "book.fill")
                    }
                } header: {
                    Text("Help")
                }
                
                // About Section
                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    
                    Link(destination: URL(string: "https://apple.com")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://apple.com")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(alignment: .center, spacing: 4) {
                        Text("Campaign Manager 2026")
                            .font(.caption)
                        Text("Built with SwiftUI")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete All Saves", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllSaves()
                }
            } message: {
                Text("This will permanently delete all saved games and cannot be undone.")
            }
        }
    }
    
    private func deleteAllSaves() {
        try? PersistenceManager.shared.deleteSavedGame()
        try? PersistenceManager.shared.deleteAutoSave()
    }
}

#Preview {
    SettingsView()
}
