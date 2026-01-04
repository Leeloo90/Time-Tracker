//
//  WindowTitleParser.swift
//  AutoTime
//
//  Parses project names from window titles
//

import Foundation

struct WindowTitleParser {
    static func parseProject(app: String, title: String) -> String {
        switch app {
        case "DaVinci Resolve":
            // Pattern: "DaVinci Resolve - [Project Name]"
            return title.replacingOccurrences(of: "DaVinci Resolve - ", with: "").trimmingCharacters(in: .whitespaces)

        case "Google Chrome", "Safari", "Firefox":
            // Use tab title as project name
            return title.trimmingCharacters(in: .whitespaces)

        case "Final Cut Pro":
            // Pattern: "[Project Name] - Final Cut Pro"
            let components = title.components(separatedBy: " - ")
            return components.first?.trimmingCharacters(in: .whitespaces) ?? title

        case "Adobe Premiere Pro", "Premiere Pro":
            // Pattern: "[Project Name] - Adobe Premiere Pro"
            let components = title.components(separatedBy: " - ")
            return components.first?.trimmingCharacters(in: .whitespaces) ?? title

        case "Xcode":
            // Pattern: "[File/Project] — Edited — Xcode"
            let components = title.components(separatedBy: " — ")
            return components.first?.trimmingCharacters(in: .whitespaces) ?? title

        default:
            // Default: use full window title
            return title.trimmingCharacters(in: .whitespaces)
        }
    }
}
