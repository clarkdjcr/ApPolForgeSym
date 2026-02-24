//
//  NewsAggregatorService.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Fetches from NewsAPI.org (max 100 req/day on free tier).
//  Batches 8–10 queries/day to stay under limit.
//  RSS fallback: AP, Reuters, NPR (no API key required).
//  Stores key in Keychain via SecureAPIKeyManager.
//

import Foundation
import Combine

// MARK: - RSS Feed

private struct RSSFeed {
    let name: String
    let url: URL
    let tier: NewsSourceTier
}

// MARK: - NewsAPI Response Models (private)

private struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

private struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let title: String?
    let description: String?
    let url: String?
    let publishedAt: String?

    struct NewsAPISource: Codable {
        let name: String?
    }
}

// MARK: - News Aggregator Service

@MainActor
final class NewsAggregatorService: ObservableObject {
    static let shared = NewsAggregatorService()

    @Published var articles: [NewsArticle] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var lastFetchDate: Date?

    private let session = URLSession.shared
    private let newsAPIBaseURL = "https://newsapi.org/v2/everything"
    private let rssFeedList: [RSSFeed] = [
        RSSFeed(name: "AP", url: URL(string: "https://feeds.apnews.com/rss/politics")!, tier: .tier1),
        RSSFeed(name: "Reuters", url: URL(string: "https://feeds.reuters.com/Reuters/PoliticsNews")!, tier: .tier1),
        RSSFeed(name: "NPR", url: URL(string: "https://feeds.npr.org/1014/rss.xml")!, tier: .tier1)
    ]

    private init() {}

    // MARK: - Public API

    /// Fetch news articles covering all 10 policy categories.
    /// Batches 2 queries per call to NewsAPI — max 8–10 calls/day stays under 100 req/day limit.
    func fetchAllIssueNews(raceIds: [String] = []) async {
        isLoading = true
        defer { isLoading = false }

        guard let apiKey = try? SecureAPIKeyManager.shared.retrieveAPIKey(for: .newsAPI) else {
            // Fall back to RSS feeds when no API key is available
            await fetchRSSFallback()
            return
        }

        var fetchedArticles: [NewsArticle] = []

        // Group categories into batches of 2 to minimize API calls
        let categories = PolicyIssueCategory.allCases
        let batches = stride(from: 0, to: categories.count, by: 2).map {
            Array(categories[$0..<min($0 + 2, categories.count)])
        }

        for batch in batches {
            let keywords = batch.flatMap { $0.classificationKeywords.prefix(3) }.joined(separator: " OR ")
            if let batchArticles = await fetchFromNewsAPI(query: keywords, apiKey: apiKey) {
                let classified = batchArticles.compactMap { article -> NewsArticle? in
                    classifyArticle(article, categories: batch, raceIds: raceIds)
                }
                fetchedArticles.append(contentsOf: classified)
            }
        }

        // Cross-validate for conflicts
        flagConflicts(in: &fetchedArticles)

        articles = fetchedArticles.sorted { $0.publishedAt > $1.publishedAt }
        lastFetchDate = Date()
    }

    /// Fetch news for a specific race, prioritizing relevant keywords.
    func fetchNews(for raceId: String, state: String) async {
        guard let apiKey = try? SecureAPIKeyManager.shared.retrieveAPIKey(for: .newsAPI) else {
            await fetchRSSFallback()
            return
        }

        let query = "\(state) election OR \(state) senate OR \(state) congress"
        guard let fetched = await fetchFromNewsAPI(query: query, apiKey: apiKey) else { return }

        let classified = fetched.compactMap { article -> NewsArticle? in
            classifyArticle(article, categories: PolicyIssueCategory.allCases, raceIds: [raceId])
        }

        // Merge with existing, deduplicated by URL
        var existing = articles
        let existingURLs = Set(existing.map(\.url))
        let newArticles = classified.filter { !existingURLs.contains($0.url) }
        existing.append(contentsOf: newArticles)
        articles = existing.sorted { $0.publishedAt > $1.publishedAt }
    }

    // MARK: - Private: NewsAPI

    private func fetchFromNewsAPI(query: String, apiKey: String) async -> [NewsAPIArticle]? {
        var components = URLComponents(string: newsAPIBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "pageSize", value: "20"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            let decoded = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
            return decoded.articles
        } catch {
            lastError = "NewsAPI fetch failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Private: RSS Fallback

    private func fetchRSSFallback() async {
        var fallbackArticles: [NewsArticle] = []

        for feed in rssFeedList {
            guard let fetched = await fetchRSSFeed(feed) else { continue }
            fallbackArticles.append(contentsOf: fetched)
        }

        articles = fallbackArticles.sorted { $0.publishedAt > $1.publishedAt }
        lastFetchDate = Date()
    }

    private func fetchRSSFeed(_ feed: RSSFeed) async -> [NewsArticle]? {
        do {
            let (data, _) = try await session.data(from: feed.url)
            let text = String(data: data, encoding: .utf8) ?? ""
            return parseRSS(text, sourceName: feed.name, tier: feed.tier)
        } catch {
            return nil
        }
    }

    /// Minimal RSS parser — extracts <title> and <pubDate> items.
    private func parseRSS(_ xml: String, sourceName: String, tier: NewsSourceTier) -> [NewsArticle] {
        var articles: [NewsArticle] = []
        let itemPattern = "<item>(.*?)</item>"
        let titlePattern = "<title><!\\[CDATA\\[([^\\]]+)\\]\\]></title>|<title>([^<]+)</title>"
        let datePattern = "<pubDate>([^<]+)</pubDate>"
        let linkPattern = "<link>([^<]+)</link>"

        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(xml.startIndex..., in: xml)
        let itemMatches = itemRegex.matches(in: xml, range: range)

        for match in itemMatches.prefix(10) {
            guard let itemRange = Range(match.range(at: 1), in: xml) else { continue }
            let item = String(xml[itemRange])

            let headline = extractFirst(pattern: titlePattern, from: item, group: 1) ??
                           extractFirst(pattern: titlePattern, from: item, group: 2) ?? "No title"
            let dateStr = extractFirst(pattern: datePattern, from: item, group: 1) ?? ""
            let link = extractFirst(pattern: linkPattern, from: item, group: 1) ?? ""

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
            let pubDate = formatter.date(from: dateStr) ?? Date()

            let category = classifyHeadline(headline)

            let article = NewsArticle(
                headline: headline,
                source: sourceName,
                publishedAt: pubDate,
                url: link,
                classifiedIssue: category,
                sentimentScore: 0,
                estimatedPollingImpact: estimatedImpact(for: category, tier: tier),
                isValidated: tier == .tier1,
                conflictsWithOtherSources: false
            )
            articles.append(article)
        }

        return articles
    }

    private func extractFirst(pattern: String, from text: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: group), in: text) else { return nil }
        return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Classification

    private func classifyArticle(
        _ apiArticle: NewsAPIArticle,
        categories: [PolicyIssueCategory],
        raceIds: [String]
    ) -> NewsArticle? {
        guard let headline = apiArticle.title, !headline.isEmpty else { return nil }

        let sourceName = apiArticle.source.name ?? "Unknown"
        let tier = NewsSource.tier(for: sourceName)

        let fullText = [headline, apiArticle.description].compactMap { $0 }.joined(separator: " ").lowercased()
        let category = classifyHeadline(fullText, among: categories)

        let formatter = ISO8601DateFormatter()
        let pubDate = apiArticle.publishedAt.flatMap { formatter.date(from: $0) } ?? Date()

        let impact = estimatedImpact(for: category, tier: tier)

        return NewsArticle(
            headline: headline,
            source: sourceName,
            publishedAt: pubDate,
            url: apiArticle.url ?? "",
            classifiedIssue: category,
            sentimentScore: 0,   // Sentiment analysis would require additional NLP pass
            estimatedPollingImpact: impact,
            isValidated: tier == .tier1,
            conflictsWithOtherSources: false,
            relatedRaceIds: raceIds
        )
    }

    private func classifyHeadline(_ text: String, among categories: [PolicyIssueCategory] = PolicyIssueCategory.allCases) -> PolicyIssueCategory {
        let lower = text.lowercased()
        var bestMatch: PolicyIssueCategory = .economyJobs
        var bestScore = 0

        for category in categories {
            let score = category.classificationKeywords.filter { lower.contains($0) }.count
            if score > bestScore {
                bestScore = score
                bestMatch = category
            }
        }
        return bestMatch
    }

    private func estimatedImpact(for category: PolicyIssueCategory, tier: NewsSourceTier) -> Double {
        let base = category.sensitivityCoefficient * 0.15 * category.typicalSwingRange.upperBound
        let tierMultiplier: Double = switch tier {
        case .tier1: 1.0
        case .tier2: 0.7
        case .tier3: 0.3
        }
        return base * tierMultiplier
    }

    // MARK: - Conflict Detection

    /// Flag articles where ≥2 Tier-1 sources published conflicting reports
    /// within 24 hours on the same headline/topic.
    private func flagConflicts(in articles: inout [NewsArticle]) {
        let cutoff: TimeInterval = 24 * 3600

        for i in 0..<articles.count {
            for j in (i + 1)..<articles.count {
                let a = articles[i]
                let b = articles[j]

                // Same issue, similar time window, different Tier-1 sentiment
                let timeDiff = abs(a.publishedAt.timeIntervalSince(b.publishedAt))
                guard timeDiff < cutoff,
                      a.classifiedIssue == b.classifiedIssue,
                      a.sourceTier == .tier1,
                      b.sourceTier == .tier1,
                      a.isPositiveSentiment != b.isPositiveSentiment
                else { continue }

                articles[i].conflictsWithOtherSources = true
                articles[j].conflictsWithOtherSources = true
            }
        }
    }
}
