//
//  IssueCorrelationEngine.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Computes Pearson correlation between news volume per issue category
//  and polling movement for a given race. Identifies top sensitive issues
//  and generates swing alerts when significant correlations are detected.
//

import Foundation
import Combine

// MARK: - Swing Alert

struct SwingAlert: Identifiable {
    let id = UUID()
    let raceId: String
    let issueCategory: PolicyIssueCategory
    let estimatedSwing: Double
    let direction: SwingDirection
    let triggeringArticleCount: Int
    let generatedAt: Date

    enum SwingDirection {
        case demFavorable, repFavorable, neutral
    }

    var alertMessage: String {
        let pctStr = String(format: "%.1f", estimatedSwing)
        let dirStr: String
        switch direction {
        case .demFavorable: dirStr = "favorable to Democrats"
        case .repFavorable: dirStr = "favorable to Republicans"
        case .neutral:      dirStr = "direction unclear"
        }
        return "\(issueCategory.rawValue): ~\(pctStr)pp swing \(dirStr) based on \(triggeringArticleCount) recent articles"
    }
}

// MARK: - Issue Correlation Engine

@MainActor
final class IssueCorrelationEngine: ObservableObject {
    static let shared = IssueCorrelationEngine()

    @Published var correlations: [String: [PollIssueCorrelation]] = [:]  // raceId → sorted correlations
    @Published var swingAlerts: [SwingAlert] = []

    private init() {}

    // MARK: - Public API

    /// Compute correlations between news volume and polling movement for a race.
    /// - Parameters:
    ///   - raceId: The Firestore race ID (e.g. "PA-presidential")
    ///   - articles: Recent news articles relevant to this race
    ///   - pollHistory: Time-series of (date, demPct, repPct) tuples
    func computeCorrelations(
        for raceId: String,
        articles: [NewsArticle],
        pollHistory: [(date: Date, demPct: Double, repPct: Double)]
    ) {
        guard pollHistory.count >= 3 else { return }

        var result: [PollIssueCorrelation] = []

        for category in PolicyIssueCategory.allCases {
            let correlation = correlationForCategory(
                category,
                raceId: raceId,
                articles: articles,
                pollHistory: pollHistory
            )
            result.append(correlation)
        }

        // Sort by significance and correlation strength
        result.sort { abs($0.correlationCoefficient) > abs($1.correlationCoefficient) }
        correlations[raceId] = result

        // Generate swing alerts for significant correlations
        generateSwingAlerts(from: result, articles: articles, raceId: raceId)
    }

    /// Top N most polling-sensitive issues for a race (by |correlation| descending).
    func topSensitiveIssues(for raceId: String, limit: Int = 3) -> [PollIssueCorrelation] {
        let sorted = correlations[raceId]?.filter(\.isSignificant) ?? []
        return Array(sorted.prefix(limit))
    }

    /// Estimated polling impact for a batch of new articles.
    /// Dampened by sensitivityCoefficient × 0.15 to avoid overwhelming gameplay.
    func estimatedPollingImpact(for articles: [NewsArticle], raceId: String) -> Double {
        guard !articles.isEmpty else { return 0 }

        var totalImpact = 0.0

        for article in articles {
            let correlation = correlations[raceId]?.first(where: { $0.issueCategory == article.classifiedIssue })
            let baseCoeff = article.classifiedIssue.sensitivityCoefficient
            let dampeningFactor = 0.15

            // Use stored pollingSwingPerEvent if available, else estimate from sensitivity
            let swingPerEvent = correlation?.pollingSwingPerEvent ?? (baseCoeff * dampeningFactor)

            // Reduce impact for unvalidated or conflicted articles
            let validationMultiplier: Double = {
                if article.conflictsWithOtherSources { return 0.25 }
                if !article.isValidated { return 0.50 }
                return 1.0
            }()

            totalImpact += swingPerEvent * validationMultiplier
        }

        return totalImpact
    }

    // MARK: - Private: Pearson Correlation

    private func correlationForCategory(
        _ category: PolicyIssueCategory,
        raceId: String,
        articles: [NewsArticle],
        pollHistory: [(date: Date, demPct: Double, repPct: Double)]
    ) -> PollIssueCorrelation {

        // Build weekly news volume series aligned to poll history dates
        let volumeSeries = buildVolumeSeries(
            for: category,
            articles: articles,
            alignedTo: pollHistory.map(\.date)
        )

        // Polling movement = demPct - repPct margin change per period
        let marginSeries = pollHistory.map { $0.demPct - $0.repPct }

        let r = pearsonCorrelation(x: volumeSeries, y: marginSeries)
        let isSignificant = abs(r) > 0.3

        let recentArticles = articles.filter { $0.classifiedIssue == category }
        let avgSwing: Double = {
            guard !recentArticles.isEmpty else { return category.sensitivityCoefficient * 0.15 }
            return recentArticles.map { abs($0.estimatedPollingImpact) }.reduce(0, +) / Double(recentArticles.count)
        }()

        return PollIssueCorrelation(
            raceId: raceId,
            issueCategory: category,
            correlationCoefficient: r,
            pollingSwingPerEvent: avgSwing,
            recentNewsCount: recentArticles.count,
            isSignificant: isSignificant
        )
    }

    /// Bin articles into time buckets aligned with poll history dates.
    private func buildVolumeSeries(
        for category: PolicyIssueCategory,
        articles: [NewsArticle],
        alignedTo dates: [Date]
    ) -> [Double] {
        guard dates.count >= 2 else { return [Double](repeating: 0, count: dates.count) }

        let relevant = articles.filter { $0.classifiedIssue == category }
        var series = [Double](repeating: 0, count: dates.count)

        for (i, date) in dates.enumerated() {
            let windowStart: Date = i == 0 ? date.addingTimeInterval(-7 * 86400) : dates[i - 1]
            let count = relevant.filter { $0.publishedAt >= windowStart && $0.publishedAt <= date }.count
            series[i] = Double(count)
        }

        return series
    }

    // MARK: - Private: Pearson r

    private func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count >= 2 else { return 0 }
        let n = Double(x.count)

        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var numerator = 0.0
        var sumSqX = 0.0
        var sumSqY = 0.0

        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            numerator += dx * dy
            sumSqX += dx * dx
            sumSqY += dy * dy
        }

        let denominator = sqrt(sumSqX * sumSqY)
        guard denominator > 0 else { return 0 }
        return max(-1.0, min(1.0, numerator / denominator))
    }

    // MARK: - Swing Alerts

    private func generateSwingAlerts(
        from correlations: [PollIssueCorrelation],
        articles: [NewsArticle],
        raceId: String
    ) {
        var newAlerts: [SwingAlert] = []

        for correlation in correlations where correlation.isSignificant && correlation.recentNewsCount >= 2 {
            let recentArticles = articles.filter {
                $0.classifiedIssue == correlation.issueCategory &&
                $0.publishedAt > Date().addingTimeInterval(-72 * 3600)
            }
            guard recentArticles.count >= 2 else { continue }

            let avgSentiment = recentArticles.map(\.sentimentScore).reduce(0, +) / Double(recentArticles.count)
            let direction: SwingAlert.SwingDirection = {
                if avgSentiment > 0.1 { return .demFavorable }
                if avgSentiment < -0.1 { return .repFavorable }
                return .neutral
            }()

            let estimatedSwing = correlation.pollingSwingPerEvent * Double(recentArticles.count)

            let alert = SwingAlert(
                raceId: raceId,
                issueCategory: correlation.issueCategory,
                estimatedSwing: estimatedSwing,
                direction: direction,
                triggeringArticleCount: recentArticles.count,
                generatedAt: Date()
            )
            newAlerts.append(alert)
        }

        // Replace alerts for this race
        swingAlerts.removeAll { $0.raceId == raceId }
        swingAlerts.append(contentsOf: newAlerts)
    }
}
