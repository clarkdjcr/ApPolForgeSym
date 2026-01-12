//
//  ExternalAIIntegrationExample.swift
//  ApPolForgeSym
//
//  Example code showing how to integrate external AI with StrategicAdvisor
//  Created by Donald Clark on 1/13/26.
//

import Foundation

// MARK: - Example: Enhanced StrategicAdvisor with External AI

/*
 Add this method to your StrategicAdvisor class to integrate external AI recommendations
 alongside your existing game logic recommendations.
 */

extension StrategicAdvisor {
    
    /// Enhanced recommendation generation with external AI support
    func generateEnhancedRecommendations(for playerType: PlayerType) async -> [StrategicRecommendation] {
        var recommendations: [StrategicRecommendation] = []
        
        // 1. Generate base recommendations using existing game logic
        let baseRecommendations = generateRecommendations(for: playerType)
        recommendations.append(contentsOf: baseRecommendations)
        
        // 2. If external AI is enabled, get AI-powered recommendations
        if AppSettings.shared.externalAIEnabled,
           SecureAPIKeyManager.shared.hasAPIKey() {
            
            do {
                let aiRecommendations = try await generateAIRecommendations(for: playerType)
                recommendations.append(contentsOf: aiRecommendations)
            } catch {
                print("⚠️ External AI error: \(error.localizedDescription)")
                // Gracefully degrade - continue with base recommendations only
            }
        }
        
        // 3. Deduplicate and prioritize
        return deduplicateRecommendations(recommendations)
    }
    
    /// Generate recommendations using external AI service
    private func generateAIRecommendations(for playerType: PlayerType) async throws -> [StrategicRecommendation] {
        guard let endpoint = URL(string: AppSettings.shared.externalAIEndpoint) else {
            throw URLError(.badURL)
        }
        
        let aiService = ExternalAIAgentService.shared
        let response = try await aiService.getRecommendations(
            for: gameState,
            playerType: playerType,
            apiEndpoint: endpoint
        )
        
        // Convert AI response to game recommendations
        return parseAIResponse(response, for: playerType)
    }
    
    /// Parse external AI response into game recommendations
    private func parseAIResponse(
        _ response: AIAgentResponse,
        for playerType: PlayerType
    ) -> [StrategicRecommendation] {
        var recommendations: [StrategicRecommendation] = []
        
        // Example: Convert AI text recommendations into structured recommendations
        for (index, recommendation) in response.recommendations.enumerated() {
            let rec = StrategicRecommendation(
                type: .offensive, // Determine from AI response content
                priority: index == 0 ? .critical : .high, // First is highest priority
                title: "AI Suggestion \(index + 1)",
                description: recommendation,
                targetStates: [], // Parse from AI response if available
                suggestedActions: [.rally, .adCampaign], // Parse from AI response
                estimatedCost: 2_000_000,
                expectedImpact: "Based on AI analysis",
                reasoning: response.reasoning ?? "AI-powered recommendation"
            )
            recommendations.append(rec)
        }
        
        return recommendations
    }
    
    /// Remove duplicate recommendations and prioritize
    private func deduplicateRecommendations(
        _ recommendations: [StrategicRecommendation]
    ) -> [StrategicRecommendation] {
        var seen = Set<String>()
        var unique: [StrategicRecommendation] = []
        
        // Helper to convert priority to value
        func priorityValue(_ priority: RecommendationPriority) -> Int {
            switch priority {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
        
        for rec in recommendations.sorted(by: { priorityValue($0.priority) > priorityValue($1.priority) }) {
            let key = "\(rec.type.rawValue)-\(rec.title)"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(rec)
            }
        }
        
        return Array(unique.prefix(5)) // Limit to top 5
    }
}

// MARK: - Example: OpenAI Integration

/// Example implementation for OpenAI's API
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

extension ExternalAIAgentService {
    
    /// Specialized method for OpenAI API
    func getOpenAIRecommendations(
        for gameState: GameState,
        playerType: PlayerType
    ) async throws -> AIAgentResponse {
        guard let endpoint = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        
        let apiKey = try SecureAPIKeyManager.shared.retrieveAPIKey()
        
        // Create prompt
        let prompt = createStrategicPrompt(gameState: gameState, playerType: playerType)
        
        let request = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIRequest.Message(role: "system", content: "You are an expert political campaign strategist."),
                OpenAIRequest.Message(role: "user", content: prompt)
            ],
            temperature: 0.7,
            max_tokens: 500
        )
        
        // Make request
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        // Parse OpenAI response
        guard let content = openAIResponse.choices.first?.message.content else {
            throw URLError(.cannotParseResponse)
        }
        
        return AIAgentResponse(
            recommendations: parseRecommendationsFromText(content),
            confidence: 0.85,
            reasoning: content
        )
    }
    
    private func createStrategicPrompt(gameState: GameState, playerType: PlayerType) -> String {
        let player = playerType == .incumbent ? gameState.incumbent : gameState.challenger
        let votes = gameState.calculateElectoralVotes()
        let playerVotes = playerType == .incumbent ? votes.incumbent : votes.challenger
        
        return """
        You are advising the \(player.name) campaign. Current situation:
        
        Electoral Votes: \(playerVotes)/270 needed
        Campaign Funds: $\(player.campaignFunds.asCurrency())
        Weeks Remaining: \(gameState.maxTurns - gameState.currentTurn)
        
        Battleground States:
        \(gameState.states.filter { $0.isBattleground }.map { state in
            "\(state.name): \(state.incumbentSupport)% vs \(state.challengerSupport)%"
        }.joined(separator: "\n"))
        
        Provide 3 strategic recommendations for winning this election. Focus on:
        1. States to target
        2. Resource allocation
        3. Timing and priorities
        
        Format each recommendation as a numbered list.
        """
    }
    
    private func parseRecommendationsFromText(_ text: String) -> [String] {
        // Simple parsing - split by numbered list
        let pattern = "\\d+\\."
        let components = text.components(separatedBy: CharacterSet.newlines)
        
        return components
            .filter { line in
                line.range(of: pattern, options: .regularExpression) != nil
            }
            .map { line in
                line.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
            }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Example: Anthropic Integration

/// Example implementation for Anthropic's Claude API
struct AnthropicRequest: Codable {
    let model: String
    let max_tokens: Int
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct AnthropicResponse: Codable {
    let content: [Content]
    
    struct Content: Codable {
        let text: String
    }
}

extension ExternalAIAgentService {
    
    /// Specialized method for Anthropic API
    func getAnthropicRecommendations(
        for gameState: GameState,
        playerType: PlayerType
    ) async throws -> AIAgentResponse {
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        
        let apiKey = try SecureAPIKeyManager.shared.retrieveAPIKey()
        let prompt = createStrategicPrompt(gameState: gameState, playerType: playerType)
        
        let request = AnthropicRequest(
            model: "claude-3-opus-20240229",
            max_tokens: 1024,
            messages: [
                AnthropicRequest.Message(role: "user", content: prompt)
            ]
        )
        
        // Make request
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        
        guard let content = anthropicResponse.content.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        return AIAgentResponse(
            recommendations: parseRecommendationsFromText(content),
            confidence: 0.9,
            reasoning: content
        )
    }
}

// MARK: - Usage Example in View

/*
 Example of how to use in a SwiftUI view:
 
 struct StrategicDashboardView: View {
     @StateObject private var advisor: StrategicAdvisor
     @State private var recommendations: [StrategicRecommendation] = []
     @State private var isLoading = false
     
     var body: some View {
         List(recommendations) { rec in
             RecommendationRow(recommendation: rec)
         }
         .task {
             await loadRecommendations()
         }
     }
     
     private func loadRecommendations() async {
         isLoading = true
         recommendations = await advisor.generateEnhancedRecommendations(
             for: gameState.currentPlayer
         )
         isLoading = false
     }
 }
 */

// MARK: - Supporting Types

/// Extended recommendation type that includes AI metadata
struct AIEnhancedRecommendation {
    let baseRecommendation: StrategicRecommendation
    let aiConfidence: Double?
    let aiReasoning: String?
    let source: RecommendationSource
    
    enum RecommendationSource {
        case gameLogic
        case externalAI
        case hybrid
    }
}

// MARK: - Testing Utilities

#if DEBUG
extension ExternalAIAgentService {
    
    /// Mock AI service for testing without API key
    func getMockRecommendations(
        for gameState: GameState,
        playerType: PlayerType
    ) -> AIAgentResponse {
        AIAgentResponse(
            recommendations: [
                "Focus resources on Pennsylvania, Michigan, and Wisconsin - these states show the strongest opportunity for gains.",
                "Increase grassroots organizing in battleground states where infrastructure is weak.",
                "Plan major fundraising push within next 2 weeks to sustain advertising through election day."
            ],
            confidence: 0.85,
            reasoning: "Mock AI analysis based on current game state and historical patterns."
        )
    }
}
#endif
