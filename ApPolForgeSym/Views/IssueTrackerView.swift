//
//  IssueTrackerView.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Shows the top polling-sensitive issues for the active race,
//  along with recent news articles and conflict-flagged articles.
//

import SwiftUI

// MARK: - Issue Tracker View

struct IssueTrackerView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var newsService = NewsAggregatorService.shared
    @StateObject private var correlationEngine = IssueCorrelationEngine.shared
    @StateObject private var firestoreService = FirestoreService.shared
    @State private var selectedCategory: PolicyIssueCategory? = nil
    @State private var showingConflictsOnly = false

    private var activeCandidate: UserCandidate? {
        guard let id = gameState.activeUserCandidateId else { return nil }
        return gameState.userCandidates.first { $0.id == id }
    }

    private var activeRaceId: String {
        activeCandidate?.raceId ?? AppSettings.shared.activeRaceId
    }

    private var topCorrelations: [PollIssueCorrelation] {
        (correlationEngine.correlations[activeRaceId] ??
         firestoreService.issueCorrelations[activeRaceId] ?? [])
            .filter(\.isSignificant)
            .prefix(5)
            .map { $0 }
    }

    private var filteredArticles: [NewsArticle] {
        var articles = newsService.articles

        if showingConflictsOnly {
            articles = articles.filter(\.conflictsWithOtherSources)
        }

        if let cat = selectedCategory {
            articles = articles.filter { $0.classifiedIssue == cat }
        }

        return articles.sorted { $0.publishedAt > $1.publishedAt }
    }

    private var conflictedArticles: [NewsArticle] {
        newsService.articles.filter(\.conflictsWithOtherSources)
    }

    var body: some View {
        List {
            // MARK: Issue Correlation Section
            if !topCorrelations.isEmpty {
                Section {
                    ForEach(topCorrelations) { correlation in
                        IssueCorrelationRow(
                            correlation: correlation,
                            isSelected: selectedCategory == correlation.issueCategory
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                if selectedCategory == correlation.issueCategory {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = correlation.issueCategory
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Top Polling-Sensitive Issues")
                        Spacer()
                        if let candidate = activeCandidate {
                            Text(candidate.displayRaceTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Tap an issue to filter news articles. Correlation shows polling movement tied to news volume.")
                        .font(.caption)
                }
            } else {
                Section("Issue Analysis") {
                    Label(
                        "Issue correlation data will appear here once news data is loaded.",
                        systemImage: "chart.bar.xaxis"
                    )
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
            }

            // MARK: Conflict Alerts
            if !conflictedArticles.isEmpty {
                Section {
                    ForEach(conflictedArticles.prefix(3)) { article in
                        NewsArticleRow(article: article, showConflictBadge: true)
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Conflicting Reports (\(conflictedArticles.count))")
                    }
                } footer: {
                    Text("These articles have conflicting coverage from Tier-1 sources. Polling impact is dampened by 75%.")
                        .font(.caption)
                }
            }

            // MARK: News Feed
            Section {
                // Filter controls
                HStack {
                    Button {
                        withAnimation { showingConflictsOnly.toggle() }
                    } label: {
                        Label(
                            showingConflictsOnly ? "All Articles" : "Conflicts Only",
                            systemImage: showingConflictsOnly ? "line.3.horizontal.decrease.circle.fill" : "exclamationmark.triangle"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(showingConflictsOnly ? .orange : .secondary)

                    Spacer()

                    if selectedCategory != nil {
                        Button {
                            withAnimation { selectedCategory = nil }
                        } label: {
                            Label("Clear Filter", systemImage: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
                .listRowBackground(Color.clear)

                if newsService.isLoading {
                    HStack {
                        ProgressView()
                        Text("Fetching news…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if filteredArticles.isEmpty {
                    ContentUnavailableView(
                        selectedCategory != nil ? "No Articles in This Category" : "No Articles Yet",
                        systemImage: "newspaper",
                        description: Text(activeRaceId.isEmpty
                            ? "Add a candidate first, then tap refresh."
                            : "Pull to refresh or check your NewsAPI key in Settings.")
                    )
                } else {
                    ForEach(filteredArticles.prefix(30)) { article in
                        NewsArticleRow(article: article, showConflictBadge: false)
                    }
                }
            } header: {
                HStack {
                    Text(selectedCategory.map { "Articles: \($0.rawValue)" } ?? "Recent News")
                    Spacer()
                    if let lastFetch = newsService.lastFetchDate {
                        Text(RelativeDateTimeFormatter().localizedString(for: lastFetch, relativeTo: Date()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .refreshable {
            await newsService.fetchAllIssueNews(raceIds: gameState.userCandidates.map(\.raceId))
        }
        .onAppear {
            if newsService.articles.isEmpty {
                Task {
                    await newsService.fetchAllIssueNews(raceIds: gameState.userCandidates.map(\.raceId))
                }
            }
        }
    }
}

// MARK: - Issue Correlation Row

struct IssueCorrelationRow: View {
    let correlation: PollIssueCorrelation
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: correlation.issueCategory.icon)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 24)

                Text(correlation.issueCategory.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(correlation.strengthLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    Text("\(correlation.recentNewsCount) articles")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }

            // Correlation bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isSelected ? Color.white : correlationBarColor)
                        .frame(width: geo.size.width * min(abs(correlation.correlationCoefficient), 1.0))
                }
            }
            .frame(height: 6)

            HStack {
                Text("r = \(correlation.formattedCoefficient)")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                Spacer()
                Text("\(String(format: "%.2f", correlation.pollingSwingPerEvent))pp/event")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, isSelected ? 8 : 0)
        .background(isSelected ? Color.blue.opacity(0.8) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var correlationBarColor: Color {
        let absR = abs(correlation.correlationCoefficient)
        switch absR {
        case 0.7...: return .red
        case 0.4...: return .orange
        case 0.2...: return .yellow
        default:     return .gray
        }
    }
}

// MARK: - News Article Row

struct NewsArticleRow: View {
    let article: NewsArticle
    let showConflictBadge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Source + tier badge
            HStack(spacing: 6) {
                TierBadge(tier: article.sourceTier)

                Text(article.source)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(article.publishedDisplay)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Headline
            Text(article.headline)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundStyle(article.conflictsWithOtherSources ? .orange : .primary)

            // Issue category + impact
            HStack(spacing: 8) {
                Label(article.classifiedIssue.rawValue, systemImage: article.classifiedIssue.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if article.estimatedPollingImpact != 0 {
                    Text(article.impactDisplay)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(article.estimatedPollingImpact > 0 ? .blue : .red)
                }

                if (showConflictBadge || article.conflictsWithOtherSources) && article.conflictsWithOtherSources {
                    Label("Conflict", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if !article.isValidated {
                    Label("Unvalidated", systemImage: "questionmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: NewsSourceTier

    var body: some View {
        Text(tier.label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color(hex: tier.badgeColorHex).opacity(0.2))
            .foregroundStyle(Color(hex: tier.badgeColorHex) ?? .gray)
            .clipShape(Capsule())
    }

    private func Color(hex: String) -> SwiftUI.Color? {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        return SwiftUI.Color(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue:  Double(value & 0xFF) / 255
        )
    }
}

#Preview {
    IssueTrackerView(gameState: GameState())
}
