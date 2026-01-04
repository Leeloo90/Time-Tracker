//
//  AppDelegate.swift
//  AutoTime
//
//  Handles menu bar integration, app lifecycle, and permission synchronization.
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
    // Cache last icon state to avoid unnecessary layout updates
    private var lastIconState: String? = nil

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize trackers
        appMonitor = AppMonitor()
        activityTracker = ActivityTracker()
        idleMonitor = IdleMonitor()

        // Setup menu bar item
        setupMenuBar()

        // Set initial icon color (white/default - not tracking)
        updateMenuBarIcon()

        // Check for Accessibility permissions on launch
        checkAccessibilityPermissions()

        // Setup monitors with a small delay to ensure the UI is ready before data starts flowing
        // and to avoid layout recursion errors during app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.setupMonitors()
        }
        
        print("🚀 AutoTime started - monitors active")
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "AutoTime")
        }

        let menu = NSMenu()

        // 1. Live Status Header
        let statusItem = NSMenuItem(
            title: activityTracker.isTracking ? "Tracking Active" : "Idle",
            action: nil,
            keyEquivalent: ""
        )
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Control Actions
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

        // 3. Quit Action
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
        // App Switch Callback - connects app detection to tracking logic
        appMonitor.onAppChange = { [weak self] app, windowTitle in
            guard let self = self, self.activityTracker.isTracking else { return }
            self.activityTracker.handleAppSwitch(app: app, windowTitle: windowTitle)
        }

        appMonitor.startMonitoring()

        // User Input / Idle Reset
        idleMonitor.onUserInput = { [weak self] in
            guard let self = self else { return }
            self.activityTracker.recordUserInput()

            if self.isIdle {
                self.isIdle = false
                self.updateMenuBarIcon()
                self.updateMenuBar()
            }
        }
        idleMonitor.startMonitoring()

        // Periodic Idle Checker (Frequency based on settings)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    func checkAccessibilityPermissions() {
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "AutoTime needs Accessibility permissions to capture window titles for your timeline. Please grant permission in System Settings."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
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
        startupWindow?.level = .floating

        // Defer showing the window to avoid layout recursion during state changes
        DispatchQueue.main.async { [weak self] in
            self?.startupWindow?.makeKeyAndOrderFront(nil)
        }
    }

    @objc func showDashboard() {
        if dashboardWindow == nil {
            let dashboardView = DashboardView(tracker: activityTracker)
            let hostingController = NSHostingController(rootView: dashboardView)

            dashboardWindow = NSWindow(contentViewController: hostingController)
            dashboardWindow?.title = "AutoTime Dashboard"
            dashboardWindow?.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            dashboardWindow?.setContentSize(NSSize(width: 1200, height: 700))
            dashboardWindow?.center()
            dashboardWindow?.level = .floating // Keep window on top
        }
        dashboardWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "AutoTime Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.setContentSize(NSSize(width: 600, height: 600))
            settingsWindow?.center()
            settingsWindow?.level = .floating // Keep window on top
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
        guard let _ = statusItem?.button else { return }

        // Compute a simple state string and early-return if nothing changed
        let state: String
        if !activityTracker.isTracking {
            state = "label"
        } else if isIdle {
            state = "idle"
        } else {
            state = "active"
        }

        if state == lastIconState { return }
        lastIconState = state

        let iconColor: NSColor
        switch state {
        case "label": iconColor = .labelColor
        case "idle": iconColor = .systemOrange
        default: iconColor = .systemGreen
        }

        let config = NSImage.SymbolConfiguration(pointSize: 0, weight: .bold)
            .applying(.init(hierarchicalColor: iconColor))

        // Update the status item on the next runloop cycle to avoid layout recursion
        DispatchQueue.main.async { [weak self] in
            guard let button = self?.statusItem?.button else { return }
            if let image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "AutoTime") {
                button.image = image.withSymbolConfiguration(config)
            }
        }
    }

    func checkIdleState() {
        guard activityTracker.isTracking else { return }

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
        appMonitor?.stopMonitoring()
        idleMonitor?.stopMonitoring()
    }
}
