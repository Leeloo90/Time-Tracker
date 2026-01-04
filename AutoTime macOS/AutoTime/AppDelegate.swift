//
//  AppDelegate.swift
//  AutoTime
//
//  Handles menu bar integration and app lifecycle
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    var appMonitor: AppMonitor!
    var activityTracker: ActivityTracker!
    var idleMonitor: IdleMonitor!

    var dashboardWindow: NSWindow?
    var startupWindow: NSWindow?
    var settingsWindow: NSWindow?

    var isIdle: Bool = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize trackers
        appMonitor = AppMonitor()
        activityTracker = ActivityTracker()
        idleMonitor = IdleMonitor()

        // Setup menu bar item
        setupMenuBar()

        // Set initial icon color (white - not tracking)
        updateMenuBarIcon()

        // Check for Accessibility permissions
        checkAccessibilityPermissions()

        // Setup monitors - CRITICAL: This connects app detection to tracking
        setupMonitors()
        print("🚀 AutoTime started - monitors active")
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "AutoTime")
            // No need to set action/target when using menu directly
        }

        // Create menu
        let menu = NSMenu()

        let statusItem = NSMenuItem(
            title: activityTracker.isTracking ? "Tracking Active" : "Idle",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        let startStopItem = NSMenuItem(
            title: activityTracker.isTracking ? "Stop Workday" : "Start Workday",
            action: #selector(toggleTracking),
            keyEquivalent: "s"
        )
        startStopItem.target = self
        menu.addItem(startStopItem)

        let dashboardItem = NSMenuItem(
            title: "Open Dashboard",
            action: #selector(showDashboard),
            keyEquivalent: "d"
        )
        dashboardItem.target = self
        menu.addItem(dashboardItem)

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit AutoTime",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem?.menu = menu
    }

    func setupMonitors() {
        // Setup app change callback - only process if tracking is active
        appMonitor.onAppChange = { [weak self] app, windowTitle in
            guard let self = self, self.activityTracker.isTracking else { return }
            print("🔔 App switch detected: \(app)")
            self.activityTracker.handleAppSwitch(app: app, windowTitle: windowTitle)
        }

        // Start app monitoring
        appMonitor.startMonitoring()

        // Idle monitoring
        idleMonitor.onUserInput = { [weak self] in
            guard let self = self else { return }
            self.activityTracker.recordUserInput()

            // If we were idle and now have input, update icon
            if self.isIdle {
                self.isIdle = false
                self.updateMenuBarIcon()
            }
        }
        idleMonitor.startMonitoring()

        // Start a timer to check for idle state periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "AutoTime needs Accessibility permissions to detect active applications and window titles. Please grant permission in System Settings > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }

    @objc func toggleTracking() {
        if activityTracker.isTracking {
            activityTracker.stopTracking()
            updateMenuBar()
            updateMenuBarIcon()
        } else {
            showStartupModal()
        }
    }

    @objc func showStartupModal() {
        let modalView = StartupModalView(isPresented: .constant(true)) { company, allocation in
            self.activityTracker.startTracking(company: company, allocation: allocation)
            self.updateMenuBar()
            self.updateMenuBarIcon()
            self.startupWindow?.close()
        }

        let hostingController = NSHostingController(rootView: modalView)
        startupWindow = NSWindow(contentViewController: hostingController)
        startupWindow?.title = "Start Workday"
        startupWindow?.styleMask = [.titled, .closable]
        startupWindow?.center()
        startupWindow?.makeKeyAndOrderFront(nil)
        startupWindow?.level = .floating
    }

    @objc func showDashboard() {
        if dashboardWindow == nil {
            let dashboardView = DashboardView(tracker: activityTracker)
            let hostingController = NSHostingController(rootView: dashboardView)

            dashboardWindow = NSWindow(contentViewController: hostingController)
            dashboardWindow?.title = "AutoTime Dashboard"
            dashboardWindow?.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            dashboardWindow?.setContentSize(NSSize(width: 1200, height: 600))
            dashboardWindow?.center()
        }

        dashboardWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "AutoTime Settings"
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            settingsWindow?.setContentSize(NSSize(width: 600, height: 700))
            settingsWindow?.center()
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func updateMenuBar() {
        guard let menu = statusItem?.menu else { return }

        let statusText: String
        if activityTracker.isTracking {
            statusText = isIdle ? "Tracking (Idle) ⏸" : "Tracking Active ●"
        } else {
            statusText = "Not Tracking"
        }

        menu.item(at: 0)?.title = statusText
        menu.item(at: 2)?.title = activityTracker.isTracking ? "Stop Workday" : "Start Workday"
    }

    func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let iconColor: NSColor
        if !activityTracker.isTracking {
            // Not tracking - white/default (system color)
            iconColor = .labelColor
        } else if isIdle {
            // Tracking but idle - orange
            iconColor = .orange
        } else {
            // Tracking and active - green
            iconColor = .systemGreen
        }

        // Create SF Symbol with color
        let config = NSImage.SymbolConfiguration(pointSize: 0, weight: .regular)
            .applying(.init(hierarchicalColor: iconColor))

        if let image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "AutoTime") {
            let coloredImage = image.withSymbolConfiguration(config)
            button.image = coloredImage
        }
    }

    func checkIdleState() {
        guard activityTracker.isTracking else {
            if isIdle {
                isIdle = false
                updateMenuBarIcon()
            }
            return
        }

        let idleThreshold = AppSettings.shared.idleThresholdSeconds
        let timeSinceLastInput = Date().timeIntervalSince(activityTracker.lastInputTime)

        let wasIdle = isIdle
        isIdle = timeSinceLastInput > idleThreshold

        if wasIdle != isIdle {
            updateMenuBar()
            updateMenuBarIcon()
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appMonitor.stopMonitoring()
        idleMonitor.stopMonitoring()
    }
}
