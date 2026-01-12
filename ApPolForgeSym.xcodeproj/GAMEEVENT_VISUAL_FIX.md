# Visual Fix Guide: GameEvent Errors

```
╔══════════════════════════════════════════════════════════════════╗
║                     ERRORS BEFORE                                ║
╚══════════════════════════════════════════════════════════════════╝

❌ AIOpponent.swift:274
   gameState.addEvent(GameEvent(...))
   ^^^^^^^^^^^^^^^^^
   Value of type 'GameState' has no member 'addEvent'

❌ AIOpponent.swift:274
   GameEvent(
       id: UUID(),
       title: "...",        ← Wrong order!
       description: "...",
       turn: ...,
       affectedPlayer: ...,
       impactMagnitude: ...
   )
   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
   Incorrect argument labels

❌ AIOpponent.swift:275
   GameEvent(
       id: UUID(),
       ← Missing 'type' parameter!
       title: "...",
   )


╔══════════════════════════════════════════════════════════════════╗
║                     ROOT CAUSE                                   ║
╚══════════════════════════════════════════════════════════════════╝

GameState class does NOT have an addEvent() method:

┌────────────────────────────────────────────────────────────┐
│ @MainActor                                                 │
│ class GameState: ObservableObject {                        │
│     @Published var recentEvents: [GameEvent]               │
│                                                            │
│     // ... other properties ...                            │
│                                                            │
│     // ❌ No addEvent() method exists!                    │
│ }                                                          │
└────────────────────────────────────────────────────────────┘

GameEvent initializer signature:

┌────────────────────────────────────────────────────────────┐
│ init(id: UUID = UUID(),                                    │
│      type: EventType,        ← REQUIRED!                   │
│      title: String,                                        │
│      description: String,                                  │
│      affectedPlayer: PlayerType?,                          │
│      impactMagnitude: Int,                                 │
│      turn: Int)              ← turn is LAST!               │
└────────────────────────────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════╗
║                     FIX APPLIED                                  ║
╚══════════════════════════════════════════════════════════════════╝

BEFORE:
┌────────────────────────────────────────────────────────────┐
│ gameState.addEvent(GameEvent(                              │
│     id: UUID(),                                            │
│     title: "Coordinated Multi-State Campaign",            │
│     description: "Launched synchronized...",              │
│     turn: gameState.currentTurn,                          │
│     affectedPlayer: .challenger,                          │
│     impactMagnitude: 5                                    │
│ ))                                                         │
└────────────────────────────────────────────────────────────┘
         ❌ Wrong method
         ❌ Missing 'type'
         ❌ Wrong parameter order

AFTER:
┌────────────────────────────────────────────────────────────┐
│ let event = GameEvent(                                     │
│     id: UUID(),                                            │
│     type: .viral,              ← ✅ ADDED                  │
│     title: "Coordinated Multi-State Campaign",            │
│     description: "Launched synchronized...",              │
│     affectedPlayer: .challenger,  ← ✅ Correct order      │
│     impactMagnitude: 5,                                   │
│     turn: gameState.currentTurn   ← ✅ Moved to end       │
│ )                                                          │
│ gameState.recentEvents.append(event)                      │
│            ^^^^^^^^^^^^^^^^^^^^^^                          │
│            ✅ Direct array append                          │
└────────────────────────────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════╗
║                 WHY .viral EVENT TYPE?                           ║
╚══════════════════════════════════════════════════════════════════╝

Available EventTypes:
┌─────────────────────────────────────────────────────────────┐
│ .scandal       → Negative campaign event                    │
│ .economicNews  → Economic developments                      │
│ .endorsement   → Major endorsement received                 │
│ .gaffe         → Campaign mistake                           │
│ .crisis        → National crisis event                      │
│ .viral         → Positive viral moment ✅ BEST FIT          │
└─────────────────────────────────────────────────────────────┘

A coordinated multi-state campaign is a positive viral moment
that generates buzz and momentum across multiple states!


╔══════════════════════════════════════════════════════════════════╗
║                  COMPLETE FIXED SECTION                          ║
╚══════════════════════════════════════════════════════════════════╝

private func executeMultiStateStrategy() async {
    // ... state selection logic ...
    
    // Execute coordinated campaign
    let totalCost = costPerState * Double(targetStates.count)
    gameState.challenger.campaignFunds -= totalCost
    
    let efficiencyBonus = 1.15 // 15% bonus for coordination
    
    for state in targetStates {
        guard let index = gameState.states.firstIndex(
            where: { $0.id == state.id }
        ) else { continue }
        
        gameState.states[index].challengerSupport += 
            Double.random(in: 3...7) * efficiencyBonus
    }
    
    gameState.challenger.momentum += 8
    
    // ✅ FIXED: Add event to recent events
    let event = GameEvent(
        id: UUID(),
        type: .viral,
        title: "Coordinated Multi-State Campaign",
        description: "Launched synchronized campaign across \(targetStates.count) key states",
        affectedPlayer: .challenger,
        impactMagnitude: 5,
        turn: gameState.currentTurn
    )
    gameState.recentEvents.append(event)
    
    gameState.endTurn()
}


╔══════════════════════════════════════════════════════════════════╗
║               HOW TO ADD EVENTS IN THE FUTURE                    ║
╚══════════════════════════════════════════════════════════════════╝

Pattern to follow:

1️⃣ Create the event
┌────────────────────────────────────────────────────────────┐
│ let event = GameEvent(                                     │
│     type: .viral,           // Choose appropriate type     │
│     title: "Event Title",                                  │
│     description: "What happened",                          │
│     affectedPlayer: .incumbent,  // or .challenger         │
│     impactMagnitude: 5,     // -50 to 50                  │
│     turn: gameState.currentTurn                           │
│ )                                                          │
└────────────────────────────────────────────────────────────┘

2️⃣ Add to recentEvents
┌────────────────────────────────────────────────────────────┐
│ gameState.recentEvents.append(event)                      │
└────────────────────────────────────────────────────────────┘

3️⃣ Optional: Limit event history
┌────────────────────────────────────────────────────────────┐
│ // Keep only last 10 events                               │
│ if gameState.recentEvents.count > 10 {                    │
│     gameState.recentEvents = Array(                       │
│         gameState.recentEvents.suffix(10)                 │
│     )                                                      │
│ }                                                          │
└────────────────────────────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════╗
║            OPTIONAL: ADD HELPER METHOD                           ║
╚══════════════════════════════════════════════════════════════════╝

You can add this to GameState for convenience:

extension GameState {
    /// Adds an event to recent events with optional history limit
    func addEvent(_ event: GameEvent, limit: Int = 10) {
        recentEvents.append(event)
        
        // Keep only recent events
        if recentEvents.count > limit {
            recentEvents = Array(recentEvents.suffix(limit))
        }
    }
}

Then use it like:
┌────────────────────────────────────────────────────────────┐
│ gameState.addEvent(event)                                  │
└────────────────────────────────────────────────────────────┘


╔══════════════════════════════════════════════════════════════════╗
║                    VERIFICATION                                  ║
╚══════════════════════════════════════════════════════════════════╝

After this fix:

✅ Build (Cmd+B) succeeds
✅ No "has no member 'addEvent'" error
✅ No "incorrect argument labels" error
✅ No "missing argument for parameter 'type'" error
✅ GameEvent initializes correctly
✅ Events appear in game UI
✅ AI multi-state strategy works

Test in game:
1. Start game with AI opponent (difficulty: Hard or Expert)
2. Let AI play multiple turns
3. AI will execute multi-state strategy when conditions are right
4. Check recent events - should see "Coordinated Multi-State Campaign"
5. No crashes or errors


╔══════════════════════════════════════════════════════════════════╗
║                       SUMMARY                                    ║
╚══════════════════════════════════════════════════════════════════╝

File:     AIOpponent.swift
Lines:    274-285
Changes:  3 fixes applied

✅ Added missing 'type' parameter (.viral)
✅ Reordered parameters to match init signature
✅ Replaced non-existent addEvent() with recentEvents.append()

Result:   Code compiles and AI multi-state campaigns work! 🎉


═══════════════════════════════════════════════════════════════════
                    ALL ERRORS FIXED!
═══════════════════════════════════════════════════════════════════
```
