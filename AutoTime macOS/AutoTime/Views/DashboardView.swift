//
//  DashboardView.swift
//  AutoTime
//
//  Main dashboard with editable time entry table
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var tracker: ActivityTracker

    @State private var editingEntry: TimeEntry?
    @State private var editedCompany = ""
    @State private var editedAllocation = ""
    @State private var editedProject = ""
    @State private var editedOverview = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AutoTime Dashboard")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                if tracker.isTracking {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Tracking Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Button("Export CSV") {
                    CSVExporter.exportToCSV(entries: tracker.entries)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Current Activity Display
            if let current = tracker.currentActivity {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Currently Tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(current.app)
                                .fontWeight(.semibold)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(current.project)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if let pending = tracker.pendingSwitch {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Pending switch to \(pending.app)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
            }

            // Table
            ScrollView {
                if tracker.entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No time entries yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Start tracking to see your activity here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(60)
                } else {
                    VStack(spacing: 0) {
                        // Table Header
                        HStack(spacing: 8) {
                            Text("Day").frame(width: 90, alignment: .leading)
                            Text("Company").frame(width: 120, alignment: .leading)
                            Text("Allocation").frame(width: 100, alignment: .leading)
                            Text("Application").frame(width: 140, alignment: .leading)
                            Text("Project").frame(width: 180, alignment: .leading)
                            Text("Start").frame(width: 80, alignment: .leading)
                            Text("Finish").frame(width: 80, alignment: .leading)
                            Text("Hours").frame(width: 60, alignment: .leading)
                            Text("Overview").frame(minWidth: 150, alignment: .leading)
                            Spacer().frame(width: 40)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))

                        Divider()

                        // Table Rows
                        ForEach(tracker.entries) { entry in
                            TimeEntryRow(
                                entry: entry,
                                onUpdate: { updatedEntry in
                                    tracker.updateEntry(updatedEntry)
                                },
                                onDelete: {
                                    tracker.deleteEntry(entry)
                                }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 600)
    }
}

struct TimeEntryRow: View {
    let entry: TimeEntry
    let onUpdate: (TimeEntry) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedEntry: TimeEntry

    init(entry: TimeEntry, onUpdate: @escaping (TimeEntry) -> Void, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedEntry = State(initialValue: entry)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.formattedDay)
                .frame(width: 90, alignment: .leading)
                .font(.caption)

            EditableTextField(text: $editedEntry.company, width: 120)
            EditableTextField(text: $editedEntry.allocation, width: 100)

            Text(entry.application)
                .frame(width: 140, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            EditableTextField(text: $editedEntry.project, width: 180)

            Text(entry.formattedStartTime)
                .frame(width: 80, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(entry.formattedFinishTime)
                .frame(width: 80, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.2f", entry.durationInHours))
                .frame(width: 60, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            EditableTextField(text: $editedEntry.overview, width: nil)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.01))
        .onChange(of: editedEntry) { oldValue, newValue in
            if newValue.company != entry.company ||
               newValue.allocation != entry.allocation ||
               newValue.project != entry.project ||
               newValue.overview != entry.overview {
                onUpdate(newValue)
            }
        }
    }
}

struct EditableTextField: View {
    @Binding var text: String
    let width: CGFloat?

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(4)
            .frame(width: width, alignment: .leading)
            .font(.caption)
    }
}
