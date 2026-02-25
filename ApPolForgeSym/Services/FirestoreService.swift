//
//  FirestoreService.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  SETUP REQUIRED:
//  1. Add Firebase SDK via Xcode > File > Add Package Dependencies
//     URL: https://github.com/firebase/firebase-ios-sdk  (v11.x)
//     Products to include: FirebaseCore, FirebaseFirestore ONLY
//  2. Add GoogleService-Info.plist to the ApPolForgeSym target
//  3. Call FirebaseApp.configure() in ApPolForgeSymApp.init()
//
//  FIRESTORE SCHEMA (read-only client):
//    polls/{raceId}/metadata          — PollAverage document (1 read per race)
//    polls/{raceId}/pollData/{pollId} — LivePoll documents (drill-down only)
//    congressional/{state}/senate/{cycle}/polls/metadata
//    congressional/{state}/house/{district}/{cycle}/polls/metadata
//    issues/{raceId}/correlations/{issueCategory} — PollIssueCorrelation
//    newsEvents/{articleId}           — NewsArticle documents
//
//  SECURITY RULES (no auth needed):
//    allow read: if true;
//    allow write: if false;
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - Candidate Roster

struct CandidateRoster {
    let candidateDem: String
    let candidateRep: String
    let demParty: PartyAffiliation
    let repParty: PartyAffiliation
    let demIncumbent: Bool
    let repIncumbent: Bool
}

struct RosterEntry: Identifiable {
    let id: String               // raceId, e.g. "AZ-senate"
    let stateAbbreviation: String
    let raceLabel: String        // "Senate" or "Governor"
    let roster: CandidateRoster
}

// MARK: - Firestore Service

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    // MARK: Published State

    @Published var pollAverages: [String: PollAverage] = [:]           // raceId → PollAverage
    @Published var congressionalRaces: [CongressionalRace] = []
    @Published var issueCorrelations: [String: [PollIssueCorrelation]] = [:]  // raceId → correlations
    @Published var recentNews: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var lastSyncDate: Date?

    // MARK: Private

    private let db: Firestore
    private var listeners: [ListenerRegistration] = []
    private let cacheKey = "FirestoreService.offlineCache"

    private init() {
        // Firestore offline persistence is enabled by default in the iOS SDK.
        // No additional configuration needed for offline cache.
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        let db = Firestore.firestore()
        db.settings = settings
        self.db = db

        // Restore last sync date from UserDefaults
        if let syncInterval = UserDefaults.standard.object(forKey: "lastFirestoreSync") as? TimeInterval {
            lastSyncDate = Date(timeIntervalSince1970: syncInterval)
        }
    }

    // MARK: - Public API

    /// Fetch poll average metadata for a race (1 Firestore read).
    /// Returns immediately from cache if available.
    func fetchPollAverage(for raceId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let docRef = db.collection("polls").document(raceId).collection("metadata").document("summary")
            let snapshot = try await docRef.getDocument()

            guard snapshot.exists, let data = snapshot.data() else { return }

            let average = parsePollAverage(from: data, raceId: raceId)
            pollAverages[raceId] = average
            persistCache()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Fetch individual polls for a race (drill-down only).
    func fetchDrillDownPolls(for raceId: String) async -> [LivePoll] {
        do {
            let snapshot = try await db.collection("polls").document(raceId)
                .collection("pollData").getDocuments()
            return snapshot.documents.compactMap { parseLivePoll(from: $0.data(), raceId: raceId) }
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    /// Fetch congressional race metadata for all tracked states.
    func fetchCongressionalRaces(chamber: ChamberType, cycle: Int = 2026) async {
        isLoading = true
        defer { isLoading = false }

        let chamberPath = chamber == .senate ? "senate" : "house"

        do {
            // Fetch top-level collection group
            let snapshot = try await db.collectionGroup(chamberPath).getDocuments()
            var races: [CongressionalRace] = []
            for doc in snapshot.documents {
                if let race = parseCongressionalRace(from: doc.data(), docId: doc.documentID) {
                    races.append(race)
                }
            }
            congressionalRaces = races
            persistCache()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Fetch issue-polling correlations for a specific race.
    func fetchIssueCorrelations(for raceId: String) async {
        do {
            let snapshot = try await db.collection("issues").document(raceId)
                .collection("correlations").getDocuments()
            let correlations = snapshot.documents.compactMap { doc -> PollIssueCorrelation? in
                parseCorrelation(from: doc.data(), raceId: raceId)
            }
            issueCorrelations[raceId] = correlations
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Fetch recent validated news events (last 7 days by default).
    func fetchRecentNews(daysBack: Int = 7, limit: Int = 50) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()

        do {
            let snapshot = try await db.collection("newsEvents")
                .whereField("publishedAt", isGreaterThan: Timestamp(date: cutoff))
                .order(by: "publishedAt", descending: true)
                .limit(to: limit)
                .getDocuments()

            recentNews = snapshot.documents.compactMap { parseNewsArticle(from: $0.data(), docId: $0.documentID) }
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate!.timeIntervalSince1970, forKey: "lastFirestoreSync")
            persistCache()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Fetch autofill candidate names, parties, and incumbent status for a race.
    /// Returns nil when firestoreEnabled is false or the race has no roster document.
    func fetchCandidateRoster(raceId: String) async -> CandidateRoster? {
        guard AppSettings.shared.firestoreEnabled else { return nil }
        do {
            let doc = try await db.collection("candidateRoster").document(raceId).getDocument()
            guard doc.exists, let data = doc.data() else { return nil }
            return CandidateRoster(
                candidateDem: data["candidateDem"] as? String ?? "",
                candidateRep: data["candidateRep"] as? String ?? "",
                demParty:     PartyAffiliation(rawValue: data["demParty"] as? String ?? "") ?? .democratic,
                repParty:     PartyAffiliation(rawValue: data["repParty"] as? String ?? "") ?? .republican,
                demIncumbent: data["demIncumbent"] as? Bool ?? false,
                repIncumbent: data["repIncumbent"] as? Bool ?? false
            )
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    /// Fetch all seeded candidateRoster documents for the browser sheet.
    func fetchAllCandidateRosters() async -> [RosterEntry] {
        guard AppSettings.shared.firestoreEnabled else { return [] }
        do {
            let snapshot = try await db.collection("candidateRoster").getDocuments()
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                let raceId = doc.documentID
                let parts = raceId.split(separator: "-", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                let stateAbbrev = parts[0].uppercased()
                let raceLabel = parts[1].capitalized
                let roster = CandidateRoster(
                    candidateDem: data["candidateDem"] as? String ?? "",
                    candidateRep: data["candidateRep"] as? String ?? "",
                    demParty:     PartyAffiliation(rawValue: data["demParty"] as? String ?? "") ?? .democratic,
                    repParty:     PartyAffiliation(rawValue: data["repParty"] as? String ?? "") ?? .republican,
                    demIncumbent: data["demIncumbent"] as? Bool ?? false,
                    repIncumbent: data["repIncumbent"] as? Bool ?? false
                )
                return RosterEntry(id: raceId, stateAbbreviation: stateAbbrev,
                                   raceLabel: raceLabel, roster: roster)
            }
            .sorted { $0.stateAbbreviation < $1.stateAbbreviation }
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    /// Full refresh: polls + congressional + news + correlations for active races.
    func performFullRefresh(raceIds: [String]) async {
        await fetchRecentNews()
        for raceId in raceIds {
            await fetchPollAverage(for: raceId)
            await fetchIssueCorrelations(for: raceId)
        }
        await fetchCongressionalRaces(chamber: .senate)
        await fetchCongressionalRaces(chamber: .house)
    }

    // MARK: - Private Parsers

    private func parsePollAverage(from data: [String: Any], raceId: String) -> PollAverage? {
        guard
            let demAvg = data["computedAvgDem"] as? Double,
            let repAvg = data["computedAvgRep"] as? Double,
            let tier = data["competitivenessTier"] as? Int
        else { return nil }

        let margin = data["forecastedMargin"] as? Double ?? abs(demAvg - repAvg)
        let winnerStr = data["forecastedWinner"] as? String
        let winner = winnerStr.flatMap { PartyAffiliation(rawValue: $0) }
        let refreshedTs = data["lastRefreshed"] as? Timestamp
        let refreshed = refreshedTs?.dateValue() ?? Date()

        return PollAverage(
            raceId: raceId,
            lastRefreshed: refreshed,
            computedAvgDem: demAvg,
            computedAvgRep: repAvg,
            forecastedWinner: winner,
            forecastedMargin: margin,
            competitivenessTier: tier
        )
    }

    private func parseLivePoll(from data: [String: Any], raceId: String) -> LivePoll? {
        guard
            let pollster = data["pollster"] as? String,
            let demPct = data["dem%"] as? Double,
            let repPct = data["rep%"] as? Double
        else { return nil }

        let sourceName = data["source"] as? String ?? ""
        let source = PollSource(rawValue: sourceName) ?? .other
        let startTs = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endTs = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        let sampleSize = data["sampleSize"] as? Int ?? 0
        let moe = data["MOE"] as? Double ?? 3.0
        let method = data["methodology"] as? String ?? "Mixed"
        let validated = data["isValidated"] as? Bool ?? false

        return LivePoll(
            raceId: raceId,
            pollster: pollster,
            source: source,
            startDate: startTs,
            endDate: endTs,
            sampleSize: sampleSize,
            marginOfError: moe,
            methodology: method,
            demPercent: demPct,
            repPercent: repPct,
            indPercent: data["ind%"] as? Double ?? 0,
            undecidedPercent: data["undecided%"] as? Double ?? 0,
            isValidated: validated
        )
    }

    private func parseCongressionalRace(from data: [String: Any], docId: String) -> CongressionalRace? {
        guard
            let state = data["state"] as? String,
            let stateAbbr = data["stateAbbreviation"] as? String,
            let chamberStr = data["chamber"] as? String,
            let chamber = ChamberType(rawValue: chamberStr),
            let cycle = data["cycle"] as? Int
        else { return nil }

        let districtNum = data["districtNumber"] as? Int ?? 0
        let tier = data["competitivenessTier"] as? Int ?? 3
        let cookPVI = data["cookPVI"] as? String ?? "EVEN"
        let demPct = data["currentDemPercent"] as? Double ?? 50.0
        let repPct = data["currentRepPercent"] as? Double ?? 50.0
        let incumbentPartyStr = data["incumbentParty"] as? String
        let incumbentParty = incumbentPartyStr.flatMap { PartyAffiliation(rawValue: $0) }

        let district = CongressionalDistrict(
            state: state,
            stateAbbreviation: stateAbbr,
            districtNumber: districtNum,
            chamber: chamber,
            cookPVI: cookPVI,
            competitivenessTier: tier,
            incumbentParty: incumbentParty,
            currentDemPercent: demPct,
            currentRepPercent: repPct
        )

        let raceId = docId
        let demAvg = data["demPollingAverage"] as? Double ?? demPct
        let repAvg = data["repPollingAverage"] as? Double ?? repPct
        let forecastedMargin = abs(demAvg - repAvg)
        let winnerParty: PartyAffiliation? = demAvg > repAvg ? .democratic : .republican

        return CongressionalRace(
            raceId: raceId,
            district: district,
            cycle: cycle,
            candidateDem: data["candidateDem"] as? String ?? "Democratic Candidate",
            candidateRep: data["candidateRep"] as? String ?? "Republican Candidate",
            candidateDemIncumbent: data["candidateDemIncumbent"] as? Bool ?? false,
            candidateRepIncumbent: data["candidateRepIncumbent"] as? Bool ?? false,
            demPollingAverage: demAvg,
            repPollingAverage: repAvg,
            lastRefreshed: (data["lastRefreshed"] as? Timestamp)?.dateValue(),
            forecastedWinner: winnerParty,
            forecastedMargin: forecastedMargin
        )
    }

    private func parseCorrelation(from data: [String: Any], raceId: String) -> PollIssueCorrelation? {
        guard
            let issueCatStr = data["issueCategory"] as? String,
            let issueCat = PolicyIssueCategory(rawValue: issueCatStr),
            let r = data["correlationCoefficient"] as? Double
        else { return nil }

        let swing = data["pollingSwingPerEvent"] as? Double ?? 0
        let count = data["recentNewsCount"] as? Int ?? 0
        let significant = data["isSignificant"] as? Bool ?? (abs(r) > 0.3)
        let computedTs = (data["computedAt"] as? Timestamp)?.dateValue() ?? Date()

        return PollIssueCorrelation(
            raceId: raceId,
            issueCategory: issueCat,
            correlationCoefficient: r,
            pollingSwingPerEvent: swing,
            recentNewsCount: count,
            isSignificant: significant,
            computedAt: computedTs
        )
    }

    private func parseNewsArticle(from data: [String: Any], docId: String) -> NewsArticle? {
        guard
            let headline = data["headline"] as? String,
            let source = data["source"] as? String
        else { return nil }

        let issueCatStr = data["classifiedIssue"] as? String ?? ""
        let issueCat = PolicyIssueCategory(rawValue: issueCatStr) ?? .economyJobs
        let publishedTs = (data["publishedAt"] as? Timestamp)?.dateValue() ?? Date()
        let sentiment = data["sentimentScore"] as? Double ?? 0
        let impact = data["estimatedPollingImpact"] as? Double ?? 0
        let validated = data["isValidated"] as? Bool ?? false
        let conflicts = data["conflictsWithOtherSources"] as? Bool ?? false
        let raceIds = data["relatedRaceIds"] as? [String] ?? []

        return NewsArticle(
            headline: headline,
            source: source,
            publishedAt: publishedTs,
            url: data["url"] as? String ?? "",
            classifiedIssue: issueCat,
            sentimentScore: sentiment,
            estimatedPollingImpact: impact,
            isValidated: validated,
            conflictsWithOtherSources: conflicts,
            relatedRaceIds: raceIds
        )
    }

    // MARK: - Offline Cache

    private func persistCache() {
        // Lightweight UserDefaults cache for last-known poll averages.
        // Full Firestore offline persistence handles document-level caching automatically.
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(pollAverages.values)) {
            UserDefaults.standard.set(data, forKey: "\(cacheKey).pollAverages")
        }
    }

    func loadFromCache() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "\(cacheKey).pollAverages"),
           let averages = try? decoder.decode([PollAverage].self, from: data) {
            for avg in averages {
                pollAverages[avg.raceId] = avg
            }
        }
    }

    // MARK: - Cleanup

    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}
