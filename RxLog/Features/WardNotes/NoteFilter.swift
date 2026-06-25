//
//  NoteFilter.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/25.
//

import Foundation

// Active filters in Ward Notes list
struct NoteFilter: Equatable {
    var dateRange: DateRangeOption = .all
    var favouritesOnly: Bool = false
    
    var isActive: Bool {
        dateRange != .all || favouritesOnly
    }
    
    func matches(_ note: Note, now: Date = .now, calendar: Calendar = .current) -> Bool {
        if favouritesOnly && !note.isFavourite { return false }
        return dateRange.contains(note.dateModified, now: now, calendar: calendar)
    }
}

// Preset date windows
enum DateRangeOption: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case last30Days
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .all: "All Notes"
        case .today: "Today"
        case .last7Days: "Last 7 Days"
        case .last30Days: "Last 30 Days"
        }
    }
    
    // True if date falls within this window, relative to now
    func contains(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .all: return true
        case .today: return calendar.isDateInToday(date)
        case .last7Days: return isWithin(days: 7, date, now: now, calendar: calendar)
        case .last30Days: return isWithin(days: 30, date, now: now, calendar: calendar)
        }
    }
    
    private func isWithin(days: Int, _ date: Date, now: Date, calendar: Calendar) -> Bool {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) else {
            return true
        }
        return date >= cutoff
    }
}
