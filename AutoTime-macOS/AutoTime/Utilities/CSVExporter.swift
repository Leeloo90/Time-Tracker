//
//  CSVExporter.swift
//  AutoTime
//
//  Exports time entries to CSV format
//

import Foundation
import AppKit

struct CSVExporter {
    static func exportToCSV(entries: [TimeEntry]) {
        let headers = "Day,Company,Allocation,Application,Project,Time Start,Time Finish,Hours,Overview\n"

        let rows = entries.map { entry in
            let day = entry.formattedDay
            let company = escapeCSV(entry.company)
            let allocation = escapeCSV(entry.allocation)
            let application = escapeCSV(entry.application)
            let project = escapeCSV(entry.project)
            let start = entry.formattedStartTime
            let finish = entry.formattedFinishTime
            let hours = String(format: "%.2f", entry.durationInHours)
            let overview = escapeCSV(entry.overview)

            return "\(day),\(company),\(allocation),\(application),\(project),\(start),\(finish),\(hours),\(overview)"
        }.joined(separator: "\n")

        let csvContent = headers + rows

        // Save file dialog
        let savePanel = NSSavePanel()
        savePanel.title = "Export Timesheet"
        savePanel.nameFieldStringValue = "AutoTime_Export_\(dateStamp()).csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try csvContent.write(to: url, atomically: true, encoding: .utf8)
                    print("✅ CSV exported to: \(url.path)")
                } catch {
                    print("❌ Failed to export CSV: \(error)")
                }
            }
        }
    }

    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private static func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
