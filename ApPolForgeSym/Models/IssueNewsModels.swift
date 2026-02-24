//
//  IssueNewsModels.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//

import Foundation

// MARK: - Policy Issue Category

/// Ten broad policy categories used for news classification and polling impact analysis.
enum PolicyIssueCategory: String, Codable, CaseIterable, Identifiable {
    case economyJobs        = "Economy & Jobs"
    case healthcare         = "Healthcare"
    case immigration        = "Immigration"
    case crimeSafety        = "Crime & Safety"
    case housingCostOfLiving = "Housing & Cost of Living"
    case climateEnergy      = "Climate & Energy"
    case education          = "Education"
    case governmentDemocracy = "Government & Democracy"
    case socialIssues       = "Social Issues"
    case foreignPolicy      = "Foreign Policy"

    var id: String { rawValue }

    // MARK: Sensitivity

    /// How strongly news events in this category typically move polling.
    /// Used as multiplier: polling_change = sensitivityCoefficient × 0.15 × event_volume
    var sensitivityCoefficient: Double {
        switch self {
        case .economyJobs:          return 1.00
        case .healthcare:           return 0.90
        case .immigration:          return 0.85
        case .crimeSafety:          return 0.70
        case .housingCostOfLiving:  return 0.75
        case .climateEnergy:        return 0.65
        case .education:            return 0.60
        case .governmentDemocracy:  return 0.60
        case .socialIssues:         return 0.55
        case .foreignPolicy:        return 0.50
        }
    }

    /// Typical per-event polling swing in percentage points.
    var typicalSwingRange: ClosedRange<Double> {
        switch self {
        case .economyJobs:          return 5...12
        case .healthcare:           return 4...10
        case .immigration:          return 4...9
        case .crimeSafety:          return 3...7
        case .housingCostOfLiving:  return 3...7
        case .climateEnergy:        return 2...6
        case .education:            return 2...5
        case .governmentDemocracy:  return 2...5
        case .socialIssues:         return 1...4
        case .foreignPolicy:        return 1...4
        }
    }

    // MARK: Keyword Classification

    /// Keywords used to auto-classify news articles into this category.
    var classificationKeywords: [String] {
        switch self {
        case .economyJobs:
            return ["economy", "jobs", "employment", "unemployment", "inflation",
                    "gdp", "recession", "wages", "labor", "stock market",
                    "federal reserve", "interest rates", "trade", "tariffs",
                    "manufacturing", "deficit", "debt", "budget", "taxes", "tax cut"]
        case .healthcare:
            return ["healthcare", "health care", "insurance", "medicaid", "medicare",
                    "aca", "affordable care act", "prescription drugs", "hospital",
                    "medical", "obamacare", "drug prices", "mental health",
                    "opioid", "pandemic", "vaccine", "public health"]
        case .immigration:
            return ["immigration", "immigrants", "border", "deportation", "asylum",
                    "undocumented", "visa", "migrants", "border security", "daca",
                    "dreamers", "customs", "cbp", "ice", "detention",
                    "refugee", "citizenship", "illegal immigration"]
        case .crimeSafety:
            return ["crime", "safety", "police", "law enforcement", "gun",
                    "shooting", "homicide", "fentanyl", "drugs", "fbi",
                    "criminal justice", "incarceration", "prison", "arrest",
                    "violent crime", "murder", "robbery", "gun control",
                    "second amendment", "background check"]
        case .housingCostOfLiving:
            return ["housing", "rent", "mortgage", "home prices", "cost of living",
                    "affordable housing", "real estate", "eviction", "homelessness",
                    "zoning", "homeownership", "foreclosure", "shelter", "apartment",
                    "housing market", "property"]
        case .climateEnergy:
            return ["climate", "climate change", "global warming", "energy",
                    "renewable", "solar", "wind power", "fossil fuels", "carbon",
                    "emissions", "epa", "environment", "green new deal",
                    "electric vehicles", "oil", "gas prices", "pipeline",
                    "paris agreement", "clean energy"]
        case .education:
            return ["education", "school", "university", "college", "student loans",
                    "teachers", "curriculum", "school choice", "vouchers",
                    "public school", "higher education", "k-12", "graduation",
                    "literacy", "student debt", "common core"]
        case .governmentDemocracy:
            return ["democracy", "election", "voting", "voter", "congress",
                    "senate", "house", "supreme court", "constitution", "government",
                    "corruption", "transparency", "lobbying", "campaign finance",
                    "gerrymandering", "filibuster", "bipartisan", "impeachment"]
        case .socialIssues:
            return ["abortion", "lgbtq", "transgender", "gay rights",
                    "religious freedom", "civil rights", "racial justice",
                    "diversity", "inclusion", "affirmative action", "free speech",
                    "social media", "cancel culture", "roe v wade", "gender",
                    "discrimination", "equity"]
        case .foreignPolicy:
            return ["foreign policy", "nato", "ukraine", "russia", "china",
                    "iran", "israel", "military", "pentagon", "defense", "war",
                    "troops", "sanctions", "diplomacy", "allies",
                    "national security", "terrorism", "middle east", "taiwan",
                    "nuclear", "alliance"]
        }
    }

    var icon: String {
        switch self {
        case .economyJobs:          return "chart.bar.fill"
        case .healthcare:           return "cross.case.fill"
        case .immigration:          return "person.2.fill"
        case .crimeSafety:          return "shield.fill"
        case .housingCostOfLiving:  return "house.fill"
        case .climateEnergy:        return "leaf.fill"
        case .education:            return "graduationcap.fill"
        case .governmentDemocracy:  return "building.columns.fill"
        case .socialIssues:         return "heart.fill"
        case .foreignPolicy:        return "globe.americas.fill"
        }
    }
}

// MARK: - News Source Tier

/// Credibility tier for news sources, used for validation logic.
enum NewsSourceTier: Int, Codable, CaseIterable {
    /// AP, Reuters, NYT, WaPo, BBC, NPR — auto-validated
    case tier1 = 1
    /// Major national outlets — validated if ≥2 Tier-1 sources confirm within 24h
    case tier2 = 2
    /// Regional/local — displayed with minimal polling weight
    case tier3 = 3

    var label: String {
        switch self {
        case .tier1: return "Tier 1"
        case .tier2: return "Tier 2"
        case .tier3: return "Tier 3"
        }
    }

    var badgeColorHex: String {
        switch self {
        case .tier1: return "#27ae60"
        case .tier2: return "#f39c12"
        case .tier3: return "#95a5a6"
        }
    }
}

// MARK: - News Source Helper

struct NewsSource {
    static let tier1Names: [String] = [
        "Associated Press", "AP", "Reuters", "The New York Times", "New York Times",
        "NYT", "The Washington Post", "Washington Post", "BBC", "NPR", "BBC News"
    ]

    static let tier2Names: [String] = [
        "CNN", "NBC", "ABC News", "CBS", "Fox News", "Politico",
        "The Hill", "Bloomberg", "Wall Street Journal", "WSJ", "USA Today",
        "Axios", "The Atlantic", "Time", "NBC News", "CBS News"
    ]

    static func tier(for sourceName: String) -> NewsSourceTier {
        let lower = sourceName.lowercased()
        if tier1Names.map({ $0.lowercased() }).contains(where: { lower.contains($0) }) {
            return .tier1
        }
        if tier2Names.map({ $0.lowercased() }).contains(where: { lower.contains($0) }) {
            return .tier2
        }
        return .tier3
    }
}

// MARK: - News Article

struct NewsArticle: Identifiable, Codable {
    let id: UUID
    let headline: String
    let source: String
    let sourceTier: NewsSourceTier
    let publishedAt: Date
    /// URL string — displayed as link but not fetched client-side
    let url: String
    let classifiedIssue: PolicyIssueCategory
    /// -1.0 (very negative) to +1.0 (very positive)
    let sentimentScore: Double
    /// Estimated polling impact in percentage points, dampened for unvalidated articles
    let estimatedPollingImpact: Double
    /// True if Tier-1 source or cross-validated by ≥2 Tier-1 sources
    let isValidated: Bool
    /// True if ≥2 Tier-1 sources contradict within 24h
    var conflictsWithOtherSources: Bool
    let relatedRaceIds: [String]

    var impactDisplay: String {
        let sign = estimatedPollingImpact >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", estimatedPollingImpact))pp"
    }

    var isPositiveSentiment: Bool { sentimentScore > 0.1 }
    var isNegativeSentiment: Bool { sentimentScore < -0.1 }

    var publishedDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }

    init(
        id: UUID = UUID(),
        headline: String,
        source: String,
        publishedAt: Date = Date(),
        url: String = "",
        classifiedIssue: PolicyIssueCategory,
        sentimentScore: Double = 0,
        estimatedPollingImpact: Double = 0,
        isValidated: Bool = false,
        conflictsWithOtherSources: Bool = false,
        relatedRaceIds: [String] = []
    ) {
        self.id = id
        self.headline = headline
        self.source = source
        self.sourceTier = NewsSource.tier(for: source)
        self.publishedAt = publishedAt
        self.url = url
        self.classifiedIssue = classifiedIssue
        self.sentimentScore = sentimentScore
        self.estimatedPollingImpact = estimatedPollingImpact
        self.isValidated = isValidated
        self.conflictsWithOtherSources = conflictsWithOtherSources
        self.relatedRaceIds = relatedRaceIds
    }
}

// MARK: - Poll-Issue Correlation

/// Pearson correlation between news volume in a category and polling movement for a race.
struct PollIssueCorrelation: Identifiable, Codable {
    let id: UUID
    let raceId: String
    let issueCategory: PolicyIssueCategory
    /// Pearson r coefficient, -1.0 to +1.0
    let correlationCoefficient: Double
    /// Average polling movement (pp) per published article in this category
    let pollingSwingPerEvent: Double
    let recentNewsCount: Int
    /// Significant if |r| > 0.3
    let isSignificant: Bool
    let computedAt: Date

    var strengthLabel: String {
        let absR = abs(correlationCoefficient)
        switch absR {
        case 0.7...:  return "Strong"
        case 0.4...:  return "Moderate"
        case 0.2...:  return "Weak"
        default:      return "Negligible"
        }
    }

    var formattedCoefficient: String {
        String(format: "%.2f", correlationCoefficient)
    }

    init(
        id: UUID = UUID(),
        raceId: String,
        issueCategory: PolicyIssueCategory,
        correlationCoefficient: Double,
        pollingSwingPerEvent: Double,
        recentNewsCount: Int,
        isSignificant: Bool,
        computedAt: Date = Date()
    ) {
        self.id = id
        self.raceId = raceId
        self.issueCategory = issueCategory
        self.correlationCoefficient = correlationCoefficient
        self.pollingSwingPerEvent = pollingSwingPerEvent
        self.recentNewsCount = recentNewsCount
        self.isSignificant = isSignificant
        self.computedAt = computedAt
    }
}
