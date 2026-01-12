# External AI Agent Integration Guide

## Overview

This implementation provides secure API key management for external AI agents with automatic session cleanup. The API key is stored in the system Keychain and automatically deleted when the app terminates, ensuring maximum security.

## Key Components

### 1. `SecureAPIKeyManager.swift`
**Main security manager that handles:**
- ✅ Secure storage in Keychain using `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- ✅ Automatic deletion on app termination
- ✅ Save, retrieve, and delete operations
- ✅ Validation and error handling
- ✅ Observable for SwiftUI integration

**Key Features:**
```swift
// Save API key
try SecureAPIKeyManager.shared.saveAPIKey("sk-...")

// Retrieve API key
let key = try SecureAPIKeyManager.shared.retrieveAPIKey()

// Delete API key (or automatic on app quit)
try SecureAPIKeyManager.shared.deleteAPIKey()

// Check if key exists
let hasKey = SecureAPIKeyManager.shared.hasAPIKey()
```

### 2. `APIKeySettingsView.swift`
**SwiftUI view providing:**
- ✅ Secure text field for API key entry (with show/hide toggle)
- ✅ Visual indication when key is configured
- ✅ Delete functionality with confirmation
- ✅ API endpoint configuration
- ✅ Security notices and instructions
- ✅ Integration toggle for enabling/disabling AI agent

### 3. `ExternalAIAgentService`
**Service class for making API calls:**
- ✅ Async/await based networking
- ✅ Automatic API key retrieval from Keychain
- ✅ Configurable endpoints
- ✅ Game state serialization
- ✅ Response parsing

### 4. Updated `PersistenceManager.swift`
**Enhanced to coordinate cleanup:**
- ✅ Observes app termination notifications
- ✅ Triggers API key cleanup on session end

### 5. Updated `AppSettings.swift`
**New settings added:**
- `externalAIEnabled`: Toggle for AI agent feature
- `externalAIEndpoint`: Configurable API endpoint URL

## Security Features

### 🔒 Keychain Storage
- Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security
- Keys never written to disk in plain text
- Protected by device encryption

### 🧹 Automatic Cleanup
Three layers of protection ensure keys are deleted:
1. **App Termination Observer** - Responds to system notifications
2. **Deinit Handler** - Cleanup in destructor
3. **Manual Cleanup** - User can delete anytime

### 🔐 Best Practices Implemented
- ✅ No API keys in UserDefaults
- ✅ No API keys in files
- ✅ SecureField for password-like entry
- ✅ Show/hide toggle for verification
- ✅ Automatic session cleanup
- ✅ Clear user communication about security

## Integration Steps

### Step 1: Add to Settings View
Add navigation to `APIKeySettingsView` in your settings menu:

```swift
NavigationLink {
    APIKeySettingsView()
} label: {
    Label("AI Agent", systemImage: "brain.fill")
}
```

### Step 2: Use in Strategic Advisor
Integrate with your existing `StrategicAdvisor`:

```swift
class StrategicAdvisor: ObservableObject {
    private let externalAI = ExternalAIAgentService.shared
    
    func generateRecommendations(for playerType: PlayerType) -> [StrategicRecommendation] {
        var recommendations: [StrategicRecommendation] = []
        
        // Your existing logic...
        
        // Add external AI recommendations if enabled
        if AppSettings.shared.externalAIEnabled && externalAI.isEnabled {
            Task {
                do {
                    let endpoint = URL(string: AppSettings.shared.externalAIEndpoint)!
                    let response = try await externalAI.getRecommendations(
                        for: gameState,
                        playerType: playerType,
                        apiEndpoint: endpoint
                    )
                    // Process response.recommendations
                } catch {
                    print("External AI error: \(error)")
                }
            }
        }
        
        return recommendations
    }
}
```

### Step 3: Test Cleanup
The cleanup happens automatically, but you can test manually:

```swift
// Manually trigger cleanup (for testing)
SecureAPIKeyManager.shared.cleanupSession()
```

## Error Handling

The system includes comprehensive error types:

```swift
enum APIKeyError: LocalizedError {
    case emptyKey              // User tried to save empty key
    case keyNotFound           // No key in Keychain
    case encodingFailed        // String encoding issue
    case decodingFailed        // String decoding issue
    case keychainError(OSStatus) // Keychain operation failed
}
```

All errors have localized descriptions for user-friendly messages.

## API Provider Examples

### OpenAI (Default)
- Endpoint: `https://api.openai.com/v1/chat/completions`
- API Key format: `sk-...`

### Anthropic
- Endpoint: `https://api.anthropic.com/v1/messages`
- API Key format: `sk-ant-...`

### Custom Providers
Users can configure any compatible REST API endpoint.

## Testing Checklist

- [ ] API key saves successfully
- [ ] API key retrieves correctly
- [ ] Show/hide toggle works
- [ ] Delete confirmation appears
- [ ] Key deleted on app quit
- [ ] Key deleted on manual delete
- [ ] Settings toggle disabled when no key
- [ ] Error messages are clear
- [ ] Keychain errors handled gracefully
- [ ] API calls include Authorization header

## Platform Support

This implementation works on:
- ✅ iOS 16+
- ✅ iPadOS 16+
- ✅ macOS 13+

The Keychain API is available on all Apple platforms.

## Future Enhancements

Potential improvements:
1. **Multiple API Keys** - Support for different providers simultaneously
2. **Key Rotation** - Automatic expiration and renewal prompts
3. **Usage Tracking** - Monitor API call counts and costs
4. **Provider Templates** - Pre-configured settings for popular services
5. **Biometric Protection** - Require Face ID/Touch ID to retrieve key
6. **Key Validation** - Test API key before saving

## Security Notes for Users

When you implement UI around this, make sure users understand:

> **Important:** Your API key is stored securely in the system Keychain and is protected by device encryption. The key will be automatically deleted when you quit the app. You'll need to enter it again the next time you want to use the AI agent feature.

This ensures users know:
1. Their key is secure
2. It's temporary (session-only)
3. They need to re-enter it each session (this is by design for security)

## Support Contact

For questions about this implementation, contact the development team or file an issue in the project repository.

---

**Implementation Date:** January 13, 2026  
**Version:** 1.0  
**Compatibility:** iOS 16+, iPadOS 16+, macOS 13+
