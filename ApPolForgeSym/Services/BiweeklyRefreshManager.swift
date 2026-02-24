//
//  BiweeklyRefreshManager.swift
//  ApPolForgeSym
//
//  Created as part of PolForge Expansion Plan.
//
//  Manages bi-weekly Firestore data refreshes.
//  On iOS/iPadOS: uses BGAppRefreshTask (requires background fetch entitlement).
//  On macOS/visionOS: uses a Timer-based fallback.
//
//  SETUP REQUIRED (iOS/iPadOS):
//  1. Add "Background fetch" capability in Xcode target settings.
//  2. ApPolForgeSym.entitlements must include:
//       com.apple.developer.background-modes: [fetch]
//  3. In ApPolForgeSymApp.init(), register the task before the first
//     runloop iteration (already done in ApPolForgeSymApp.swift).
//

import Foundation
import Combine

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

// MARK: - Biweekly Refresh Manager

@MainActor
final class BiweeklyRefreshManager: ObservableObject {
    static let shared = BiweeklyRefreshManager()

    static let bgTaskIdentifier = "com.appolforgesym.biweeklyrefresh"

    @Published var isRefreshing: Bool = false
    @Published var lastRefreshDate: Date?
    @Published var nextScheduledRefresh: Date?

    private let refreshIntervalDays: Double = 14
    private var timerCancellable: AnyCancellable?

    private var refreshIntervalSeconds: TimeInterval {
        refreshIntervalDays * 24 * 3600
    }

    private init() {
        // Restore last refresh date from UserDefaults
        if let ts = UserDefaults.standard.object(forKey: "lastFirestoreSync") as? TimeInterval {
            lastRefreshDate = Date(timeIntervalSince1970: ts)
        }
        computeNextSchedule()
    }

    // MARK: - Registration (call from App.init before Scene)

    /// Register the background task identifier with BGTaskScheduler.
    /// Must be called before the first scene is created.
    static func registerBackgroundTask() {
        #if canImport(BackgroundTasks) && (os(iOS) || os(iPadOS))
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: bgTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await BiweeklyRefreshManager.shared.handleBackgroundRefresh(task: refreshTask)
            }
        }
        #endif
    }

    // MARK: - Scheduling

    /// Schedule the next bi-weekly background refresh.
    func scheduleNextRefresh() {
        guard AppSettings.shared.biweeklyRefreshEnabled else { return }

        let earliestBegin = (lastRefreshDate ?? Date()).addingTimeInterval(refreshIntervalSeconds)
        nextScheduledRefresh = earliestBegin

        #if canImport(BackgroundTasks) && (os(iOS) || os(iPadOS))
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        request.earliestBeginDate = earliestBegin
        try? BGTaskScheduler.shared.submit(request)
        #else
        // macOS/visionOS fallback: use a local timer
        scheduleTimerRefresh(after: max(0, earliestBegin.timeIntervalSinceNow))
        #endif
    }

    /// Trigger an immediate manual refresh (e.g. pull-to-refresh in LivePollDashboardView).
    func performManualRefresh(raceIds: [String]) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            lastRefreshDate = Date()
            UserDefaults.standard.set(lastRefreshDate!.timeIntervalSince1970, forKey: "lastFirestoreSync")
            scheduleNextRefresh()
        }

        await FirestoreService.shared.performFullRefresh(raceIds: raceIds)
    }

    // MARK: - Background Task Handler

    #if canImport(BackgroundTasks) && (os(iOS) || os(iPadOS))
    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        // Schedule the next fetch immediately so the chain continues
        scheduleNextRefresh()

        // Set expiration handler
        task.expirationHandler = {
            Task { @MainActor in
                self.isRefreshing = false
            }
        }

        let activeRaceId = AppSettings.shared.activeRaceId
        let raceIds = activeRaceId.isEmpty ? [] : [activeRaceId]

        await performManualRefresh(raceIds: raceIds)
        task.setTaskCompleted(success: true)
    }
    #endif

    // MARK: - Timer Fallback (macOS/visionOS)

    private func scheduleTimerRefresh(after delay: TimeInterval) {
        timerCancellable?.cancel()
        timerCancellable = Just(())
            .delay(for: .seconds(delay), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let activeRaceId = AppSettings.shared.activeRaceId
                    let raceIds = activeRaceId.isEmpty ? [] : [activeRaceId]
                    await self.performManualRefresh(raceIds: raceIds)
                }
            }
    }

    // MARK: - Helpers

    private func computeNextSchedule() {
        guard let last = lastRefreshDate else {
            nextScheduledRefresh = Date()
            return
        }
        nextScheduledRefresh = last.addingTimeInterval(refreshIntervalSeconds)
    }

    var isDueForRefresh: Bool {
        guard let next = nextScheduledRefresh else { return true }
        return Date() >= next
    }
}
