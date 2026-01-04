//
//  SettingsView.swift
//  AutoTime
//
//  Settings panel for configuring tracking behavior
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    // State for Add alerts
    @State private var newAppName = ""
    @State private var newCompanyName = ""
    @State private var newAllocationName = ""
    
    @State private var showingAddAppAlert = false
    @State private var showingAddCompanyAlert = false
    @State private var showingAddAllocationAlert = false

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
                        TimingSlider(title: "App Switch Threshold",
                                     description: "Minimum time on a new app before creating an entry",
                                     value: $settings.stickyThresholdSeconds,
                                     range: 5...300,
                                     step: 5,
                                     unit: "seconds")
                        
                        TimingSlider(title: "Idle Detection Timeout",
                                     description: "Stop tracking after this many minutes of inactivity",
                                     value: $settings.idleThresholdMinutes,
                                     range: 1...30,
                                     step: 1,
                                     unit: "minutes")
                    }

                    Divider()

                    // Editable Lists Section
                    EditableListView(
                        title: "Blacklisted Apps",
                        description: "These apps won't be tracked. When active for 5+ minutes, they'll terminate the current session.",
                        items: $settings.blacklistedApps,
                        onAdd: { showingAddAppAlert = true },
                        onDelete: settings.removeFromBlacklist
                    )
                    
                    Divider()
                    
                    EditableListView(
                        title: "Companies",
                        description: "Manage the list of companies for time entries.",
                        items: $settings.companyList,
                        onAdd: { showingAddCompanyAlert = true },
                        onDelete: settings.removeCompany
                    )
                    
                    Divider()
                    
                    EditableListView(
                        title: "Allocations",
                        description: "Manage the list of allocations for time entries.",
                        items: $settings.allocationList,
                        onAdd: { showingAddAllocationAlert = true },
                        onDelete: settings.removeAllocation
                    )

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
        // Alert for adding a blacklisted app
        .alert("Add App to Blacklist", isPresented: $showingAddAppAlert) {
            TextField("App Name (e.g., Safari)", text: $newAppName)
            Button("Cancel", role: .cancel) { newAppName = "" }
            Button("Add") {
                settings.addToBlacklist(newAppName)
                newAppName = ""
            }
        } message: {
            Text("Enter the exact name of the app as it appears in the menu bar")
        }
        // Alert for adding a company
        .alert("Add New Company", isPresented: $showingAddCompanyAlert) {
            TextField("Company Name", text: $newCompanyName)
            Button("Cancel", role: .cancel) { newCompanyName = "" }
            Button("Add") {
                settings.addCompany(newCompanyName)
                newCompanyName = ""
            }
        }
        // Alert for adding an allocation
        .alert("Add New Allocation", isPresented: $showingAddAllocationAlert) {
            TextField("Allocation Name", text: $newAllocationName)
            Button("Cancel", role: .cancel) { newAllocationName = "" }
            Button("Add") {
                settings.addAllocation(newAllocationName)
                newAllocationName = ""
            }
        }
    }
}

// MARK: - Reusable Components

struct EditableListView: View {
    let title: String
    let description: String
    @Binding var items: [String]
    let onAdd: () -> Void
    let onDelete: (String) -> Void
    
    @State private var itemToDelete: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New")
                }
                .buttonStyle(.bordered)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                if items.isEmpty {
                    Text("No items in the list.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(20)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items, id: \.self) { item in
                            HStack {
                                Text(item)
                                Spacer()
                                Button(action: { self.itemToDelete = item }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            
                            if item != items.last {
                                Divider()
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
                }
            }
        }
        .alert("Confirm Deletion", isPresented: .constant(itemToDelete != nil)) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    onDelete(item)
                }
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete '\(itemToDelete ?? "")'? This cannot be undone.")
        }
    }
}


struct TimingSlider: View {
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(verbatim: "\(Int(value)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(value: $value, in: range, step: step)

            HStack {
                Text(verbatim: "\(Int(range.lowerBound))\(unit.first!)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(verbatim: "\(Int(range.upperBound))\(unit.first!)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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

