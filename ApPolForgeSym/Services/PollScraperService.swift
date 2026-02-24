//
//  PollScraperService.swift
//  ApPolForgeSym
//
//  ⚠ DEVELOPER REFERENCE ONLY — This service documents the Cloud Function
//  scraping approach. It is NOT called from the iOS/macOS app.
//  See functions/src/pollScraper.ts for the actual Cloud Function implementation.
//
//  The app is a READ-ONLY Firestore client; all scraping and writes happen
//  server-side inside Firebase Cloud Functions to avoid exposing credentials
//  and to stay within Apple's App Store guidelines on web scraping.
//
//  DATA SOURCES (in priority order):
//    1. FiveThirtyEight polls CSV  — free, structured, no auth required
//       Endpoint: https://projects.fivethirtyeight.com/polls/data/president_polls.csv
//    2. RealClearPolitics HTML     — free, robots.txt allows crawling
//    3. Ballotpedia HTML           — free, rate limit: 1 request/race/cycle
//
//  SCHEDULE:
//    pollScraper Cloud Function runs every 14 days (bi-weekly).
//    newsProcessor Cloud Function runs every 1 day.
//
//  FIRESTORE WRITES (server only — security rules: allow write: if false):
//    polls/{raceId}/metadata/summary    — PollAverage document
//    polls/{raceId}/pollData/{pollId}   — Individual LivePoll documents
//    refreshLog/{refreshId}             — Audit log entry
//

import Foundation

/// Developer-facing documentation for the poll scraper architecture.
/// See `functions/src/pollScraper.ts` for the live Cloud Function implementation.
enum PollScraperDocumentation {

    /// FiveThirtyEight CSV column names (as of 2026).
    static let fiveThirtyEightColumns = [
        "poll_id", "pollster", "sponsor", "field_dates",
        "fte_grade", "sample_size", "population",
        "dem", "rep", "ind",
        "created_at", "notes", "url",
        "state", "office_type", "seat_name", "seat_number",
        "cycle", "party", "candidate_name"
    ]

    /// Expected Firestore metadata document structure written by Cloud Function.
    static let firestoreMetadataShape: [String: String] = [
        "lastRefreshed":        "Timestamp",
        "computedAvgDem":       "Double",
        "computedAvgRep":       "Double",
        "forecastedWinner":     "String (PartyAffiliation rawValue)",
        "forecastedMargin":     "Double",
        "competitivenessTier":  "Int (1–4)",
        "state":                "String",
        "raceType":             "String (presidential | senate | house)",
        "cycle":                "Int (e.g. 2026)"
    ]

    /// Expected Firestore individual poll document structure.
    static let firestorePollShape: [String: String] = [
        "pollster":             "String",
        "source":               "String (FiveThirtyEight | RealClearPolitics | Ballotpedia)",
        "startDate":            "Timestamp",
        "endDate":              "Timestamp",
        "sampleSize":           "Int",
        "MOE":                  "Double",
        "methodology":          "String (Phone | Online | Mixed)",
        "dem%":                 "Double",
        "rep%":                 "Double",
        "ind%":                 "Double",
        "undecided%":           "Double",
        "isValidated":          "Bool"
    ]

    /// Competitiveness tier thresholds (margin = |D% - R%|).
    static let competitivenessTiers: [(tier: Int, label: String, maxMargin: Double)] = [
        (1, "Battleground", 5.0),
        (2, "Lean",         10.0),
        (3, "Likely",       20.0),
        (4, "Safe",         Double.infinity)
    ]

    static func competitivenessTier(forMargin margin: Double) -> Int {
        for entry in competitivenessTiers {
            if margin < entry.maxMargin { return entry.tier }
        }
        return 4
    }
}
