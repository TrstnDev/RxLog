//
//  NoteListModel.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/26.
//
// Logical core behind Ward Notes list (configuration, ordering, and dated sections)

import Foundation

// MARK: DISPLAY STYLE

/// <summary>Which of the 3 layouts the list is currently rendered in</summary>
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

// MARK: SORT OPTION

/// <summary>How the list is ordered and/or sectioned by date</summary>
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
    
	/// <summary>The date this option sorts and sections by, or 'nil' for Title</summary>
	var dateKeyPath: KeyPath<Note, Date>? {
		switch self {
		case .dateModified: \.dateModified
		case .dateCreated: \.dateCreated
		case .lastViewed: \.lastViewed
		case .title: nil
		}
	}
}

// MARK: FILTERING

/// <summary>The active filter state in the Ward Notes list</summary>
struct NoteFilter: Equatable {
	var dateRange: DateRangeOption = .all
	var favouritesOnly: Bool = false
    
	/// <summary>Whether any non-default filter is applied</summary>
	var isActive: Bool {
		dateRange != .all || favouritesOnly
	}
    
	/// <remarks>True if a note passes every active filter</remarks>
	func matches(_ note: Note, now: Date = .now, calendar: Calendar = .current) -> Bool {
		if favouritesOnly && !note.isFavourite { return false }
		return dateRange.contains(note.dateModified, now: now, calendar: calendar)
	}
}

/// <summary>Preset date windows offered in the filter sheet</summary>
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
    
	/// <summary>Whether 'date' falls inside this window relative to 'now'</summary>
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

// MARK: SECTIONING

/// <summary>One dated group of notes; "title == nil" renders without a header</summary>
struct NoteSection: Identifiable {
	let id: String
	let title: String?
	let notes: [Note]
}

/// <summary>Buckets notes into ordered dated sections</summary>
enum NoteSectioner {
	static func sections(
		from notes: [Note],
		by dateKeyPath: KeyPath<Note, Date> = \.dateModified
	) -> [NoteSection] {
		let calendar = Calendar.current
		let now = Date.now
        
		// Newest first by chosen date
		let sorted = notes.sorted { $0[keyPath: dateKeyPath] > $1[keyPath: dateKeyPath] }
        
		// Group by bucket title
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
    
	/// <summary>Maps a single date to its section title</summary>
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

// MARK: PIPELINE

/// <summary>Single ordered transform from filter -> sort -> section</summary>
enum NoteListPipeline {
	static func sections(
		from notes: [Note],
		searchText: String,
		filter: NoteFilter,
		sortOption: NoteSortOption
	) -> [NoteSection] {
		// 1. FILTER
		let filtered = notes.filter { note in
			guard filter.matches(note) else { return false }
			guard !searchText.isEmpty else { return true }
			return note.title.localizedStandardContains(searchText)
				|| note.plainText.localizedStandardContains(searchText)
		}
        
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
