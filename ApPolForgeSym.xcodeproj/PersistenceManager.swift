//
//  PersistenceManager.swift
//  ApPolForgeSym
//
//  Created by Donald Clark on 1/12/26.
//

import Foundation

/// Manages saving and loading game state to disk
@MainActor
class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var saveFileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("savedGame.json")
    }
    
    private var autoSaveFileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("autoSave.json")
    }
    
    private init() {
        encoder.outputFormatting = .prettyPrinted
    }
    
    // MARK: - Save Game
    
    /// Saves the current game state to disk
    func saveGame(_ gameState: GameState) throws {
        let saveData = SaveData(from: gameState)
        let data = try encoder.encode(saveData)
        try data.write(to: saveFileURL, options: .atomic)
    }
    
    /// Auto-saves the game state (separate file from manual saves)
    func autoSaveGame(_ gameState: GameState) throws {
        let saveData = SaveData(from: gameState)
        let data = try encoder.encode(saveData)
        try data.write(to: autoSaveFileURL, options: .atomic)
    }
    
    // MARK: - Load Game
    
    /// Loads a saved game
    func loadGame() throws -> SaveData {
        let data = try Data(contentsOf: saveFileURL)
        return try decoder.decode(SaveData.self, from: data)
    }
    
    /// Loads the auto-saved game
    func loadAutoSave() throws -> SaveData {
        let data = try Data(contentsOf: autoSaveFileURL)
        return try decoder.decode(SaveData.self, from: data)
    }
    
    // MARK: - Utilities
    
    /// Checks if a saved game exists
    func hasSavedGame() -> Bool {
        fileManager.fileExists(atPath: saveFileURL.path)
    }
    
    /// Checks if an auto-save exists
    func hasAutoSave() -> Bool {
        fileManager.fileExists(atPath: autoSaveFileURL.path)
    }
    
    /// Deletes the saved game
    func deleteSavedGame() throws {
        if hasSavedGame() {
            try fileManager.removeItem(at: saveFileURL)
        }
    }
    
    /// Deletes the auto-save
    func deleteAutoSave() throws {
        if hasAutoSave() {
            try fileManager.removeItem(at: autoSaveFileURL)
        }
    }
    
    /// Gets save file metadata
    func getSaveMetadata() -> SaveMetadata? {
        guard hasSavedGame() else { return nil }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: saveFileURL.path)
            let saveDate = attributes[.modificationDate] as? Date ?? Date()
            let saveData = try loadGame()
            
            return SaveMetadata(
                saveDate: saveDate,
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

// MARK: - Save Data Structure

struct SaveData: Codable {
    let incumbent: Player
    let challenger: Player
    let states: [ElectoralState]
    let currentTurn: Int
    let maxTurns: Int
    let currentPlayer: PlayerType
    let recentEvents: [GameEvent]
    let gamePhase: String
    let saveDate: Date
    
    init(from gameState: GameState) {
        self.incumbent = gameState.incumbent
        self.challenger = gameState.challenger
        self.states = gameState.states
        self.currentTurn = gameState.currentTurn
        self.maxTurns = gameState.maxTurns
        self.currentPlayer = gameState.currentPlayer
        self.recentEvents = gameState.recentEvents
        self.gamePhase = gameState.gamePhase.rawValue
        self.saveDate = Date()
    }
    
    func apply(to gameState: GameState) {
        gameState.incumbent = incumbent
        gameState.challenger = challenger
        gameState.states = states
        gameState.currentTurn = currentTurn
        gameState.maxTurns = maxTurns
        gameState.currentPlayer = currentPlayer
        gameState.recentEvents = recentEvents
        gameState.gamePhase = GameState.GamePhase(rawValue: gamePhase) ?? .setup
    }
}

struct SaveMetadata {
    let saveDate: Date
    let currentTurn: Int
    let maxTurns: Int
    let incumbentName: String
    let challengerName: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: saveDate)
    }
    
    var turnDescription: String {
        "Week \(currentTurn) of \(maxTurns)"
    }
}
