//
//  ActivityTracker.swift
//  AutoTime
//
//  Implements the core tracking logic with 5-minute sticky rule
//

import Foundation
import Combine

struct ActivityState {
    let app: String
    let project: String
    let startTime: Date
    var lastActive: Date
}

struct PendingSwitch {
    let app: String
    let project: String
    let switchTime: Date
}

class ActivityTracker: ObservableObject {
    @Published var entries: [TimeEntry] = []
    @Published var isTracking = false
    @Published var currentActivity: ActivityState?
    @Published var pendingSwitch: PendingSwitch?

    var currentCompany: String = ""
    var currentAllocation: String = ""

    private var currentActivityState: ActivityState?
    private var pendingSwitchState: PendingSwitch?
    var lastInputTime: Date = Date() // Public so AppDelegate can check idle state
    private var blacklistedStartTime: Date?

    private var timer: Timer?
    private let settings = AppSettings.shared

    init() {
        loadEntries()
    }

    func startTracking(company: String, allocation: String) {
        currentCompany = company
        currentAllocation = allocation
        isTracking = true
        lastInputTime = Date()

        // Start the logic timer (runs every second)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.processLogic()
        }
    }

    func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil

        // Close current session
        if let current = currentActivityState {
            addEntry(from: current, endTime: Date())
        }

        currentActivityState = nil
        pendingSwitchState = nil
        blacklistedStartTime = nil
        currentActivity = nil
        pendingSwitch = nil
    }

    func handleAppSwitch(app: String, windowTitle: String) {
        let now = Date()
        lastInputTime = now

        let project = WindowTitleParser.parseProject(app: app, title: windowTitle)
        print("📱 App/Window change: \(app) | Project: \(project)")

        // Handle blacklisted apps
        if settings.isBlacklisted(app) {
            print("🚫 Blacklisted app detected: \(app)")
            if blacklistedStartTime == nil {
                blacklistedStartTime = now
            }
            return
        }

        // Clear blacklist timer if we switched back to a tracked app
        blacklistedStartTime = nil

        // First activity
        if currentActivityState == nil {
            print("🆕 First activity started: \(app) - \(project)")
            currentActivityState = ActivityState(app: app, project: project, startTime: now, lastActive: now)
            currentActivity = currentActivityState
            return
        }

        // Check if we're in the same app AND same project (e.g., same Chrome tab)
        if app == currentActivityState?.app && project == currentActivityState?.project {
            print("↩️ Same app and project, canceling any pending switch")
            pendingSwitchState = nil
            pendingSwitch = nil
            return
        }

        // Check if we're in the same app but DIFFERENT project (e.g., different Chrome tab)
        if app == currentActivityState?.app && project != currentActivityState?.project {
            // This is a window/tab switch within the same app
            // Treat it the same as an app switch - start pending
            if pendingSwitchState?.app != app || pendingSwitchState?.project != project {
                print("📑 Window/tab switch within \(app): \(currentActivityState?.project ?? "") → \(project)")
                pendingSwitchState = PendingSwitch(app: app, project: project, switchTime: now)
                pendingSwitch = pendingSwitchState
            }
            return
        }

        // Different app - start pending switch
        if pendingSwitchState?.app != app || pendingSwitchState?.project != project {
            print("⏳ Starting pending switch to: \(app) - \(project)")
            pendingSwitchState = PendingSwitch(app: app, project: project, switchTime: now)
            pendingSwitch = pendingSwitchState
        }
    }

    func recordUserInput() {
        lastInputTime = Date()
    }

    private func processLogic() {
        let now = Date()

        // 1. Idle Detection
        if now.timeIntervalSince(lastInputTime) > settings.idleThresholdSeconds {
            if let current = currentActivityState {
                print("💤 Idle detected - closing session")
                addEntry(from: current, endTime: lastInputTime)
                currentActivityState = nil
                pendingSwitchState = nil
                currentActivity = nil
                pendingSwitch = nil
            }
            return
        }

        // 2. Blacklist Logic
        if let blacklistStart = blacklistedStartTime {
            if now.timeIntervalSince(blacklistStart) > settings.idleThresholdSeconds {
                print("🚫 Blacklisted app active for 5+ min - terminating session")
                if let current = currentActivityState {
                    addEntry(from: current, endTime: blacklistStart)
                }
                currentActivityState = nil
                blacklistedStartTime = nil
                currentActivity = nil
            }
        }

        // 3. Sticky Logic
        if let pending = pendingSwitchState {
            let timeSpent = now.timeIntervalSince(pending.switchTime)

            if timeSpent > settings.stickyThreshold {
                print("✅ Sticky threshold exceeded - committing switch")

                // Close current activity at the switch time
                if let current = currentActivityState {
                    addEntry(from: current, endTime: pending.switchTime)
                }

                // Start new activity from the switch time
                currentActivityState = ActivityState(
                    app: pending.app,
                    project: pending.project,
                    startTime: pending.switchTime,
                    lastActive: now
                )
                pendingSwitchState = nil

                currentActivity = currentActivityState
                pendingSwitch = nil
            }
        }
    }

    private func addEntry(from activity: ActivityState, endTime: Date) {
        let duration = endTime.timeIntervalSince(activity.startTime)

        // Skip tiny entries (< 10 seconds)
        guard duration >= 10 else {
            print("⏭ Skipping tiny entry (\(Int(duration))s) for \(activity.app)")
            return
        }

        let entry = TimeEntry(
            company: currentCompany.isEmpty ? "Pending" : currentCompany,
            allocation: currentAllocation.isEmpty ? "Unassigned" : currentAllocation,
            application: activity.app,
            project: activity.project,
            timeStart: activity.startTime,
            timeFinish: endTime
        )

        print("💾 Adding entry: \(activity.app) - \(Int(duration))s")
        entries.insert(entry, at: 0)
        saveEntries()
        print("✅ Entry saved! Total entries: \(entries.count)")
    }

    // MARK: - Persistence

    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "autotime_entries")
        }
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "autotime_entries"),
           let decoded = try? JSONDecoder().decode([TimeEntry].self, from: data) {
            entries = decoded
        }
    }

    func updateEntry(_ entry: TimeEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }

    func deleteEntry(_ entry: TimeEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
}
