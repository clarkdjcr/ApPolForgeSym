//
//  PersistenceManager.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/11/26.
//

import Foundation

// MARK: - Save Data Structure

struct GameSaveData: Codable {
    let incumbent: Player
    let challenger: Player
    let states: [ElectoralState]
    let currentTurn: Int
    let maxTurns: Int
    let currentPlayer: PlayerType
    let recentEvents: [GameEvent]
    let savedDate: Date
    
    init(from gameState: GameState) {
        self.incumbent = gameState.incumbent
        self.challenger = gameState.challenger
        self.states = gameState.states
        self.currentTurn = gameState.currentTurn
        self.maxTurns = gameState.maxTurns
        self.currentPlayer = gameState.currentPlayer
        self.recentEvents = gameState.recentEvents
        self.savedDate = Date()
    }
    
    @MainActor
    func apply(to gameState: GameState) {
        gameState.incumbent = incumbent
        gameState.challenger = challenger
        gameState.states = states
        gameState.currentTurn = currentTurn
        gameState.maxTurns = maxTurns
        gameState.currentPlayer = currentPlayer
        gameState.recentEvents = recentEvents
        gameState.gamePhase = .playing
    }
}

// MARK: - Save Metadata

struct SaveMetadata: Codable {
    let savedDate: Date
    let currentTurn: Int
    let maxTurns: Int
    let incumbentName: String
    let challengerName: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedDate)
    }
    
    var turnDescription: String {
        return "Week \(currentTurn) of \(maxTurns)"
    }
}

// MARK: - Persistence Manager

@MainActor
class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let autoSaveURL: URL
    private let fileManager = FileManager.default
    
    private init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        autoSaveURL = documentsDirectory.appendingPathComponent("autosave.json")
    }
    
    // MARK: - Auto Save
    
    func autoSaveGame(_ gameState: GameState) throws {
        let saveData = GameSaveData(from: gameState)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(saveData)
        try data.write(to: autoSaveURL)
    }
    
    // MARK: - Manual Save
    
    func saveGame(_ gameState: GameState) throws {
        // For manual saves, we use the same auto-save location
        // In a more complex app, you might want separate save slots
        try autoSaveGame(gameState)
    }
    
    func loadAutoSave() throws -> GameSaveData {
        let data = try Data(contentsOf: autoSaveURL)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(GameSaveData.self, from: data)
        } catch {
            // Migration guard: old save missing new ElectoralState fields — delete and rethrow
            print("PersistenceManager: Save data incompatible (likely missing new state fields). Deleting old save.")
            try? deleteAutoSave()
            throw error
        }
    }
    
    func hasAutoSave() -> Bool {
        return fileManager.fileExists(atPath: autoSaveURL.path)
    }
    
    func deleteAutoSave() throws {
        if hasAutoSave() {
            try fileManager.removeItem(at: autoSaveURL)
        }
    }
    
    func getSaveMetadata() -> SaveMetadata? {
        guard hasAutoSave() else { return nil }
        
        do {
            let saveData = try loadAutoSave()
            return SaveMetadata(
                savedDate: saveData.savedDate,
                currentTurn: saveData.currentTurn,
                maxTurns: saveData.maxTurns,
                incumbentName: saveData.incumbent.name,
                challengerName: saveData.challenger.name
            )
        } catch {
            return nil
        }
    }
}
