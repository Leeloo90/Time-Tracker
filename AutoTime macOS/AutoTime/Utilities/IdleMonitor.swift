//
//  IdleMonitor.swift
//  AutoTime
//
//  Monitors HID (keyboard/mouse) events for idle detection
//

import Foundation
import Cocoa

class IdleMonitor {
    private var eventMonitor: Any?
    var onUserInput: (() -> Void)?

    func startMonitoring() {
        // Monitor global mouse and keyboard events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .mouseMoved, .keyDown]
        ) { [weak self] event in
            self?.onUserInput?()
        }

        // Also monitor local events (within the app)
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .mouseMoved, .keyDown]) { [weak self] event in
            self?.onUserInput?()
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
