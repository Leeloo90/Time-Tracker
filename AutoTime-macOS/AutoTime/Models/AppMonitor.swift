//
//  AppMonitor.swift
//  AutoTime
//
//  Monitors active applications using NSWorkspace
//

import Foundation
import AppKit

class AppMonitor: ObservableObject {
    @Published var currentApp: String = ""
    @Published var currentWindowTitle: String = ""

    private var workspace = NSWorkspace.shared
    private var observer: NSObjectProtocol?

    // Blacklisted apps that should not be tracked
    static let blacklistedApps = ["Finder", "System Settings", "Activity Monitor", "System Preferences"]

    func startMonitoring() {
        // Initial state
        updateCurrentApp()

        // Observe app activation changes
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateCurrentApp()
        }
    }

    func stopMonitoring() {
        if let observer = observer {
            workspace.notificationCenter.removeObserver(observer)
        }
    }

    private func updateCurrentApp() {
        guard let frontApp = workspace.frontmostApplication else { return }

        currentApp = frontApp.localizedName ?? "Unknown"
        currentWindowTitle = getWindowTitle(for: frontApp) ?? ""

        print("🔍 Active App: \(currentApp) | Window: \(currentWindowTitle)")
    }

    private func getWindowTitle(for app: NSRunningApplication) -> String? {
        // This requires Accessibility permissions
        guard AXIsProcessTrusted() else {
            print("⚠️ Accessibility permissions not granted")
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?

        // Get the focused window
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowRef
        )

        guard result == .success, let window = windowRef else {
            return nil
        }

        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(
            window as! AXUIElement,
            kAXTitleAttribute as CFString,
            &titleRef
        )

        if titleResult == .success, let title = titleRef as? String {
            return title
        }

        return nil
    }

    func isBlacklisted(_ appName: String) -> Bool {
        return AppMonitor.blacklistedApps.contains(appName)
    }

    deinit {
        stopMonitoring()
    }
}
