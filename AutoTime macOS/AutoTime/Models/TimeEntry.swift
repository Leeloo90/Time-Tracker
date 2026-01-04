//
//  TimeEntry.swift
//  AutoTime
//
//  Core data model for time tracking entries
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

enum Allocation: String, CaseIterable {
    case production = "Production"
    case editing = "Editing"
    case unassigned = "Unassigned"
}
