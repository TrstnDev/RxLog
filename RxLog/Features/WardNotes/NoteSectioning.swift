//
//  NoteSectioning.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import Foundation

// One dated group of notes
struct NoteSection: Identifiable {
    let id: String
    let title: String?
    let notes: [Note]
}

// Buckets notes into ordered, dated sections
enum NoteSectioner {
    
    /// - Parameters:
    ///     - notes: the notes to group
    ///     - dateKeyPath: which date to bucket by
    static func sections(
        from notes: [Note],
        by dateKeyPath: KeyPath<Note, Date> = \.dateModified
    ) -> [NoteSection] {
        let calendar = Calendar.current
        let now = Date.now
        
        // Sort newest-first by chosen date
        let sorted = notes.sorted { $0[keyPath: dateKeyPath] > $1[keyPath: dateKeyPath] }
        
        // Group by section title
        var order: [String] = []
        var buckets: [String: [Note]] = [:]
        
        for note in sorted {
            let title = sectionTitle(for: note[keyPath: dateKeyPath], now: now, calendar: calendar)
            if buckets[title] == nil {
                buckets[title] = []
                order.append(title)
            }
            buckets[title]?.append(note)
        }
        
        return order.map { NoteSection(id: $0, title: $0, notes: buckets[$0] ?? []) }
    }
    
    /// Maps a single date to its section title
    private static func sectionTitle(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        
        // Whole-day difference, so notes from 1am and 11pm the same day group together
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        let daysAgo = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        
        switch daysAgo {
        case ..<7: return "Last 7 Days"     // 2-6 days ago
        case ..<30: return "Last 30 Days"   // 7-29 days ago
        default: return monthTitle(for: date, in: calendar, now: now)
        }
    }
    
    private static func monthTitle(for date: Date, in calendar: Calendar, now: Date) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        
        return sameYear
            ? date.formatted(.dateTime.month(.wide))
            : date.formatted(.dateTime.month(.wide).year())
    }
}
