//
//  Settings.swift
//  AutoTime
//
//  Manages user preferences and settings
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    // Singleton instance
    static let shared = AppSettings()

    // Published settings that trigger UI updates
    @Published var blacklistedApps: [String] {
        didSet { saveSettings() }
    }

    @Published var idleThresholdMinutes: Double {
        didSet { saveSettings() }
    }

    @Published var stickyThresholdSeconds: Double {
        didSet { saveSettings() }
    }

    // Keys for UserDefaults
    private let blacklistKey = "autotime_blacklist"
    private let idleThresholdKey = "autotime_idle_threshold"
    private let stickyThresholdKey = "autotime_sticky_threshold"

    // Default blacklisted apps
    private let defaultBlacklist = [
        "Finder",
        "System Settings",
        "Activity Monitor",
        "System Preferences",
        "AutoTime",
        "AutoTime macOS"
    ]

    private init() {
        // Load saved settings or use defaults
        if let savedBlacklist = UserDefaults.standard.stringArray(forKey: blacklistKey) {
            self.blacklistedApps = savedBlacklist
        } else {
            self.blacklistedApps = defaultBlacklist
        }

        // Idle threshold in minutes (default: 5 minutes)
        let savedIdle = UserDefaults.standard.double(forKey: idleThresholdKey)
        self.idleThresholdMinutes = savedIdle > 0 ? savedIdle : 5.0

        // Sticky threshold in seconds (default: 10 seconds)
        let savedSticky = UserDefaults.standard.double(forKey: stickyThresholdKey)
        self.stickyThresholdSeconds = savedSticky > 0 ? savedSticky : 10.0
    }

    private func saveSettings() {
        UserDefaults.standard.set(blacklistedApps, forKey: blacklistKey)
        UserDefaults.standard.set(idleThresholdMinutes, forKey: idleThresholdKey)
        UserDefaults.standard.set(stickyThresholdSeconds, forKey: stickyThresholdKey)
    }

    // Computed properties for easy access
    var idleThresholdSeconds: TimeInterval {
        return idleThresholdMinutes * 60.0
    }

    var stickyThreshold: TimeInterval {
        return stickyThresholdSeconds
    }

    // Helper methods
    func isBlacklisted(_ appName: String) -> Bool {
        return blacklistedApps.contains { appName.contains($0) }
    }

    func addToBlacklist(_ appName: String) {
        if !blacklistedApps.contains(appName) {
            blacklistedApps.append(appName)
        }
    }

    func removeFromBlacklist(_ appName: String) {
        blacklistedApps.removeAll { $0 == appName }
    }

    func resetToDefaults() {
        blacklistedApps = defaultBlacklist
        idleThresholdMinutes = 5.0
        stickyThresholdSeconds = 10.0
    }
}
