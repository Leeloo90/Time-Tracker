//
//  AppMonitor.swift
//  AutoTime
//
//  Monitors active applications and extracts window titles using a hybrid approach.
//

import Foundation
import AppKit
import Combine

class AppMonitor: ObservableObject {
    @Published var currentApp: String = ""
    @Published var currentWindowTitle: String = ""

    private var workspace = NSWorkspace.shared
    private var observer: NSObjectProtocol?
    private var pollTimer: Timer?

    private var lastTrackedApp: String = ""
    private var lastTrackedWindow: String = ""

    var onAppChange: ((String, String) -> Void)?

    func startMonitoring() {
        updateCurrentApp()

        // Observe app activation changes (when switching apps)
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentApp()
        }

        // Poll for window title changes within the same app (e.g., tab switches)
        // Check every 2 seconds for window title changes
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForWindowChanges()
        }
    }

    func stopMonitoring() {
        if let observer = observer {
            workspace.notificationCenter.removeObserver(observer)
        }
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func updateCurrentApp() {
        guard let frontApp = workspace.frontmostApplication else { return }

        let appName = frontApp.localizedName ?? "Unknown"
        let windowTitle = getWindowTitle(for: frontApp)

        self.currentApp = appName
        self.currentWindowTitle = windowTitle ?? ""

        // Track what we last reported
        lastTrackedApp = appName
        lastTrackedWindow = windowTitle ?? ""

        // Only call the callback (which will check if tracking is active)
        onAppChange?(currentApp, currentWindowTitle)
    }

    private func checkForWindowChanges() {
        guard let frontApp = workspace.frontmostApplication else { return }

        let appName = frontApp.localizedName ?? "Unknown"
        let windowTitle = getWindowTitle(for: frontApp) ?? ""

        // Only trigger callback if app or window title changed
        if appName != lastTrackedApp || windowTitle != lastTrackedWindow {
            self.currentApp = appName
            self.currentWindowTitle = windowTitle

            lastTrackedApp = appName
            lastTrackedWindow = windowTitle

            // Trigger the callback with updated info
            onAppChange?(appName, windowTitle)
        }
    }

    /// Hybrid strategy to get window title
    func getWindowTitle(for app: NSRunningApplication) -> String? {
        let appName = app.localizedName ?? ""
        let pid = app.processIdentifier

        // 1. STRATEGY: Quartz Window Services (Best for DaVinci Resolve)
        // Works even if Accessibility is being difficult
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        if let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for entry in windowListInfo {
                let windowPid = entry[kCGWindowOwnerPID as String] as? pid_t
                let layer = entry[kCGWindowLayer as String] as? Int ?? 0
                
                // Layer 0 is the standard UI layer. We want the window belonging to our active PID.
                if windowPid == pid && layer == 0 {
                    if let title = entry[kCGWindowName as String] as? String, !title.isEmpty {
                        return title
                    }
                }
            }
        }

        // 2. STRATEGY: AppleScript (Best for Browsers)
        if appName.contains("Chrome") || appName.contains("Safari") {
            let scriptSource: String
            if appName.contains("Chrome") {
                scriptSource = "tell application \"Google Chrome\" to return title of active tab of front window"
            } else {
                scriptSource = "tell application \"Safari\" to return name of front document"
            }
            
            if let script = NSAppleScript(source: scriptSource) {
                var error: NSDictionary?
                let result = script.executeAndReturnError(&error)
                if error == nil, let title = result.stringValue, !title.isEmpty {
                    return title
                }
            }
        }

        // 3. STRATEGY: Accessibility API (Standard fallback)
        if AXIsProcessTrusted() {
            let axApp = AXUIElementCreateApplication(pid)
            var value: CFTypeRef?
            
            // Try focused window
            if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success {
                let windowElement = value as! AXUIElement
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef) == .success {
                    return titleRef as? String
                }
            }
        }

        return nil
    }

    deinit {
        stopMonitoring()
    }
}
