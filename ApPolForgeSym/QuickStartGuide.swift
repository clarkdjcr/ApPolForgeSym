//
//  QuickStartGuide.swift
//  ApPolForgeSym
//
//  Quick reference for using the secure API key system
//  Created by Donald Clark on 1/13/26.
//

import Foundation

/*
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║         SECURE API KEY SYSTEM - QUICK START GUIDE               ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 1. ADD SETTINGS VIEW TO YOUR APP                                │
 └─────────────────────────────────────────────────────────────────┘
 
 In your settings/preferences view:
 
 NavigationLink {
     APIKeySettingsView()
 } label: {
     Label("AI Agent", systemImage: "brain.fill")
 }
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 2. CHECK IF API KEY IS CONFIGURED                               │
 └─────────────────────────────────────────────────────────────────┘
 
 let keyManager = SecureAPIKeyManager.shared
 
 if keyManager.hasAPIKey() {
     // User has configured their API key
     print("API key is ready!")
 } else {
     // Prompt user to add key in settings
     print("Please configure your API key in settings")
 }
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 3. USE THE API KEY IN YOUR CODE                                 │
 └─────────────────────────────────────────────────────────────────┘
 
 do {
     let apiKey = try keyManager.retrieveAPIKey()
     
     // Use the key in your API requests
     var request = URLRequest(url: endpoint)
     request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
     
     // Make your request...
     
 } catch APIKeyError.keyNotFound {
     print("No API key configured")
 } catch {
     print("Error retrieving key: \(error)")
 }
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 4. USE WITH EXTERNAL AI SERVICE                                 │
 └─────────────────────────────────────────────────────────────────┘
 
 let aiService = ExternalAIAgentService.shared
 
 // Check if enabled in settings
 guard AppSettings.shared.externalAIEnabled,
       aiService.isEnabled else {
     return // AI not enabled
 }
 
 // Get recommendations
 Task {
     do {
         let endpoint = URL(string: AppSettings.shared.externalAIEndpoint)!
         let response = try await aiService.getRecommendations(
             for: gameState,
             playerType: .incumbent,
             apiEndpoint: endpoint
         )
         
         // Use response.recommendations
         print(response.recommendations)
         
     } catch {
         print("AI error: \(error)")
     }
 }
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 5. MANUAL CLEANUP (OPTIONAL)                                    │
 └─────────────────────────────────────────────────────────────────┘
 
 // Cleanup happens automatically on app quit, but you can trigger manually:
 
 SecureAPIKeyManager.shared.cleanupSession()
 
 
 ┌─────────────────────────────────────────────────────────────────┐
 │ 6. OBSERVE KEY CONFIGURATION STATUS                             │
 └─────────────────────────────────────────────────────────────────┘
 
 struct MyView: View {
     @StateObject private var keyManager = SecureAPIKeyManager.shared
     
     var body: some View {
         VStack {
             if keyManager.isAPIKeyConfigured {
                 Text("✅ API Key Configured")
                 Button("Use AI Features") { /* ... */ }
             } else {
                 Text("⚠️ API Key Not Configured")
                 NavigationLink("Configure API Key") {
                     APIKeySettingsView()
                 }
             }
         }
     }
 }
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                        SECURITY FEATURES                         ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 ✅ Stored in Keychain (not files or UserDefaults)
 ✅ Device-only access (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
 ✅ Automatic deletion on app termination
 ✅ Manual deletion option
 ✅ No persistence between app sessions
 ✅ Observable for SwiftUI integration
 ✅ Comprehensive error handling
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                         ERROR HANDLING                           ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 do {
     let key = try keyManager.retrieveAPIKey()
     // Use key...
 } catch APIKeyError.emptyKey {
     // Key was empty
 } catch APIKeyError.keyNotFound {
     // No key configured - prompt user
 } catch APIKeyError.encodingFailed {
     // String encoding issue
 } catch APIKeyError.decodingFailed {
     // String decoding issue
 } catch APIKeyError.keychainError(let status) {
     // Keychain operation failed with status code
 } catch {
     // Other error
 }
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                      COMMON PATTERNS                             ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 
 // PATTERN 1: Guard for API key availability
 // ──────────────────────────────────────────
 
 guard SecureAPIKeyManager.shared.hasAPIKey() else {
     showAlert("Please configure your API key in settings")
     return
 }
 
 
 // PATTERN 2: Safe API key retrieval
 // ──────────────────────────────────
 
 func makeAPICall() async {
     do {
         let key = try SecureAPIKeyManager.shared.retrieveAPIKey()
         // Make API call with key...
     } catch {
         handleError(error)
     }
 }
 
 
 // PATTERN 3: Conditional AI features
 // ───────────────────────────────────
 
 var isAIAvailable: Bool {
     AppSettings.shared.externalAIEnabled &&
     SecureAPIKeyManager.shared.hasAPIKey()
 }
 
 if isAIAvailable {
     // Show AI-powered features
 } else {
     // Show standard features only
 }
 
 
 // PATTERN 4: Graceful degradation
 // ────────────────────────────────
 
 func getRecommendations() async -> [Recommendation] {
     var recommendations: [Recommendation] = []
     
     // Always add game logic recommendations
     recommendations.append(contentsOf: getGameLogicRecommendations())
     
     // Try to add AI recommendations if available
     if isAIAvailable {
         do {
             let aiRecs = try await getAIRecommendations()
             recommendations.append(contentsOf: aiRecs)
         } catch {
             print("AI unavailable, using game logic only")
         }
     }
     
     return recommendations
 }
 
 
 // PATTERN 5: User feedback for configuration
 // ───────────────────────────────────────────
 
 struct FeatureRequiringAI: View {
     @StateObject private var keyManager = SecureAPIKeyManager.shared
     
     var body: some View {
         if keyManager.isAPIKeyConfigured {
             AIFeaturesView()
         } else {
             VStack {
                 Image(systemName: "brain.fill")
                     .font(.system(size: 60))
                     .foregroundStyle(.gray)
                 
                 Text("AI Features Require Configuration")
                     .font(.headline)
                 
                 Text("Add your API key in settings to unlock AI-powered recommendations.")
                     .font(.caption)
                     .foregroundStyle(.secondary)
                 
                 NavigationLink("Configure Now") {
                     APIKeySettingsView()
                 }
                 .buttonStyle(.borderedProminent)
             }
             .padding()
         }
     }
 }
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                    TESTING & DEBUGGING                           ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 
 // DEBUG: Check keychain status
 // ─────────────────────────────
 
 #if DEBUG
 func debugKeychain() {
     let manager = SecureAPIKeyManager.shared
     
     print("Has API Key:", manager.hasAPIKey())
     print("Is Configured:", manager.isAPIKeyConfigured)
     
     if let error = manager.lastError {
         print("Last Error:", error)
     }
     
     do {
         let key = try manager.retrieveAPIKey()
         print("Key Length:", key.count)
         print("Key Preview:", String(key.prefix(10)) + "...")
     } catch {
         print("Cannot retrieve key:", error)
     }
 }
 #endif
 
 
 // MOCK: Test without real API key
 // ────────────────────────────────
 
 #if DEBUG
 extension ExternalAIAgentService {
     func useMockData() {
         lastResponse = AIAgentResponse(
             recommendations: [
                 "Focus on battleground states",
                 "Increase fundraising efforts",
                 "Schedule town halls in key districts"
             ],
             confidence: 0.85,
             reasoning: "Mock AI analysis for testing"
         )
     }
 }
 #endif
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                      FILE REFERENCE                              ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 SecureAPIKeyManager.swift         - Core security manager
 APIKeySettingsView.swift          - UI for key management
 ExternalAIIntegrationExample.swift - Integration examples
 AI_AGENT_INTEGRATION.md           - Full documentation
 IMPLEMENTATION_SUMMARY.md         - Implementation overview
 QuickStartGuide.swift            - This file
 
 
 ╔══════════════════════════════════════════════════════════════════╗
 ║                    COMMON QUESTIONS                              ║
 ╚══════════════════════════════════════════════════════════════════╝
 
 Q: Why do I need to re-enter the key each session?
 A: Security by design. Session-only storage minimizes exposure window
    and follows the principle of ephemeral credentials.
 
 Q: Can I make it persistent?
 A: You can modify the code, but it's not recommended. Users can store
    their key in 1Password/Keychain Access and paste when needed.
 
 Q: Does it work in the simulator?
 A: Yes, but test on real device to verify Keychain behavior.
 
 Q: What if cleanup fails?
 A: Triple-layered cleanup (notification, deinit, manual) makes
    failure extremely unlikely. Check logs for warnings.
 
 Q: Can I support multiple AI providers?
 A: Yes! Store multiple keys with different account names, or let
    users choose which provider to use with a single key.
 
 Q: How do I test without an API key?
 A: Use the mock methods provided in DEBUG builds, or create
    a free API key from OpenAI/Anthropic for testing.
 
 
 ═══════════════════════════════════════════════════════════════════
                         END OF QUICK START GUIDE
 ═══════════════════════════════════════════════════════════════════
 
 */
