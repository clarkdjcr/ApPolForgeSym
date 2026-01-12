//
//  ExampleScenarios.swift
//  ApPolForgeSym
//
//  Example scenarios showing how strategic recommendations adapt to game state
//

import Foundation

/*
 
 EXAMPLE SCENARIOS - Strategic Recommendations in Action
 ========================================================
 
 These examples show how the AI Strategic Advisor responds to different campaign situations.
 
 
 SCENARIO 1: Early Game - Building Infrastructure
 -------------------------------------------------
 
 Turn: Week 3/20
 Your Status: Incumbent, 223 Electoral Votes (secure + likely)
 Opponent: 198 Electoral Votes
 Your Funds: $180M
 
 RECOMMENDATION GENERATED:
 
 Type: Infrastructure
 Priority: High
 Title: "Build Ground Game"
 Description: "Your field organization is weak in 2 battleground states"
 Target States: Pennsylvania (20 EV), Michigan (16 EV)
 Suggested Actions: Grassroots Organizing, Town Hall
 Estimated Cost: $1.6M
 Expected Impact: "Improved turnout and long-term support"
 Reasoning: "Infrastructure score is below 60%. Building field offices 
             and recruiting volunteers will pay off."
 
 WHY THIS MAKES SENSE:
 - Early in campaign (still time to build organization)
 - Affordable ($1.6M out of $180M budget)
 - Targets states you need to win
 - Grassroots work has compounding effects over time
 
 
 SCENARIO 2: Mid Game - Defensive Play
 --------------------------------------
 
 Turn: Week 10/20
 Your Status: Challenger, 265 Electoral Votes
 Opponent: 273 Electoral Votes
 Your Funds: $95M
 
 States You're Winning Narrowly:
 - Florida: You +3.2%, 29 EV
 - Arizona: You +2.8%, 11 EV
 - Nevada: You +4.1%, 6 EV
 
 RECOMMENDATION GENERATED:
 
 Type: Defensive
 Priority: CRITICAL
 Title: "Shore Up Vulnerable States"
 Description: "You're leading in 3 key states but margins are thin"
 Target States: Florida, Arizona, Nevada (46 total EV)
 Suggested Actions: Grassroots, Town Hall, Ad Campaign
 Estimated Cost: $6M
 Expected Impact: "Secure 46 electoral votes"
 Reasoning: "These states have narrow margins (<7 points). Grassroots 
             organizing and town halls will solidify support."
 
 WHY THIS MAKES SENSE:
 - You're at 265 EV - need these 3 states to win
 - Margins are thin (under 5 points in FL and AZ)
 - Losing any of these states means you lose the election
 - Critical priority reflects the stakes
 
 PLAYER SHOULD:
 ✓ Execute multi-state town halls in all 3 states
 ✓ Follow up with grassroots organizing
 ✓ Monitor these states every turn
 ✗ Don't waste time on offensive plays yet - secure these first
 
 
 SCENARIO 3: Late Game - Path to Victory
 ----------------------------------------
 
 Turn: Week 17/20
 Your Status: Incumbent, 254 Electoral Votes (secure + likely + leaning)
 Opponent: 284 Electoral Votes
 Your Funds: $42M
 
 States You're Losing Narrowly:
 - Georgia: Them +4.1%, 16 EV → Would give you 270!
 - Wisconsin: Them +6.8%, 10 EV
 - North Carolina: Them +7.2%, 15 EV
 
 RECOMMENDATION GENERATED:
 
 Type: Offensive
 Priority: CRITICAL
 Title: "Flip Competitive States"
 Description: "Target 1 winnable state worth 16 electoral votes"
 Target States: Georgia (16 EV)
 Suggested Actions: Rally, Ad Campaign, Town Hall
 Estimated Cost: $2.5M
 Expected Impact: "Potential to gain 16 electoral votes - WINNING PATH"
 Reasoning: "You're within striking distance (<8 points behind). 
             Rallies and ad campaigns can close the gap. This state 
             alone gets you to 270."
 
 WHY THIS MAKES SENSE:
 - Only 3 weeks left - need to focus
 - Georgia alone gets you from 254 to 270 = WIN
 - Within 5 points = flippable
 - Have enough funds for big push
 
 PLAYER SHOULD:
 ✓ All-in on Georgia with multi-state actions
 ✓ Execute rally + ad campaign immediately
 ✓ Follow up with town halls
 ✓ Ignore other states - this is the path
 ✗ Don't spread resources thin
 
 
 SCENARIO 4: Financial Crisis
 -----------------------------
 
 Turn: Week 13/20
 Your Status: Challenger, 241 Electoral Votes
 Opponent: 297 Electoral Votes
 Your Funds: $4.2M ⚠️
 
 Projected Funds at Election Day: -$6.5M ⚠️⚠️
 Burn Rate: $1.5M/week
 
 RECOMMENDATION GENERATED:
 
 Type: Fundraising
 Priority: CRITICAL
 Title: "Replenish Campaign Funds"
 Description: "Treasury is running low at $4.2M. Fundraising needed."
 Target States: (none - national action)
 Suggested Actions: Fundraiser
 Estimated Cost: $100K
 Expected Impact: "Raise $1-3M to continue operations"
 Reasoning: "Current funds won't sustain campaign through election. 
             Hold multiple fundraisers."
 
 ALERT DISPLAYED:
 "⚠️ Campaign will run out of money before Election Day"
 
 WHY THIS MAKES SENSE:
 - Running out of money = can't execute any actions
 - Better to fundraise now than be broke later
 - Even though behind in EV, need resources to catch up
 
 PLAYER SHOULD:
 ✓ Do 2-3 fundraisers immediately
 ✓ Rebuild war chest to ~$15-20M
 ✓ Then return to competitive actions
 ✗ Don't ignore this - you'll be unable to act
 
 
 SCENARIO 5: Momentum Shift Needed
 ----------------------------------
 
 Turn: Week 8/20
 Your Status: Challenger, 188 Electoral Votes
 Opponent: 350 Electoral Votes
 Your Funds: $125M
 Your Momentum: -15
 National Polling: 42% vs 52%
 
 RECOMMENDATION GENERATED:
 
 Type: Momentum
 Priority: CRITICAL
 Title: "Change Campaign Narrative"
 Description: "You're down 162 electoral votes. Need to shift momentum."
 Target States: (none - national impact)
 Suggested Actions: Debate Prep, Opposition Research, Rally
 Estimated Cost: $2M
 Expected Impact: "Boost national profile and momentum"
 Reasoning: "Facing significant deficit. Debate prep and opposition 
             research can change the race dynamics."
 
 WHY THIS MAKES SENSE:
 - Down by 162 EV = losing badly
 - State-by-state tactics won't fix this
 - Need national narrative change
 - Have plenty of money for big moves
 
 PLAYER SHOULD:
 ✓ Opposition research on opponent (damage their numbers)
 ✓ Debate prep (boost your momentum)
 ✓ National rallies for media coverage
 ✓ Wait for events to shift race
 ✗ Don't focus only on small state gains
 
 
 SCENARIO 6: Perfect Position
 -----------------------------
 
 Turn: Week 15/20
 Your Status: Incumbent, 312 Electoral Votes
 Opponent: 226 Electoral Votes
 Your Funds: $88M
 Infrastructure: 75%+ in all battleground states
 
 RECOMMENDATION GENERATED:
 
 Type: Defensive
 Priority: Medium
 Title: "Maintain Leads in Key States"
 Description: "You're in strong position. Light defensive work recommended."
 Target States: (a few close states)
 Suggested Actions: Town Hall, Grassroots
 Estimated Cost: $1M
 Expected Impact: "Maintain winning position"
 Reasoning: "Strong lead and good infrastructure. Just maintain course."
 
 WHY THIS MAKES SENSE:
 - Already over 270 EV
 - Well-funded
 - Strong organization
 - Just need to avoid mistakes
 
 PLAYER SHOULD:
 ✓ Light defensive plays
 ✓ Maybe one more fundraiser for cushion
 ✓ Don't do anything risky
 ✗ Don't overspend - already winning
 
 
 HOW THE AI PRIORITIZES
 ----------------------
 
 The Strategic Advisor checks in this order:
 
 1. Financial viability (will you run out of money?)
    → If yes: CRITICAL fundraising recommendation
 
 2. Defensive needs (protecting narrow wins)
    → If states <7 point margins: HIGH/CRITICAL defensive
 
 3. Offensive opportunities (flippable states)
    → If states within 8 points: HIGH offensive
 
 4. Infrastructure gaps (poor ground game)
    → If battleground <60% score: HIGH infrastructure
 
 5. Overall momentum (race dynamics)
    → If down 50+ EV: CRITICAL momentum
 
 Priority levels:
 - CRITICAL: Act now or face major consequences
 - HIGH: Strong recommendation, act soon
 - MEDIUM: Good idea if you have resources
 - LOW: Optional, nice to have
 
 
 REAL GAMEPLAY TIPS
 ------------------
 
 Early Game (Weeks 1-7):
 - Follow infrastructure recommendations religiously
 - Build ground game in battlegrounds
 - Fundraise to build war chest
 - Strategy: Long-term investment
 
 Mid Game (Weeks 8-14):
 - Balance offensive and defensive plays
 - Follow recommendations but use judgment
 - Start focusing on paths to 270
 - Strategy: Positioning for endgame
 
 Late Game (Weeks 15-20):
 - ONLY act on critical recommendations
 - Focus exclusively on path to 270
 - Use multi-state coordination
 - Ignore "nice to have" advice
 - Strategy: Laser focus on winning
 
 
 IGNORING RECOMMENDATIONS
 -------------------------
 
 When should you ignore the AI's advice?
 
 ✓ You have a better strategy in mind
 ✓ Recommendation doesn't fit your playstyle
 ✓ You know something AI doesn't (upcoming event)
 ✓ AI suggests spreading thin, you want to focus
 
 ✗ Don't ignore critical financial warnings
 ✗ Don't ignore defensive warnings if actually vulnerable
 ✗ Don't ignore if you don't have a better plan
 
 The AI is smart but not perfect. Use it as a guide!
 
 
 COMBINING RECOMMENDATIONS
 -------------------------
 
 Sometimes you can combine multiple recommendations:
 
 Example: AI suggests defensive play in Pennsylvania
          AND offensive play in Georgia
 
 Solution: Multi-state town hall in PA + GA
          Hits both recommendations
          Gets efficiency bonus
          Costs less than doing separately
 
 
 Think strategically! 🧠
 
 */
