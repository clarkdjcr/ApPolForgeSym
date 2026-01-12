# Campaign Manager 2026 - Game Design Document

## Overview
A turn-based strategy game where two players (or Player vs AI) compete in a fictionalized presidential election. One player represents the Incumbent Party, the other represents the Challenger Party.

## Core Gameplay Loop

### Turn Structure
- **20 Turns Total**: Each turn represents one week leading up to Election Day
- **Turn Order**: Incumbent goes first, then Challenger
- **Actions Per Turn**: Each player takes one action per turn

### Win Condition
At the end of 20 weeks, the player with 270+ electoral votes wins the presidency.

## Game Systems

### 1. Resources
Each player manages three key resources:

#### Campaign Funds
- Starting: $15M (Incumbent) / $12M (Challenger)
- Used to: Execute campaign actions
- Replenished by: Fundraiser actions

#### Momentum
- Range: -100 to +100
- Affects: Effectiveness of actions and event resistance
- Influenced by: Actions, events, and polling trends

#### National Polling
- Range: 0% to 100%
- Represents: Overall national support
- Influenced by: Actions, events, and state-level performance

### 2. Electoral Map
The game features a simplified electoral map with:
- **14 States** representing key battlegrounds and strongholds
- **538 Total Electoral Votes** distributed among states
- **State-Level Polling** tracking support for each candidate

#### State Types
- **Battleground States**: Margins within 10 points (contested)
- **Safe States**: Margins over 10 points (likely winner)

#### State Metrics
- **Incumbent Support**: Percentage supporting incumbent
- **Challenger Support**: Percentage supporting challenger
- **Undecided**: Remaining voters (100 - both supports)
- **Electoral Votes**: Winner-take-all in each state

### 3. Campaign Actions
Seven distinct action types with different costs and effects:

#### Rally ($500K)
- **Effect**: Boosts momentum and state support
- **Target**: Specific state
- **Best for**: Energizing base voters
- **Impact**: +1-4% state support, +2-5 momentum

#### Ad Campaign ($2M)
- **Effect**: Major polling impact in target state
- **Target**: Specific state
- **Best for**: Moving polling numbers quickly
- **Impact**: +2-6% state support

#### Fundraiser ($100K)
- **Effect**: Replenishes campaign funds
- **Target**: National
- **Best for**: Building war chest
- **Impact**: +$1M-3M campaign funds

#### Town Hall ($250K)
- **Effect**: Improves favorability and undecided voters
- **Target**: Specific state
- **Best for**: Connecting with voters personally
- **Impact**: +1-3% state support, +0.5% national polling

#### Debate Prep ($750K)
- **Effect**: Increases debate performance potential
- **Target**: National
- **Best for**: Preparing for key moments
- **Impact**: +3-8 momentum

#### Grassroots Organizing ($300K)
- **Effect**: Long-term support building
- **Target**: Specific state
- **Best for**: Building sustainable ground game
- **Impact**: +1-2% state support (reliable but modest)

#### Opposition Research ($1M)
- **Effect**: Damages opponent's support
- **Target**: National (affects opponent)
- **Best for**: Going negative
- **Impact**: -0.5-2% opponent national polling, -3-8 opponent momentum

### 4. Random Events
40% chance per turn of a random event occurring.

#### Event Types
1. **Scandal**: Campaign controversy emerges
2. **Economic News**: Economic indicators shift
3. **Endorsement**: Major figure announces support
4. **Gaffe**: Candidate makes controversial statement
5. **National Crisis**: Sudden crisis tests leadership
6. **Viral Moment**: Campaign moment captures attention

#### Event Effects
- **Impact Magnitude**: -30 to +30 points
- **Target**: Can affect Incumbent, Challenger, or both
- **Visibility**: Last 5 events displayed in Events feed
- **Unpredictability**: Creates volatility and excitement

## AI Opponent Strategy

The AI uses four strategic modes:

### 1. Aggressive Strategy
- **When**: Losing badly (50+ electoral votes behind)
- **Actions**: Ad campaigns, rallies, opposition research
- **Targets**: Swing states and weak incumbent states
- **Goal**: Make up ground quickly

### 2. Defensive Strategy
- **When**: Winning by large margin (50+ electoral votes ahead)
- **Actions**: Town halls, grassroots organizing
- **Targets**: States with narrow leads
- **Goal**: Protect current advantages

### 3. Balanced Strategy
- **When**: Race is close
- **Actions**: Mix of all action types
- **Targets**: Battleground states
- **Goal**: Maintain competitiveness everywhere

### 4. Fundraising Strategy
- **When**: Low on funds (<$2M)
- **Actions**: Prioritize fundraisers
- **Goal**: Replenish resources for future turns

## User Interface

### Setup Screen
- Displays both candidates
- Shows starting statistics
- Initiates campaign

### Game Screen (3 Tabs)

#### Map Tab
- Lists all states with current polling
- Visual polling bars (Blue/Red/Gray)
- Electoral vote counts
- Battleground vs. safe state indicators

#### Actions Tab
- Current resources display
- Available actions with costs
- Action execution interface
- State selection when needed

#### Events Tab
- Recent event feed (last 5 events)
- Event details and impacts
- Turn tracking for events

### Results Screen
- Final electoral vote count
- Winner announcement
- Option to start new campaign

## Game Balance

### Resource Management
- Actions have meaningful tradeoffs
- Expensive actions (Ad Campaign, Opposition Research) have bigger impact
- Cheap actions (Grassroots, Rally) allow frequency
- Fundraising prevents total depletion

### Strategic Depth
- State targeting matters (high EV vs. winnable states)
- Timing is important (early momentum vs. late push)
- Risk/reward in going negative
- Adaptability to random events

### Volatility
- 40% event rate keeps games dynamic
- Events have moderate impact (not game-breaking)
- Multiple paths to victory
- Comeback potential maintained throughout

## Future Enhancement Ideas

### Immediate Additions
1. **Debate Events**: Special turns with head-to-head competition
2. **VP Selection**: Choose running mate with strategic benefits
3. **Issue Positions**: Take stances that affect different voter groups
4. **Media Coverage**: Track favorability with different news outlets

### Medium-Term Features
1. **Multiplayer**: Hot-seat or online multiplayer
2. **Difficulty Levels**: Adjust AI aggression and starting advantages
3. **Historical Scenarios**: Play famous elections with real candidates
4. **Custom Candidates**: Create your own candidates and parties
5. **Save/Load Games**: Persist game state between sessions

### Advanced Systems
1. **Demographic Groups**: Target specific voter coalitions
2. **Ground Game**: Persistent state-level infrastructure
3. **Super PACs**: Independent expenditure groups
4. **Primary Season**: Win your party's nomination first
5. **Congressional Races**: Down-ballot effects

## Technical Implementation

### Architecture
- **SwiftUI**: Modern declarative UI
- **Observable Objects**: Reactive state management
- **Async/Await**: AI turn processing
- **Value Types**: Immutable game state where possible

### Data Models
- `Player`: Represents each candidate
- `ElectoralState`: Individual state data
- `CampaignAction`: Player actions
- `GameEvent`: Random events
- `GameState`: Central observable game controller
- `AIOpponent`: AI decision-making logic

### Key Design Patterns
- **MVVM**: Views observe GameState
- **Strategy Pattern**: AI uses different strategies
- **Command Pattern**: Actions encapsulate behaviors
- **Observer Pattern**: State changes trigger UI updates

## Credits
Built with SwiftUI for iOS and iPadOS
Created January 2026
