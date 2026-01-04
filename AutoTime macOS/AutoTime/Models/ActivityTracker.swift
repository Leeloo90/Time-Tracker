//
//  ActivityTracker.swift
//  AutoTime
//
//  Core tracking logic updated for Timeline Visualizer and Advanced Filtering.
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
    var lastInputTime: Date = Date()
    private var blacklistedStartTime: Date?

    private var timer: Timer?
    private let settings = AppSettings.shared

    init() {
        loadEntries()
    }

    // MARK: - Filtering Helpers for Dashboard View

    /// Returns entries filtered by a specific day and an optional time range within that day.
    func getEntries(for date: Date, startSeconds: Double = 0, endSeconds: Double = 86400) -> [TimeEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            // 1. Match the Day
            let isSameDay = calendar.isDate(entry.timeStart, inSameDayAs: date)
            
            // 2. Match the Seconds Range within that day
            let startOfDay = calendar.startOfDay(for: date)
            let entryStartSec = entry.timeStart.timeIntervalSince(startOfDay)
            let entryFinishSec = entry.timeFinish.timeIntervalSince(startOfDay)
            
            let inRange = (entryStartSec >= startSeconds && entryStartSec <= endSeconds) ||
                          (entryFinishSec >= startSeconds && entryFinishSec <= endSeconds)
            
            return isSameDay && inRange
        }
    }

    // MARK: - Tracking Logic

    func startTracking(company: String, allocation: String) {
        currentCompany = company
        currentAllocation = allocation
        isTracking = true
        lastInputTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.processLogic()
        }
    }

    func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil

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

        // 1. Handle Blacklisted Apps (Treat as Idle)
        if ["Finder", "System Settings", "Music"].contains(app) {
            if blacklistedStartTime == nil { blacklistedStartTime = now }
            return
        }
        blacklistedStartTime = nil

        // 2. Handle Initial Activity
        if currentActivityState == nil {
            currentActivityState = ActivityState(app: app, project: project, startTime: now, lastActive: now)
            currentActivity = currentActivityState
            return
        }

        // 3. Handle returning to the active session (cancel pending)
        if app == currentActivityState?.app && project == currentActivityState?.project {
            pendingSwitchState = nil
            pendingSwitch = nil
            return
        }

        // 4. Handle Switch (Different App OR Different Project/Tab in same app)
        if pendingSwitchState?.app != app || pendingSwitchState?.project != project {
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
                addEntry(from: current, endTime: lastInputTime)
                clearActiveSession()
            }
            return
        }

        // 2. Blacklist Duration Logic
        if let blacklistStart = blacklistedStartTime, now.timeIntervalSince(blacklistStart) > settings.idleThresholdSeconds {
            if let current = currentActivityState { addEntry(from: current, endTime: blacklistStart) }
            clearActiveSession()
            blacklistedStartTime = nil
        }

        // 3. Sticky Logic Implementation
        if let pending = pendingSwitchState {
            if now.timeIntervalSince(pending.switchTime) > settings.stickyThreshold {
                if let current = currentActivityState {
                    addEntry(from: current, endTime: pending.switchTime)
                }

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

    private func clearActiveSession() {
        currentActivityState = nil
        pendingSwitchState = nil
        currentActivity = nil
        pendingSwitch = nil
    }

    private func addEntry(from activity: ActivityState, endTime: Date) {
        let duration = endTime.timeIntervalSince(activity.startTime)
        guard duration >= 10 else { return } // Ignore noise shorter than 10s

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

    // MARK: - Persistence & Updates

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
