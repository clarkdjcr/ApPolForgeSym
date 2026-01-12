# Campaign Manager 2026

A strategic turn-based election simulation game for iOS/iPadOS built with SwiftUI.

## 🎮 Game Overview

Take control of either the **Incumbent Party** or **Challenger Party** in a high-stakes race for the presidency. Manage your campaign funds, execute strategic actions, and navigate unpredictable events over 20 intense weeks leading up to Election Day.

## 🎯 How to Win

Secure **270 or more electoral votes** by winning individual states through strategic campaign actions.

## ✨ Features

### Core Gameplay
- **Turn-based Strategy**: Take one action per turn, choosing from 7 different campaign strategies
- **Electoral Map**: 14 states with varying electoral votes and voter sentiment
- **Resource Management**: Balance campaign funds, momentum, and national polling
- **Random Events**: 40% chance per turn of game-changing events
- **AI Opponent**: Smart AI that adapts its strategy based on the race dynamics

### User Experience
- **Save/Load System**: Manual save and auto-save functionality
- **Tutorial Mode**: Interactive tutorial for new players
- **In-Game Help**: Quick tips and strategy guide
- **Settings**: Customize sound, haptics, AI speed, and more
- **Share Results**: Share your election victories on social media

### Accessibility
- **VoiceOver Support**: Full screen reader compatibility
- **Dynamic Type**: Text scales with system settings
- **Haptic Feedback**: Tactile responses for actions
- **High Contrast**: Readable in all lighting conditions
- **Comprehensive Labels**: Descriptive accessibility labels throughout

### Campaign Actions
1. **Rally** - Energize your base and boost state support
2. **Ad Campaign** - Saturate airwaves for major polling gains
3. **Fundraiser** - Replenish your campaign war chest
4. **Town Hall** - Connect with voters personally
5. **Debate Prep** - Prepare for strong debate performances
6. **Grassroots Organizing** - Build sustainable ground game
7. **Opposition Research** - Go negative and damage opponent

### Dynamic Events
- Campaign scandals
- Economic news
- Major endorsements
- Candidate gaffes
- National crises
- Viral moments

## 🚀 Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+
- Swift 5.9+

### Installation
1. Open `ApPolForgeSym.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press **⌘R** to build and run

### File Structure
```
ApPolForgeSym/
├── ApPolForgeSymApp.swift       # App entry point
├── ContentView.swift            # Main UI views
├── Models/
│   └── GameModels.swift         # Game data models and logic
├── AIOpponent.swift             # AI strategy system
├── PersistenceManager.swift    # Save/load functionality
├── SettingsView.swift           # User settings
├── TutorialView.swift           # Tutorial and help screens
├── HapticsManager.swift         # Haptic feedback system
├── AccessibilityExtensions.swift # Accessibility support
├── Extensions.swift             # Helper extensions
├── GAME_DESIGN.md              # Detailed game design document
├── APP_ICON_GUIDE.md           # Guide for creating app icons
└── APP_STORE_CHECKLIST.md      # Submission checklist
```

## 🎲 Gameplay Tips

### Strategy Guidelines
1. **Watch Your Funds**: Running out of money limits your options
2. **Target Battleground States**: Focus on states within 10 points
3. **Time Your Actions**: Save expensive moves for critical moments
4. **Adapt to Events**: Respond quickly to game-changing events
5. **Balance Resources**: Don't neglect momentum or polling for just money

### Early Game (Weeks 1-7)
- Build your war chest with fundraisers
- Establish ground game in key states
- React to early events

### Mid Game (Weeks 8-14)
- Focus on battleground states
- Use ad campaigns strategically
- Prepare for debates

### Late Game (Weeks 15-20)
- All-in on must-win states
- Calculate electoral paths to 270
- Use opposition research sparingly

## 🤖 AI Behavior

The AI opponent uses four adaptive strategies:

1. **Aggressive** - When losing badly, goes all-in on swing states
2. **Defensive** - When winning, protects vulnerable leads
3. **Balanced** - When competitive, plays strategically everywhere
4. **Fundraising** - When low on cash, prioritizes fundraising

## 🔮 Future Features

### Completed ✅
- [x] Save/load game functionality
- [x] Tutorial mode
- [x] Settings screen
- [x] Haptic feedback
- [x] Full accessibility support
- [x] Share results feature

### Planned Enhancements
- [ ] Two-player hot-seat mode
- [ ] Multiplayer over network
- [ ] Difficulty settings
- [ ] Historical election scenarios
- [ ] Custom candidate creator
- [ ] More detailed state modeling
- [ ] Demographic voter groups
- [ ] Primary election mode
- [ ] Debate mini-games
- [ ] Sound effects and music
- [ ] Game Center integration
- [ ] iCloud sync

## 🛠 Technical Details

### Architecture
- **SwiftUI** for modern, reactive UI
- **Combine** for state management with @Published properties
- **Swift Concurrency** for AI processing
- **Value types** for immutable game state
- **UserDefaults** for app settings
- **File system** for game saves (JSON encoding)

### Key Design Patterns
- MVVM architecture
- Observer pattern for reactive updates
- Strategy pattern for AI
- Command pattern for actions
- Singleton pattern for managers (Settings, Haptics, Persistence)

## 📖 Additional Resources

See [GAME_DESIGN.md](GAME_DESIGN.md) for detailed information about:
- Complete game mechanics
- AI strategy breakdown
- Balancing decisions
- Future feature roadmap

See [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md) for:
- Complete submission requirements
- Testing checklist
- Metadata templates
- Post-launch planning

See [APP_ICON_GUIDE.md](APP_ICON_GUIDE.md) for:
- Required icon sizes
- Design recommendations
- Creation tools
- Testing guidelines

## 🏪 App Store Readiness

### ✅ Completed
- [x] All compilation errors fixed
- [x] Core gameplay fully functional
- [x] Save/load system implemented
- [x] Tutorial and help system
- [x] Settings and customization
- [x] Full accessibility support
- [x] Comprehensive unit tests
- [x] No data collection (privacy-friendly)

### 📋 Before Submission
- [ ] Create and add app icons (all sizes)
- [ ] Test on multiple physical devices
- [ ] Create App Store screenshots
- [ ] Write App Store description
- [ ] Set up App Store Connect listing
- [ ] Beta test with TestFlight
- [ ] Create privacy policy page
- [ ] Set up support contact

**Status**: Ready for beta testing! Needs app icon and metadata before App Store submission.

## 🤝 Contributing

This is a learning project, but suggestions and improvements are welcome!

## 📝 License

This project is for educational and entertainment purposes.

## 🎉 Credits

Built with SwiftUI and ❤️  
Created: January 2026

---

**Ready to Run for Office?** Open the project in Xcode and start your campaign! 🇺🇸
