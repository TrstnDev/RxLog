//
//  RecentSearchesStore.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//

import Foundation
import SwiftData

/// Lightweight store for universal-search recents
///
/// Persists up to 15 entries to UserDefaults as JSON
/// Call ``gc(validPatientIDs:validNoteIDs:)`` before displaying to purge stale references
@Observable
final class RecentSearchesStore {
	
	/// One stored search result
	struct Entry: Codable, Identifiable {
		let id: Int			// PersistentIdentifier.value
		let type: EntryType		// .patient or .note
		let displayName: String
		let selectedAt: Date
		
		enum EntryType: String, Codable {
			case patient, note
		}
	}
	
	private static let storageKey = "rxlog.recentSearches"
	static let maxEntries = 15
	
	var recentSearches: [Entry] = []
	
	/// Load from disk; fall back to empty array on decode failure
	init() {
		if let data = UserDefaults.standard.data(forKey: Self.storageKey),
		   let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
			recentSearches = decoded
		}
	}
	
	private func save() {
		if let data = try? JSONEncoder().encode(recentSearches) {
			UserDefaults.standard.set(data, forKey: Self.storageKey)
		}
	}
	
	/// Add a patient to the front of the recents list
	/// Duplicates (same ID) are moved to the front rather than duplicated
	func addPatient(_ patient: Patient) {
		let entry = Entry(
			id: patient.persistentModelID.hashValue,
			type: .patient,
			displayName: patient.displayName,
			selectedAt: .now
		)
		insert(entry: entry)
	}
	
	/// Add a note to the front of the recents list
	func addNote(_ note: Note) {
		let entry = Entry(
			id: note.persistentModelID.hashValue,
			type: .note,
			displayName: note.title,
			selectedAt: .now
		)
		insert(entry: entry)
	}
	
	private func insert(entry: Entry) {
		// Remove existing entry with the same ID (move-to-front)
		recentSearches.removeAll { $0.id == entry.id }
		recentSearches.insert(entry, at: 0)
		recentSearches = Array(recentSearches.prefix(Self.maxEntries))
		save()
	}
	
	/// Remove expired/deleted entries that no longer exist in the store
	///
	/// - `validPatientIDs`: IDs of patients currently in SwiftData
	/// - `validNoteIDs`: IDs of notes currently in SwiftData
	func gc(
		validPatientIDs: Set<Int>,
		validNoteIDs: Set<Int>
	) {
		let before = recentSearches.count
		recentSearches = recentSearches.filter { entry in
			switch entry.type {
			case .patient: validPatientIDs.contains(entry.id)
			case .note: validNoteIDs.contains(entry.id)
			}
		}
		if recentSearches.count != before {
			save()
		}
	}
	
	/// Wipe the entire recents list
	func clearAll() {
		recentSearches.removeAll()
		save()
	}
}
