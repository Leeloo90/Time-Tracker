//
//  SettingsView.swift
//  AutoTime
//
//  Settings panel for configuring tracking behavior
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var newAppName = ""
    @State private var showingAddAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Timing Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Timing Thresholds")
                            .font(.headline)

                        // Sticky Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("App Switch Threshold")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(settings.stickyThresholdSeconds)) seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Minimum time on a new app before creating an entry")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Slider(value: $settings.stickyThresholdSeconds, in: 5...300, step: 5)

                            HStack {
                                Text("5s")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("5min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)

                        // Idle Threshold
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Idle Detection Timeout")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(settings.idleThresholdMinutes)) minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Stop tracking after this many minutes of inactivity")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Slider(value: $settings.idleThresholdMinutes, in: 1...30, step: 1)

                            HStack {
                                Text("1min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("30min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }

                    Divider()

                    // Blacklist Settings
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Blacklisted Apps")
                                .font(.headline)

                            Spacer()

                            Button(action: { showingAddAlert = true }) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add App")
                            }
                            .buttonStyle(.bordered)
                        }

                        Text("These apps won't be tracked. When active for 5+ minutes, they'll terminate the current session.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Blacklist Table
                        VStack(spacing: 4) {
                            if settings.blacklistedApps.isEmpty {
                                Text("No apps blacklisted")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(20)
                            } else {
                                ForEach(settings.blacklistedApps, id: \.self) { appName in
                                    HStack {
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)

                                        Text(appName)
                                            .font(.body)

                                        Spacer()

                                        Button(action: {
                                            settings.removeFromBlacklist(appName)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }

                    Divider()

                    // Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How It Works")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(
                                icon: "timer",
                                title: "App Switch Threshold",
                                description: "Quick app switches under this time won't create new entries"
                            )

                            InfoRow(
                                icon: "moon.fill",
                                title: "Idle Detection",
                                description: "Session automatically closes after this period of no keyboard/mouse input"
                            )

                            InfoRow(
                                icon: "hand.raised.fill",
                                title: "Blacklisted Apps",
                                description: "These apps are ignored during tracking and can terminate active sessions"
                            )
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .alert("Add App to Blacklist", isPresented: $showingAddAlert) {
            TextField("App Name (e.g., Safari)", text: $newAppName)
            Button("Cancel", role: .cancel) {
                newAppName = ""
            }
            Button("Add") {
                if !newAppName.isEmpty {
                    settings.addToBlacklist(newAppName)
                    newAppName = ""
                }
            }
        } message: {
            Text("Enter the exact name of the app as it appears in the menu bar")
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
