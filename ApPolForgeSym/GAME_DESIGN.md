# Campaign Manager 2026 - Game Design Document

## Overview

A turn-based strategy game where you compete against an AI opponent in a fictionalized presidential election. Play as either the Incumbent Party or Challenger Party, managing resources, executing campaign actions, and navigating the ethical gray zones of modern politics.

---

## Core Gameplay Loop

### Turn Structure
- **20 Turns Total**: Each turn represents one week leading up to Election Day
- **Turn Order**: Player acts first, then AI opponent responds
- **Actions Per Turn**: 1-4 actions based on momentum and game position
  - Base: 1 action
  - Momentum > 20: +1 action
  - Momentum > 40: +1 action (total 3)
  - Momentum > 60: +1 action (total 4)

### Win Condition
At the end of 20 weeks, the player with **270+ electoral votes** wins the presidency.

---

## Game Systems

### 1. Resources

Each player manages four key resources:

#### Campaign Funds
- **Starting Amount**: Scales with difficulty level
- **Uses**: Execute campaign actions, shadow operations
- **Replenishment**: Fundraiser actions, integrity bonuses
- **Burn Rate**: Tracked in Strategic Advisor dashboard

#### Momentum
- **Range**: -100 to +100
- **Affects**:
  - Number of actions per turn
  - Effectiveness of campaign actions
  - Event resistance
- **Influenced by**: Actions, events, and relative position

#### National Polling
- **Range**: 0% to 100%
- **Represents**: Overall national support
- **Influenced by**: Actions, events, state-level performance

#### Infrastructure (Per State)
- **Staff**: Campaign employees in each state
- **Volunteers**: Grassroots supporters
- **Efficiency Score**: 0.0 to 1.0+ based on recommended vs. actual levels

---

### 2. Electoral Map

#### Complete U.S. Coverage
- **51 Jurisdictions**: All 50 states plus Washington D.C.
- **538 Total Electoral Votes**: Authentic distribution
- **Real Campaign Data**: Each state includes:
  - Historical voting margins (2008-2020)
  - Regional classification (Northeast, Southeast, Midwest, Southwest, West, Pacific)
  - Media market cost index
  - Action effectiveness ratings
  - Weekly staffing targets
  - Volunteer goals

#### Competitiveness Tiers
| Tier | Classification | Effectiveness Multiplier |
|------|----------------|-------------------------|
| 1 | Battleground | 1.4x |
| 2 | Competitive | 1.2x |
| 3 | Lean | 0.9x |
| 4 | Safe | 0.6x |

#### State Metrics
- **Incumbent Support**: Percentage supporting incumbent (0-100%)
- **Challenger Support**: Percentage supporting challenger (0-100%)
- **Undecided**: Remaining voters (100 - both supports)
- **Electoral Votes**: Winner-take-all in each state
- **Battleground Status**: Within 10 points = battleground

---

### 3. Campaign Actions

Seven distinct action types with different costs, targets, and effects:

#### Rally ($500K)
- **Target**: Specific state(s)
- **Effect**: Energize base voters, boost momentum
- **Impact**: +1-4% state support, +2-5 momentum
- **Best For**: Building enthusiasm in key states

#### Ad Campaign ($2M)
- **Target**: Specific state(s)
- **Effect**: Major polling impact through media saturation
- **Impact**: +2-6% state support
- **Best For**: Moving numbers quickly in critical states
- **Note**: Costs scale by state media market index

#### Fundraiser ($100K)
- **Target**: National
- **Effect**: Replenish campaign funds
- **Impact**: +$1-3M campaign funds
- **Bonus**: +20% with integrity bonus active
- **Best For**: Maintaining financial runway

#### Town Hall ($250K)
- **Target**: Specific state(s)
- **Effect**: Connect with undecided voters
- **Impact**: +1-3% state support, +0.5% national polling
- **Best For**: Converting undecided voters

#### Debate Prep ($750K)
- **Target**: National
- **Effect**: Prepare for strong debate performance
- **Impact**: +3-8 momentum
- **Best For**: Building momentum before key moments

#### Grassroots Organizing ($300K)
- **Target**: Specific state(s)
- **Effect**: Build sustainable ground game
- **Impact**: +1-2% state support (reliable)
- **Bonus**: Improves infrastructure score
- **Best For**: Long-term state building

#### Opposition Research ($1M)
- **Target**: National (affects opponent)
- **Effect**: Damages opponent's support
- **Impact**: -0.5-2% opponent polling, -3-8 opponent momentum
- **Best For**: Going negative strategically

#### Multi-State Targeting
- Most state-targeted actions can hit multiple states
- **Cost Scaling**: +20% per additional state
- **Strategic Use**: Efficient when momentum is high

---

### 4. Shadow Budget System

Navigate the ethical gray zones with a sophisticated covert operations system.

#### Budget Allocation Zones

| Zone | Range | Risk Level | Description |
|------|-------|------------|-------------|
| **Green** | 0-5% | Minimal | Transparent operations |
| **Yellow** | 6-15% | Moderate | Aggressive tactics |
| **Red** | 16-30% | High | Black ops/espionage |

#### Shadow Operations

| Operation | Base Cost | Detection Risk | Effect |
|-----------|-----------|----------------|--------|
| **Data Theft** | $5M | 25% | Steal opponent's voter data |
| **Technical Sabotage** | $3M | 20% | Disrupt opponent's operations |
| **Opposition Dirt** | $4M | 15% | Uncover damaging information |
| **Voter Suppression** | $6M | 35% | Suppress turnout in opponent states |
| **Media Manipulation** | $3.5M | 12% | Plant negative stories |

#### Detection & Consequences

**Detection Modifiers:**
- Base risk varies by operation (12-35%)
- Shell company layers: 2x cost = -50% detection risk
- Additional layers possible for further reduction

**Scandal Severity Levels:**
| Level | Polling Impact | Funding Freeze | Additional Effects |
|-------|----------------|----------------|-------------------|
| Minor | -5 to -10 | 1 turn | Reputation damage |
| Major | -15 to -20 | 2-3 turns | Media scrutiny |
| Campaign-Ending | -25 to -30 | 4 turns | Potential disqualification |

**Denial System:**
- Attempt to deny scandal: 30% base success rate
- Modified by integrity score
- Failed denial worsens scandal

#### Integrity Bonuses (Green Zone Rewards)

3+ consecutive turns in green zone grants:
- **Fundraising Bonus**: +20% on all fundraiser returns
- **Teflon Shield**: Reduced scandal impact
- **Reputation Boost**: Improved event outcomes

---

### 5. Dynamic Events

40% chance per turn of a random event occurring.

#### Event Types

| Type | Description | Impact Range |
|------|-------------|--------------|
| **Scandal** | Campaign controversy emerges | -10 to -30 polling |
| **Economic News** | Economic indicators shift | Variable |
| **Endorsement** | Major figure announces support | +5 to +15 polling |
| **Gaffe** | Candidate makes controversial statement | -5 to -15 momentum |
| **National Crisis** | Sudden crisis tests leadership | High volatility |
| **Viral Moment** | Campaign moment captures attention | +5 to +20 momentum |

#### Event Mechanics
- **Target**: Can affect Incumbent, Challenger, or both
- **Visibility**: Last 5 events displayed in feed
- **Shadow Integration**: Detected operations auto-generate scandal events

---

### 6. AI Opponent

#### Strategy Modes

| Strategy | Trigger Condition | Behavior |
|----------|-------------------|----------|
| **Aggressive** | 50+ EV behind | All-in on swing states, heavy shadow ops |
| **Defensive** | 50+ EV ahead | Protect leads, infrastructure building |
| **Balanced** | Close race | Strategic mix across battlegrounds |
| **Fundraising** | Funds < threshold | Prioritize war chest |
| **MultiState** | Strong momentum | Efficient multi-state actions |

#### Difficulty Levels

| Level | Description | AI Behavior |
|-------|-------------|-------------|
| **Easy** | Forgiving | Basic decisions, sometimes inefficient |
| **Medium** | Balanced | Strategic but beatable (default) |
| **Hard** | Challenging | Smart, competitive decisions |
| **Expert** | Ruthless | Maximum efficiency, exploits weaknesses |

#### AI Shadow Personalities

| Personality | Allocation Style | Behavior Pattern |
|-------------|------------------|------------------|
| **The Moralist** | < 5% | Stays clean, plays victim if accused |
| **The Machiavellian** | Spikes to 30% | Goes all-in at critical moments |
| **The Cautious** | 8-12% steady | Consistent moderate risk |
| **The Reckless** | 20%+ frequent | High risk tolerance |

---

## User Interface

### Setup Screen
- Party selection (Incumbent/Challenger)
- Difficulty selection
- Tutorial access
- Continue saved game prompt

### Game Screen (Tabbed Interface)

#### Map Tab
- Full state list with polling bars
- Electoral vote counts per state
- Battleground indicators
- Current electoral vote projection

#### Actions Tab
- Resource display (funds, momentum, polling)
- Action selection with costs
- State targeting interface
- Multi-state selection
- Action execution confirmation

#### Strategic Advisor Tab
- Electoral analysis (Secure/Likely/Leaning/Tossup)
- Financial projections and burn rate
- Strategic recommendations with priorities
- Infrastructure tracking per state
- Paths to 270 visualization

#### Shadow Budget Tab
- Budget allocation slider (0-30%)
- Zone indicator (Green/Yellow/Red)
- Operation selection
- Shell company options
- Active operation status
- Scandal management

#### Events Tab
- Recent event feed
- Event details and impacts
- Turn tracking

### Results Screen
- Final electoral vote map
- Winner announcement
- Victory/defeat breakdown
- Share results option
- New game option

---

## Game Balance

### Resource Tension
- Expensive actions have bigger impact but drain funds
- Cheap actions allow frequency but smaller gains
- Shadow ops offer shortcuts with severe risk
- Fundraising creates opportunity cost

### Strategic Depth
- State targeting: High EV vs. winnable states
- Timing: Early investment vs. late push
- Risk management: Integrity vs. shadow ops
- Adaptability: Responding to events and opponent

### Volatility Management
- 40% event rate maintains dynamism
- Events have moderate impact (not game-breaking)
- Multiple paths to victory remain viable
- Comeback potential through strategic shadow ops

---

## Technical Implementation

### Architecture
- **SwiftUI**: Modern declarative UI
- **Observable Objects**: Reactive state management
- **Async/Await**: AI turn processing
- **JSON**: Campaign data and save files

### Data Models
- `Player`: Candidate resources and state
- `ElectoralState`: Per-state polling and data
- `CampaignActionType`: Action definitions
- `GameEvent`: Random event system
- `GameState`: Central game controller
- `ShadowBudgetState`: Covert operations tracking
- `CampaignAnalytics`: Strategic advisor data
- `AIOpponent`: AI decision logic

### Key Design Patterns
- **MVVM**: Views observe GameState
- **Strategy Pattern**: AI mode selection
- **Command Pattern**: Action execution
- **Observer Pattern**: Reactive UI updates

---

## Version History

- **v1.0**: Initial release with 14 states, single action turns
- **v1.1**: Shadow Budget system added
- **v1.2**: Strategic Advisor dashboard
- **v2.0**: Expanded to 51 states with real campaign data
- **v2.1**: Multi-action turn system
- **v2.2**: Difficulty levels and AI personalities

---

## Credits

Built with SwiftUI for macOS, iOS, iPadOS, and visionOS
Created: January 2026
Updated: February 2026
