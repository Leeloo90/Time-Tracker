//
//  Settings.swift
//  AutoTime
//
//  Manages user preferences and settings
//

import Foundation
import Combine
import SwiftUI

class AppSettings: ObservableObject {
    // Singleton instance
    static let shared = AppSettings()

    // Published settings that trigger UI updates
    @Published var blacklistedApps: [String] { didSet { saveSettings() } }
    @Published var idleThresholdMinutes: Double { didSet { saveSettings() } }
    @Published var stickyThresholdSeconds: Double { didSet { saveSettings() } }
    @Published var companyList: [String] { didSet { saveSettings() } }
    @Published var allocationList: [String] { didSet { saveSettings() } }

    // Keys for UserDefaults
    private let blacklistKey = "autotime_blacklist"
    private let idleThresholdKey = "autotime_idle_threshold"
    private let stickyThresholdKey = "autotime_sticky_threshold"
    private let companyListKey = "autotime_company_list"
    private let allocationListKey = "autotime_allocation_list"

    // Default values
    private let defaultBlacklist = ["Finder", "System Settings", "Activity Monitor", "System Preferences", "AutoTime", "AutoTime macOS"]
    private let defaultCompanies = ["CORE", "Hudson & Meadow", "Freelance"]
    private let defaultAllocations = ["Production", "Editing", "Unassigned"]

    private init() {
        // Load saved settings or use defaults
        self.blacklistedApps = UserDefaults.standard.stringArray(forKey: blacklistKey) ?? defaultBlacklist
        self.companyList = UserDefaults.standard.stringArray(forKey: companyListKey) ?? defaultCompanies
        self.allocationList = UserDefaults.standard.stringArray(forKey: allocationListKey) ?? defaultAllocations
        
        let savedIdle = UserDefaults.standard.double(forKey: idleThresholdKey)
        self.idleThresholdMinutes = savedIdle > 0 ? savedIdle : 5.0

        let savedSticky = UserDefaults.standard.double(forKey: stickyThresholdKey)
        self.stickyThresholdSeconds = savedSticky > 0 ? savedSticky : 10.0
    }

    private func saveSettings() {
        UserDefaults.standard.set(blacklistedApps, forKey: blacklistKey)
        UserDefaults.standard.set(idleThresholdMinutes, forKey: idleThresholdKey)
        UserDefaults.standard.set(stickyThresholdSeconds, forKey: stickyThresholdKey)
        UserDefaults.standard.set(companyList, forKey: companyListKey)
        UserDefaults.standard.set(allocationList, forKey: allocationListKey)
    }

    // Computed properties for easy access
    var idleThresholdSeconds: TimeInterval {
        return idleThresholdMinutes * 60.0
    }

    var stickyThreshold: TimeInterval {
        return stickyThresholdSeconds
    }

    // MARK: - Helper Methods

    func isBlacklisted(_ appName: String) -> Bool {
        return blacklistedApps.contains { appName.contains($0) }
    }

    func addToBlacklist(_ appName: String) {
        if !blacklistedApps.contains(appName) {
            blacklistedApps.append(appName)
        }
    }

    func removeFromBlacklist(_ name: String) {
        blacklistedApps.removeAll { $0 == name }
    }
    
    // Company List Helpers
    func addCompany(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !companyList.contains(name) else { return }
        companyList.append(name)
        companyList.sort()
    }

    func removeCompany(_ name: String) {
        // Prevent deleting the default value
        guard name != "Pending" else { return }
        companyList.removeAll { $0 == name }
    }
    
    // Allocation List Helpers
    func addAllocation(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, !allocationList.contains(name) else { return }
        allocationList.append(name)
        allocationList.sort()
    }
    
    func removeAllocation(_ name: String) {
        // Prevent deleting the default value
        guard name != "Unassigned" else { return }
        allocationList.removeAll { $0 == name }
    }

    func resetToDefaults() {
        blacklistedApps = defaultBlacklist
        idleThresholdMinutes = 5.0
        stickyThresholdSeconds = 10.0
        companyList = defaultCompanies
        allocationList = defaultAllocations
    }
}
