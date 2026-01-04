//
//  DashboardView.swift
//  AutoTime
//
//  Main dashboard with Timeline Visualizer, Sidebar filtering, and Editable Table.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var tracker: ActivityTracker

    // Filter States
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var filterCompany = ""
    @State private var filterAllocation = ""
    
    // Timeline Range Selection (Seconds from start of day: 0 to 86400)
    @State private var rangeStart: Double = 0
    @State private var rangeEnd: Double = 86400
    @State private var isShowingSidebar = true

    @ObservedObject var settings = AppSettings.shared

    // Computed property to filter entries based on Sidebar + Timeline Range
    var filteredEntries: [TimeEntry] {
        tracker.entries.filter { entry in
            let calendar = Calendar.current
            
            // 1. Date Range Check
            guard let startOfDayForRange = calendar.startOfDay(for: startDate) as Date?,
                  let endOfDayForRange = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) as Date? else {
                return false
            }
            let isInDateRange = entry.timeStart >= startOfDayForRange && entry.timeStart < endOfDayForRange
            
            // 2. Sidebar Filters
            let matchesCompany = filterCompany.isEmpty || entry.company == filterCompany
            let matchesAllocation = filterAllocation.isEmpty || entry.allocation == filterAllocation
            
            // 3. Timeline Range Check (Only applies if start and end date are the same)
            var inTimeRange = true
            if calendar.isDate(startDate, inSameDayAs: endDate) {
                let startOfDay = calendar.startOfDay(for: startDate)
                let entryStartSec = entry.timeStart.timeIntervalSince(startOfDay)
                let entryFinishSec = entry.timeFinish.timeIntervalSince(startOfDay)
                
                inTimeRange = (entryStartSec >= rangeStart && entryStartSec <= rangeEnd) ||
                              (entryFinishSec >= rangeStart && entryFinishSec <= rangeEnd)
            }
            
            return isInDateRange && matchesCompany && matchesAllocation && inTimeRange
        }
    }
    
    private var headerDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        NavigationView {
            // MARK: - SIDEBAR
            List {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Filters")) {
                    Picker("Company", selection: $filterCompany) {
                        Text("All Companies").tag("")
                        ForEach(settings.companyList, id: \.self) { company in
                            Text(company).tag(company)
                        }
                    }
                    
                    Picker("Allocation", selection: $filterAllocation) {
                        Text("All Allocations").tag("")
                        ForEach(settings.allocationList, id: \.self) { alloc in
                            Text(alloc).tag(alloc)
                        }
                    }
                    
                    Button("Reset Filters") {
                        filterCompany = ""
                        filterAllocation = ""
                        rangeStart = 0
                        rangeEnd = 86400
                        startDate = Date()
                        endDate = Date()
                    }
                    .buttonStyle(.link)
                }
                
                Section(header: Text("Stats")) {
                    VStack(alignment: .leading) {
                        Text("Selected Range Total:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f Hours", filteredEntries.reduce(0) { $0 + $1.durationInHours }))
                            .font(.headline)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 250)

            // MARK: - MAIN CONTENT
            VStack(spacing: 0) {
                // Toolbar Header
                HStack {
                    Button(action: { isShowingSidebar.toggle() }) {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(.plain)
                    
                    if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                        Text(startDate, style: .date)
                            .font(.headline)
                    } else {
                        Text("\(headerDateFormatter.string(from: startDate)) - \(headerDateFormatter.string(from: endDate))")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if tracker.isTracking {
                        Label("Tracking Active", systemImage: "record.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Button("Export CSV") {
                        CSVExporter.exportToCSV(entries: filteredEntries)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                // MARK: - TIMELINE VISUALIZER
                if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Timeline (00:00 - 24:00)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .leading) {
                            // Background Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 40)

                            // Activity Blocks
                            ForEach(tracker.entries.filter { Calendar.current.isDate($0.timeStart, inSameDayAs: startDate) }) { entry in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForApp(entry.application))
                                    .frame(width: max(2, entry.widthPercentageOfDay * 800), height: 30) // Scaled width
                                    .offset(x: entry.startPercentageOfDay * 800)
                                    .help("\(entry.application): \(entry.formattedStartTime) - \(entry.formattedFinishTime)")
                            }
                            
                            // Range Selector Overlay (In/Out Points)
                            RangeHandleOverlay(rangeStart: $rangeStart, rangeEnd: $rangeEnd, totalWidth: 800)
                        }
                        .frame(width: 800, height: 60)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.black.opacity(0.03))

                    Divider()
                }

                // MARK: - TABLE VIEW
                ScrollView {
                    if filteredEntries.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No entries match the selected filters or range.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        VStack(spacing: 0) {
                            // Table Header
                            HStack(spacing: 8) {
                                Text("Time").frame(width: 140, alignment: .leading)
                                Text("Company").frame(width: 120, alignment: .leading)
                                Text("Allocation").frame(width: 100, alignment: .leading)
                                Text("Project").frame(width: 180, alignment: .leading)
                                Text("Application").frame(width: 120, alignment: .leading)
                                Text("Hours").frame(width: 60, alignment: .leading)
                                Text("Overview").frame(minWidth: 200, alignment: .leading)
                                Spacer().frame(width: 40)
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.gray.opacity(0.1))

                            ForEach(filteredEntries) { entry in
                                TimeEntryRow(entry: entry, onUpdate: tracker.updateEntry, onDelete: { tracker.deleteEntry(entry) })
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper to assign consistent colors to apps on the timeline
    private func colorForApp(_ app: String) -> Color {
        switch app {
        case "DaVinci Resolve": return .purple
        case "Google Chrome", "Safari": return .blue
        case "Xcode": return .orange
        case "Adobe Premiere Pro": return .cyan
        default: return .gray
        }
    }
}

// MARK: - TIMELINE OVERLAY COMPONENTS
struct RangeHandleOverlay: View {
    @Binding var rangeStart: Double
    @Binding var rangeEnd: Double
    let totalWidth: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Visual Shadow for unselected areas
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(width: CGFloat(rangeStart / 86400) * totalWidth)
            
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(width: totalWidth - (CGFloat(rangeEnd / 86400) * totalWidth))
                .offset(x: CGFloat(rangeEnd / 86400) * totalWidth)

            // Draggable Handles
            TimelineHandle(position: $rangeStart, totalWidth: totalWidth, color: .blue)
            TimelineHandle(position: $rangeEnd, totalWidth: totalWidth, color: .red)
        }
    }
}

struct TimelineHandle: View {
    @Binding var position: Double
    let totalWidth: CGFloat
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(color).frame(width: 2, height: 50)
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 8))
                .foregroundColor(color)
        }
        .offset(x: CGFloat(position / 86400) * totalWidth - 1)
        .gesture(
            DragGesture().onChanged { value in
                let newPos = Double(value.location.x / totalWidth) * 86400
                position = min(max(0, newPos), 86400)
            }
        )
    }
}

// MARK: - ROW VIEW
struct TimeEntryRow: View {
    @ObservedObject var settings = AppSettings.shared
    let entry: TimeEntry
    let onUpdate: (TimeEntry) -> Void
    let onDelete: () -> Void

    @State private var editedEntry: TimeEntry
    @State private var isDirty = false
    @State private var showDeleteConfirm = false

    init(entry: TimeEntry, onUpdate: @escaping (TimeEntry) -> Void, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedEntry = State(initialValue: entry)
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading) {
                Text("\(entry.formattedStartTime) - \(entry.formattedFinishTime)")
                    .font(.caption.monospacedDigit())
                Text(entry.formattedDay).font(.system(size: 9)).foregroundColor(.secondary)
            }
            .frame(width: 140, alignment: .leading)

            // Use a Picker for the Company
            Picker("", selection: $editedEntry.company) {
                ForEach(settings.companyList, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .font(.caption)

            // Use a Picker for the allocation
            Picker("", selection: $editedEntry.allocation) {
                ForEach(settings.allocationList, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
            .font(.caption)

            TextField("", text: $editedEntry.project)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(4)
                .frame(width: 180, alignment: .leading)
                .font(.caption)

            Text(entry.application)
                .frame(width: 120, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "%.2f", entry.durationInHours))
                .frame(width: 60, alignment: .leading)
                .font(.caption.bold())

            TextField("", text: $editedEntry.overview)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(4)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .font(.caption)

            VStack(spacing: 4) {
                if isDirty {
                    Button(action: { onUpdate(editedEntry) }) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }.buttonStyle(.plain)
                    
                    Button(action: { editedEntry = entry }) {
                        Image(systemName: "x.circle.fill").foregroundColor(.orange)
                    }.buttonStyle(.plain)
                } else {
                    Button(action: { showDeleteConfirm = true }) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }.buttonStyle(.plain)
                }
            }
            .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onChange(of: editedEntry) {
            isDirty = (editedEntry != entry)
        }
        .onChange(of: entry) {
            // This is called when the parent view saves, so we reset our state
            editedEntry = entry
            isDirty = false
        }
        .alert("Confirm Delete", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this time entry? This cannot be undone.")
        }
    }
}

// Reusable component no longer needed with direct TextField usage
// struct EditableTextField ...

