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
    private var lastInputTime: Date = Date()
    private var blacklistedStartTime: Date?

    private var timer: Timer?

    // Constants
    private let stickyThresholdSeconds: TimeInterval = 300 // 5 minutes
    private let idleThresholdSeconds: TimeInterval = 300 // 5 minutes

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
        guard isTracking else { return }

        let now = Date()
        lastInputTime = now

        let project = WindowTitleParser.parseProject(app: app, title: windowTitle)

        // Handle blacklisted apps
        if AppMonitor.blacklistedApps.contains(app) {
            if blacklistedStartTime == nil {
                blacklistedStartTime = now
            }
            return
        }

        // Clear blacklist timer if we switched back to a tracked app
        blacklistedStartTime = nil

        // First activity
        if currentActivityState == nil {
            currentActivityState = ActivityState(app: app, project: project, startTime: now, lastActive: now)
            currentActivity = currentActivityState
            return
        }

        // Return to current primary app (cancel pending switch)
        if app == currentActivityState?.app {
            pendingSwitchState = nil
            pendingSwitch = nil
            return
        }

        // Secondary app switch - start pending
        if pendingSwitchState?.app != app {
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
        if now.timeIntervalSince(lastInputTime) > idleThresholdSeconds {
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
            if now.timeIntervalSince(blacklistStart) > idleThresholdSeconds {
                print("🚫 Blacklisted app active for 5+ min - terminating session")
                if let current = currentActivityState {
                    addEntry(from: current, endTime: blacklistStart)
                }
                currentActivityState = nil
                blacklistedStartTime = nil
                currentActivity = nil
            }
        }

        // 3. Sticky Logic (5-minute rule)
        if let pending = pendingSwitchState {
            let timeSpent = now.timeIntervalSince(pending.switchTime)

            if timeSpent > stickyThresholdSeconds {
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
        // Skip tiny entries (< 10 seconds)
        guard endTime.timeIntervalSince(activity.startTime) >= 10 else { return }

        let entry = TimeEntry(
            company: currentCompany.isEmpty ? "Pending" : currentCompany,
            allocation: currentAllocation.isEmpty ? "Unassigned" : currentAllocation,
            application: activity.app,
            project: activity.project,
            timeStart: activity.startTime,
            timeFinish: endTime
        )

        entries.insert(entry, at: 0)
        saveEntries()
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
