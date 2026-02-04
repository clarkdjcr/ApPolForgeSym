# Campaign Manager 2026

A deep strategic turn-based presidential election simulation for macOS, iOS, iPadOS, and visionOS built with SwiftUI.

## Game Overview

Take control of either the **Incumbent Party** or **Challenger Party** in a high-stakes race for the presidency. Manage campaign funds totaling hundreds of millions of dollars, execute strategic actions across all 50 states plus DC, navigate unpredictable events, and decide whether to engage in covert operations that could win—or destroy—your campaign.

## How to Win

Secure **270 or more electoral votes** out of 538 total by winning individual states through strategic campaign actions over 20 intense weeks leading up to Election Day.

---

## Core Features

### Strategic Gameplay

#### Complete U.S. Electoral Map
- **51 Jurisdictions**: All 50 states plus Washington D.C.
- **538 Electoral Votes**: Authentic electoral vote distribution
- **Real Campaign Data**: Historical voting patterns, media market costs, and regional characteristics
- **Competitiveness Tiers**: States ranked from Battleground (Tier 1) to Safe (Tier 4)

#### Multi-Action Turn System
- **Variable Actions Per Turn**: Earn 1-4 actions based on momentum and game position
- **Strategic Flexibility**: Execute multiple campaign actions in a single turn
- **Cost Scaling**: Additional states in multi-state actions cost 20% more each

#### Resource Management
- **Campaign Funds**: Starting war chest scales with difficulty; manage burn rate carefully
- **Momentum**: -100 to +100 scale affecting action effectiveness and actions per turn
- **National Polling**: Overall support percentage influencing voter sentiment
- **Infrastructure**: Staff, volunteers, and field offices tracked per state

---

### Campaign Actions (7 Types)

| Action | Cost | Target | Effect |
|--------|------|--------|--------|
| **Rally** | $500K | State | Energize supporters, boost momentum and state support |
| **Ad Campaign** | $2M | State | Major polling impact through media saturation |
| **Fundraiser** | $100K | National | Replenish campaign war chest (+$1-3M return) |
| **Town Hall** | $250K | State | Connect with undecided voters, improve favorability |
| **Debate Prep** | $750K | National | Increase debate performance, boost momentum |
| **Grassroots Organizing** | $300K | State | Build long-term ground game infrastructure |
| **Opposition Research** | $1M | National | Damage opponent's polling and momentum |

**Multi-State Targeting**: Most actions can target multiple states simultaneously with cost scaling.

---

### Shadow Budget System ("Nixon Disease")

Navigate the ethical gray zones of modern campaigns with a sophisticated covert operations system:

#### Budget Allocation Zones
- **Green Zone (0-5%)**: Transparent operations—maintain integrity bonuses
- **Yellow Zone (6-15%)**: Aggressive tactics—morally gray territory
- **Red Zone (16-30%)**: Black ops/espionage—high risk, high reward

#### Shadow Operations (5 Types)
| Operation | Cost | Risk | Effect |
|-----------|------|------|--------|
| **Data Theft** | $5M | 25% | Steal opponent's voter data |
| **Technical Sabotage** | $3M | 20% | Disrupt opponent's campaign operations |
| **Opposition Dirt** | $4M | 15% | Uncover damaging information |
| **Voter Suppression** | $6M | 35% | Suppress turnout in opponent's states |
| **Media Manipulation** | $3.5M | 12% | Plant negative stories |

#### Risk & Reward Mechanics
- **Detection System**: Each operation has base detection risk (12-35%)
- **Shell Company Layers**: Spend 2x base cost to reduce detection by 50%
- **Integrity Bonuses**: 3+ turns in green zone grants:
  - 20% fundraising multiplier
  - Teflon Shield (scandal resistance)
  - Reputation boost
- **Scandal Consequences**: Detection triggers scandals with:
  - Polling impact: -5 to -30 points
  - Funding freeze: 1-4 turns
  - Potential campaign-ending exposure

#### AI Spy Personalities
The AI opponent has distinct shadow budget behaviors:
- **The Moralist**: Stays under 5%, plays victim if caught
- **The Machiavellian**: Spikes to 30% at critical moments
- **The Cautious**: Consistent 8-12% allocation
- **The Reckless**: Frequent 20%+ allocation

---

### Dynamic Events System

40% chance per turn of game-changing random events:

| Event Type | Description | Potential Impact |
|------------|-------------|------------------|
| **Scandal** | Campaign controversy emerges | -10 to -30 polling |
| **Economic News** | Economic indicators shift | Variable |
| **Endorsement** | Major figure announces support | +5 to +15 polling |
| **Campaign Gaffe** | Candidate makes controversial statement | -5 to -15 momentum |
| **National Crisis** | Sudden crisis tests leadership | High volatility |
| **Viral Moment** | Campaign moment captures attention | +5 to +20 momentum |

Events create unpredictability and require adaptive strategy.

---

### AI-Powered Strategic Advisor

Built-in campaign analytics dashboard providing:

#### Electoral Analysis
- **Secure States**: Commanding leads (likely wins)
- **Likely States**: Probable victories
- **Leaning States**: Slight advantages
- **Tossup States**: Competitive battlegrounds
- **Multiple Paths to 270**: Strategic victory scenarios

#### Financial Projections
- Current funds and burn rate analysis
- Projected endgame funds
- Funding alerts for shortfalls
- Weeks of runway remaining

#### Strategic Recommendations
Prioritized action suggestions with:
- **Priority Levels**: Critical, High, Medium, Low
- **Recommendation Types**: Defensive, Offensive, Infrastructure, Fundraising, Momentum
- **State-by-State Analysis**: Infrastructure gaps and opportunities

#### Infrastructure Tracking
- Recommended vs. actual staffing levels
- Volunteer recruitment progress
- Field office coverage
- Efficiency scoring (0.0-1.0+ scale)

---

### AI Opponent

Adaptive AI with 5 strategy modes and 4 difficulty levels:

#### AI Strategies
| Strategy | Trigger | Behavior |
|----------|---------|----------|
| **Aggressive** | Losing badly | All-in on swing states, shadow ops |
| **Defensive** | Winning big | Protect leads, build infrastructure |
| **Balanced** | Close race | Strategic mix across battlegrounds |
| **Fundraising** | Low funds | Prioritize war chest replenishment |
| **MultiState** | Strong position | Efficient multi-state actions |

#### Difficulty Levels
- **Easy**: Basic decisions, sometimes inefficient
- **Medium**: Balanced strategy (default)
- **Hard**: Smart, competitive decisions
- **Expert**: Ruthless efficiency, maximum challenge

---

### Game Features

#### Save/Load System
- **Auto-Save**: Automatic saves after each turn
- **Manual Save**: Save anytime during gameplay
- **Save Metadata**: Track progress, turn number, candidates
- **Continue Prompt**: Resume last game on launch

#### Tutorial System
7-page interactive tutorial covering:
1. Win conditions (270 electoral votes)
2. Time limit (20 weeks)
3. Resource management
4. Campaign actions (all 7 types)
5. Battleground state targeting
6. Dynamic events system
7. Strategic dashboard features

#### User Experience
- **Haptic Feedback**: Tactile responses for immersive gameplay
- **Share Results**: Share election victories
- **Settings**: Customize sound, haptics, AI speed
- **Clean SwiftUI Interface**: Modern, intuitive design

#### Accessibility
- **VoiceOver Support**: Full screen reader compatibility
- **Dynamic Type**: Text scales with system settings
- **High Contrast**: Readable in all conditions
- **Comprehensive Labels**: Descriptive accessibility throughout

---

## How to Play

### Getting Started
1. **Launch the app** and view the tutorial (recommended for first-time players)
2. **Choose your side**: Incumbent or Challenger party
3. **Select difficulty**: Easy, Medium, Hard, or Expert
4. **Begin your campaign** with your starting war chest

### Turn Structure
1. **Review the map**: Check state-by-state polling and electoral vote projections
2. **Check your resources**: Funds, momentum, national polling
3. **Consult the Strategic Advisor**: Review recommendations and analytics
4. **Execute actions**: Use your 1-4 available actions strategically
5. **Manage Shadow Budget** (optional): Allocate covert operations budget
6. **End turn**: AI opponent takes their turn, events may occur

### Strategy Tips

#### Early Game (Weeks 1-7)
- Build your war chest with fundraisers
- Establish ground game in key battleground states
- Stay in the green zone to build integrity bonuses
- React quickly to early events

#### Mid Game (Weeks 8-14)
- Focus ad campaigns on battleground states
- Use debate prep before key moments
- Consider calculated shadow operations if behind
- Track multiple paths to 270

#### Late Game (Weeks 15-20)
- Go all-in on must-win states
- Calculate exact electoral paths needed
- Use opposition research sparingly but strategically
- Protect narrow leads in critical states

### Winning Strategies
1. **Resource Awareness**: Never run out of funds—maintain runway
2. **Battleground Focus**: States within 10 points are most efficient targets
3. **Timing**: Save expensive moves for critical moments
4. **Adaptability**: Respond quickly to events and opponent moves
5. **Risk Assessment**: Shadow ops can win or lose the election

---

## Technical Requirements

### Supported Platforms
- macOS 15.0+
- iOS 17.0+ / iPadOS 17.0+
- visionOS 2.0+

### Development Requirements
- Xcode 15.0+
- Swift 5.9+

### Installation
1. Open `ApPolForgeSym.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press **Cmd+R** to build and run

---

## File Structure

```
ApPolForgeSym/
├── ApPolForgeSymApp.swift        # App entry point
├── ContentView.swift             # Main UI views and game flow
├── ModelsGameModels.swift        # Core game data models
├── EnhancedGameModels.swift      # Advanced analytics models
├── CampaignData.json             # 51-state campaign data
├── CampaignDataLoader.swift      # Data loading system
├── ShadowBudgetModels.swift      # Shadow operations system
├── ShadowBudgetManager.swift     # Covert ops logic
├── ShadowBudgetView.swift        # Shadow budget UI
├── StrategicAdvisor.swift        # AI advisor and analytics
├── StrategicDashboardView.swift  # Analytics dashboard UI
├── AIOpponent.swift              # AI strategy system
├── Persistence.swift             # Save/load functionality
├── TutorialView.swift            # Tutorial system
├── SettingsView.swift            # User settings
├── HapticsManager.swift          # Haptic feedback
└── AccessibilityExtensions.swift # Accessibility support
```

---

## Educational Value

Learn about:
- The Electoral College system and paths to 270
- Campaign finance dynamics and resource allocation
- Swing state strategy and battleground targeting
- Political event impacts and crisis management
- Risk vs. reward decision-making
- Ethical boundaries in political campaigns

---

## Credits

Built with SwiftUI
Created: January 2026
Updated: February 2026

---

**Ready to Run for Office?** Launch the app and start your campaign for the presidency!
