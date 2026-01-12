//
//  APIKeySettingsView.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/13/26.
//

import SwiftUI

/// View for managing external AI API key
struct APIKeySettingsView: View {
    @StateObject private var keyManager = SecureAPIKeyManager.shared
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKeyInput: String = ""
    @State private var showingAPIKey: Bool = false
    @State private var showingSuccessAlert: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingDeleteConfirmation: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable External AI Agent", isOn: $settings.externalAIEnabled)
                    .disabled(!keyManager.isAPIKeyConfigured)
                
                Text("Use an external AI service (like OpenAI or Anthropic) to power strategic recommendations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("AI Agent", systemImage: "brain.fill")
            }
            
            Section {
                if keyManager.isAPIKeyConfigured {
                    // Key is configured
                    HStack {
                        Label("API Key", systemImage: "key.fill")
                        Spacer()
                        Text("Configured")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete API Key", systemImage: "trash")
                    }
                    
                } else {
                    // Need to enter key
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            if showingAPIKey {
                                TextField("Enter API Key", text: $apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    #endif
                            } else {
                                SecureField("Enter API Key", text: $apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    #endif
                            }
                            
                            Button {
                                showingAPIKey.toggle()
                            } label: {
                                Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Button {
                            saveAPIKey()
                        } label: {
                            Label("Save API Key", systemImage: "checkmark.circle.fill")
                        }
                        .disabled(apiKeyInput.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Security notice
                VStack(alignment: .leading, spacing: 8) {
                    Label("Security Notice", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text("Your API key is stored securely in the Keychain and will be automatically deleted when you quit the app.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
            } header: {
                Label("API Configuration", systemImage: "key.horizontal")
            } footer: {
                Text("Get your API key from your AI service provider (OpenAI, Anthropic, etc.).")
            }
            
            Section {
                TextField("API Endpoint", text: $settings.externalAIEndpoint)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    #if os(iOS)
                    .keyboardType(.URL)
                    #endif
                
                Button {
                    settings.externalAIEndpoint = "https://api.openai.com/v1/chat/completions"
                } label: {
                    Text("Reset to OpenAI Default")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                
            } header: {
                Label("Endpoint Configuration", systemImage: "network")
            } footer: {
                Text("Custom endpoint URL for your AI service. Default is OpenAI's chat completions endpoint.")
            }
        }
        .navigationTitle("AI Agent Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("API Key Saved", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your API key has been securely saved and will be deleted when you quit the app.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog("Delete API Key?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAPIKey()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your API key from secure storage. You'll need to enter it again to use the AI agent.")
        }
    }
    
    private func saveAPIKey() {
        do {
            try keyManager.saveAPIKey(apiKeyInput)
            apiKeyInput = ""
            showingAPIKey = false
            showingSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func deleteAPIKey() {
        do {
            try keyManager.deleteAPIKey()
            settings.externalAIEnabled = false
        } catch {
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        APIKeySettingsView()
    }
}
