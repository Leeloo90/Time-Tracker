//
//  TimeEntry.swift
//  AutoTime
//
//  Core data model for time tracking entries with timeline helpers
//

import Foundation

struct TimeEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var day: String
    var company: String
    var allocation: String
    var application: String
    var project: String
    var timeStart: Date
    var timeFinish: Date
    var overview: String

    // MARK: - Calculated Properties

    var durationInHours: Double {
        timeFinish.timeIntervalSince(timeStart) / 3600.0
    }

    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: timeStart)
    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timeStart)
    }

    var formattedFinishTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timeFinish)
    }

    // MARK: - Timeline Positioning Helpers

    /// Calculates the start position of the entry as a percentage (0.0 to 1.0) of a 24-hour day.
    /// Useful for placing the block on a visual timeline bar.
    var startPercentageOfDay: CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: timeStart)
        let secondsFromStart = timeStart.timeIntervalSince(startOfDay)
        return CGFloat(secondsFromStart / 86400.0) // 86400 seconds in a day
    }

    /// Calculates the width of the entry as a percentage (0.0 to 1.0) of a 24-hour day.
    var widthPercentageOfDay: CGFloat {
        let duration = timeFinish.timeIntervalSince(timeStart)
        return CGFloat(duration / 86400.0)
    }

    // MARK: - Initialization

    init(id: UUID = UUID(),
         day: String = "",
         company: String = "",
         allocation: String = "",
         application: String,
         project: String,
         timeStart: Date,
         timeFinish: Date,
         overview: String = "") {
        self.id = id
        self.day = day
        self.company = company
        self.allocation = allocation
        self.application = application
        self.project = project
        self.timeStart = timeStart
                 self.timeFinish = timeFinish
                self.overview = overview
            }
        }
        
