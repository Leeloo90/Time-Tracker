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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize trackers
        appMonitor = AppMonitor()
        activityTracker = ActivityTracker()
        idleMonitor = IdleMonitor()

        // Setup menu bar item
        setupMenuBar()

        // Check for Accessibility permissions
        checkAccessibilityPermissions()

        // Setup monitors
        setupMonitors()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "AutoTime")
            button.action = #selector(toggleMenu)
            button.target = self
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

        menu.addItem(NSMenuItem(
            title: activityTracker.isTracking ? "Stop Workday" : "Start Workday",
            action: #selector(toggleTracking),
            keyEquivalent: "s"
        ))

        menu.addItem(NSMenuItem(
            title: "Open Dashboard",
            action: #selector(showDashboard),
            keyEquivalent: "d"
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit AutoTime",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        self.statusItem?.menu = menu
    }

    func setupMonitors() {
        // App monitoring
        appMonitor.startMonitoring()

        // Listen for app changes
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.activityTracker.handleAppSwitch(
                app: self.appMonitor.currentApp,
                windowTitle: self.appMonitor.currentWindowTitle
            )
        }

        // Idle monitoring
        idleMonitor.onUserInput = { [weak self] in
            self?.activityTracker.recordUserInput()
        }
        idleMonitor.startMonitoring()
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

    @objc func toggleMenu() {
        // Menu is shown automatically
    }

    @objc func toggleTracking() {
        if activityTracker.isTracking {
            activityTracker.stopTracking()
            updateMenuBar()
        } else {
            showStartupModal()
        }
    }

    @objc func showStartupModal() {
        let modalView = StartupModalView(isPresented: .constant(true)) { company, allocation in
            self.activityTracker.startTracking(company: company, allocation: allocation)
            self.updateMenuBar()
            self.startupWindow?.close()
            self.showDashboard()
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

    func updateMenuBar() {
        guard let menu = statusItem?.menu else { return }

        menu.item(at: 0)?.title = activityTracker.isTracking ? "Tracking Active ●" : "Idle"
        menu.item(at: 2)?.title = activityTracker.isTracking ? "Stop Workday" : "Start Workday"
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appMonitor.stopMonitoring()
        idleMonitor.stopMonitoring()
    }
}
