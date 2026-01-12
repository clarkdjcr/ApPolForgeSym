//
//  SecureAPIKeyManager.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/13/26.
//

import Foundation
import Security
import Combine

/// Manages secure storage and cleanup of external AI API keys
@MainActor
class SecureAPIKeyManager: ObservableObject {
    static let shared = SecureAPIKeyManager()
    
    @Published var isAPIKeyConfigured: Bool = false
    @Published var lastError: String?
    
    private let serviceName = "com.appolforgesym.aiagent"
    private let accountName = "external-ai-api-key"
    
    private init() {
        // Check if key exists on init
        isAPIKeyConfigured = hasAPIKey()
        
        // Register for app lifecycle notifications to clean up on termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSNotification.Name("NSApplicationWillTerminateNotification"),
            object: nil
        )
    }
    
    // MARK: - Public API
    
    /// Securely stores the API key in the Keychain
    func saveAPIKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw APIKeyError.emptyKey
        }
        
        // Remove any existing key first
        try? deleteAPIKey()
        
        guard let data = key.data(using: .utf8) else {
            throw APIKeyError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw APIKeyError.keychainError(status)
        }
        
        isAPIKeyConfigured = true
        lastError = nil
    }
    
    /// Retrieves the API key from the Keychain
    func retrieveAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw APIKeyError.keyNotFound
            }
            throw APIKeyError.keychainError(status)
        }
        
        guard let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw APIKeyError.decodingFailed
        }
        
        return key
    }
    
    /// Deletes the API key from the Keychain
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Consider success if item was deleted or didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyError.keychainError(status)
        }
        
        isAPIKeyConfigured = false
        lastError = nil
    }
    
    /// Checks if an API key is stored
    func hasAPIKey() -> Bool {
        do {
            _ = try retrieveAPIKey()
            return true
        } catch {
            return false
        }
    }
    
    /// Validates that the stored key is accessible and non-empty
    func validateAPIKey() -> Bool {
        do {
            let key = try retrieveAPIKey()
            return !key.isEmpty && key.count > 10 // Basic validation
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Session Cleanup
    
    /// Called when app terminates to ensure API key is deleted
    @objc private func appWillTerminate() {
        cleanupSession()
    }
    
    /// Manually cleanup session (delete API key)
    func cleanupSession() {
        do {
            try deleteAPIKey()
            print("✅ API key securely deleted from session")
        } catch {
            print("⚠️ Failed to delete API key: \(error.localizedDescription)")
        }
    }
    
    // Note: deinit cannot call @MainActor isolated methods
    // Cleanup is handled by appWillTerminate notification
}

// MARK: - Error Types

enum APIKeyError: LocalizedError {
    case emptyKey
    case keyNotFound
    case encodingFailed
    case decodingFailed
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "API key cannot be empty"
        case .keyNotFound:
            return "No API key found. Please enter your key in settings."
        case .encodingFailed:
            return "Failed to encode API key"
        case .decodingFailed:
            return "Failed to decode API key"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - External AI Agent Integration

/// Protocol for external AI agents
protocol ExternalAIAgent {
    func getStrategicRecommendation(
        gameState: GameState,
        playerType: PlayerType
    ) async throws -> AIAgentResponse
}

/// Response from external AI agent
struct AIAgentResponse: Codable {
    let recommendations: [String]
    let confidence: Double
    let reasoning: String?
}

/// Example implementation of an external AI agent (OpenAI, Anthropic, etc.)
@MainActor
class ExternalAIAgentService: ObservableObject {
    static let shared = ExternalAIAgentService()
    
    @Published var isEnabled: Bool = false
    @Published var lastResponse: AIAgentResponse?
    @Published var isLoading: Bool = false
    
    private let keyManager = SecureAPIKeyManager.shared
    private let session = URLSession.shared
    
    private init() {
        isEnabled = keyManager.isAPIKeyConfigured
    }
    
    /// Example method to call external AI API
    func getRecommendations(
        for gameState: GameState,
        playerType: PlayerType,
        apiEndpoint: URL
    ) async throws -> AIAgentResponse {
        guard keyManager.hasAPIKey() else {
            throw APIKeyError.keyNotFound
        }
        
        let apiKey = try keyManager.retrieveAPIKey()
        
        isLoading = true
        defer { isLoading = false }
        
        // Prepare request payload
        let payload = createPayload(gameState: gameState, playerType: playerType)
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        // Create request
        var request = URLRequest(url: apiEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
        
        // Parse response
        let aiResponse = try JSONDecoder().decode(AIAgentResponse.self, from: data)
        lastResponse = aiResponse
        
        return aiResponse
    }
    
    private func createPayload(gameState: GameState, playerType: PlayerType) -> [String: Any] {
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let votes = gameState.calculateElectoralVotes()
        
        return [
            "game_state": [
                "current_turn": gameState.currentTurn,
                "max_turns": gameState.maxTurns,
                "player_type": playerType.rawValue,
                "campaign_funds": player.campaignFunds,
                "electoral_votes": playerType == .incumbent ? votes.incumbent : votes.challenger,
                "opponent_votes": playerType == .incumbent ? votes.challenger : votes.incumbent
            ],
            "states": gameState.states.map { state in
                [
                    "name": state.name,
                    "electoral_votes": state.electoralVotes,
                    "incumbent_support": state.incumbentSupport,
                    "challenger_support": state.challengerSupport,
                    "is_battleground": state.isBattleground
                ]
            },
            "request": "strategic_recommendations"
        ]
    }
}
