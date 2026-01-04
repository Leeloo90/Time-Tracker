//
//  AutoTimeApp.swift
//  AutoTime
//
//  Main application entry point
//

import SwiftUI

@main
struct AutoTimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
