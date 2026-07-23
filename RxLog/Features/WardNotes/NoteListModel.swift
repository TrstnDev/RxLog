//
//  NoteListModel.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/26.
//
//	Value-layer for the Ward Notes list: display/sort options, filtering, and
//	date-based sectioning. No SwiftUI or persistence dependencies.

import Foundation

// MARK: - Display Style

/// The layout the list is rendered in
enum NoteDisplayStyle: String, CaseIterable, Identifiable {
	case waterfall
	case grid
	case list
    
	var id: Self {
		self
	}
    
	var label: String {
		switch self {
		case .waterfall: "Waterfall"
		case .grid: "Grid"
		case .list: "List"
		}
	}
    
	var systemImage: String {
		switch self {
		case .waterfall: "rectangle.3.offgrid"
		case .grid: "square.grid.2x2"
		case .list: "list.bullet"
		}
	}
}

// MARK: - Sort Option

/// How the list is ordered and sectioned
enum NoteSortOption: String, CaseIterable, Identifiable {
	case dateModified
	case dateCreated
	case lastViewed
	case title
    
	var id: Self {
		self
	}
    
	var label: String {
		switch self {
		case .dateModified: "Date Modified"
		case .dateCreated: "Date Created"
		case .lastViewed: "Last Viewed"
		case .title: "Title"
		}
	}
    
	/// Date the option sorts and sections by; `nil` for `.title`
	var dateKeyPath: KeyPath<Note, Date>? {
		switch self {
		case .dateModified: \.dateModified
		case .dateCreated: \.dateCreated
		case .lastViewed: \.lastViewed
		case .title: nil
		}
	}
}

// MARK: - Filtering

/// Active filter state for the list
struct NoteFilter: Hashable {
	var dateRange: DateRangeOption = .all
	var favouritesOnly: Bool = false
    
	/// Whether any non-default filter is applied
	var isActive: Bool {
		dateRange != .all || favouritesOnly
	}
    
	/// Whether `note` passes every active filter
	func matches(_ note: Note, now: Date = .now, calendar: Calendar = .current) -> Bool {
		if favouritesOnly && !note.isFavourite { return false }
		return dateRange.contains(note.dateModified, now: now, calendar: calendar)
	}
}

/// Preset date windows offered in the filter sheet
enum DateRangeOption: String, CaseIterable, Identifiable {
	case all
	case today
	case last7Days
	case last30Days
    
	var id: Self {
		self
	}
    
	var label: String {
		switch self {
		case .all: "All Notes"
		case .today: "Today"
		case .last7Days: "Last 7 Days"
		case .last30Days: "Last 30 Days"
		}
	}
    
	/// Whether `date` falls within this window relative to `now`
	func contains(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
		switch self {
		case .all: return true
		case .today: return calendar.isDateInToday(date)
		case .last7Days: return isWithin(days: 7, date, now: now, calendar: calendar)
		case .last30Days: return isWithin(days: 30, date, now: now, calendar: calendar)
		}
	}
    
	private func isWithin(days: Int, _ date: Date, now: Date, calendar: Calendar) -> Bool {
		guard let cutoff = calendar.date(
			byAdding: .day,
			value: -days,
			to: calendar.startOfDay(for: now)
		) else {
			return true
		}
		return date >= cutoff
	}
}

// MARK: - Sectioning

/// A dated group of notes; A `nil` title renders without a header
struct NoteSection: Identifiable {
	let id: String
	let title: String?
	let notes: [Note]
}

/// Buckets notes into ordered, dated sections
enum NoteSectioner {
	/// Groups `notes` by date bucket (Today, Yesterday, Last 7/30 Days, then by month)
	/// - Returns: Sections newest-first, each titled by its bucket
	static func sections(
		from notes: [Note],
		by dateKeyPath: KeyPath<Note, Date> = \.dateModified
	) -> [NoteSection] {
		let calendar = Calendar.current
		let now = Date.now
        
		let sorted = notes.sorted { $0[keyPath: dateKeyPath] > $1[keyPath: dateKeyPath] }
        
		// Preserve first-seen bucket order while grouping
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
    
	private static func sectionTitle(for date: Date, now: Date, calendar: Calendar) -> String {
		if calendar.isDateInToday(date) { return "Today" }
		if calendar.isDateInYesterday(date) { return "Yesterday" }
        
		let startOfToday = calendar.startOfDay(for: now)
		let startOfDate = calendar.startOfDay(for: date)
		let daysAgo = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
        
		switch daysAgo {
		case ..<7: return "Last 7 Days"
		case ..<30: return "Last 30 Days"
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

// MARK: - Pipeline

/// Single transform from raw notes to display-ready sections
enum NoteListPipeline {
	/// Applies search and filtering, then sorts and sections
	/// - Returns: Date-buckets sections for date sorts, or one untitled section for `.title`
	static func sections(
		from notes: [Note],
		filter: NoteFilter,
		sortOption: NoteSortOption
	) -> [NoteSection] {
		// 1. FILTER
		let filtered = notes.filter { filter.matches($0) }
        
		// 2 & 3. SORT + SECTION
		if let dateKeyPath = sortOption.dateKeyPath {
			return NoteSectioner.sections(from: filtered, by: dateKeyPath)
		} else {
			let sorted = filtered.sorted {
				$0.title.localizedStandardCompare($1.title) == .orderedAscending
			}
			return [NoteSection(id: "all", title: nil, notes: sorted)]
		}
	}
}
