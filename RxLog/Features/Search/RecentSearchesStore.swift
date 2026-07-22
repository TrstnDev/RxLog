	//
	//  RecentSearchesStore.swift
	//  RxLog
	//
	//  Created by Tristan Kriel on 2026/07/21.
	//

import Foundation

	/// Lightweight store for universal-search recents.
	///
	/// Persists up to 15 entries to `UserDefaults` as JSON. Entries reference live
	/// models by their model-owned `uuid` — a plain value that round-trips through
	/// JSON with full fidelity, unlike `PersistentIdentifier`, whose decoded form is
	/// documented as not equivalent to store-created identifiers. Anything that no
	/// longer resolves (deleted notes, expired or removed patients) is dropped by
	/// ``prune(keeping:)``.
@Observable
final class RecentSearchesStore {
	
		/// A stored pointer to a previously selected search result.
		///
		/// Only the identifier, kind, and selection date are stored — display content
		/// is always read from the live model, so entries never show stale titles and
		/// dead entries simply fail to resolve.
	struct Entry: Codable, Identifiable, Equatable {
		let id: UUID
		let kind: Kind
		var selectedAt: Date
		
		enum Kind: String, Codable {
			case patient, note
		}
	}
	
	private static let storageKey = "rxlog.recentSearches"
	static let maxEntries = 15
	
	private(set) var entries: [Entry] = []
	
		/// Loads persisted entries; falls back to an empty list if decoding fails
		/// (e.g. after a format change), which self-heals as new selections arrive.
	init() {
		if let data = UserDefaults.standard.data(forKey: Self.storageKey),
		   let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
			entries = decoded
		}
	}
	
		// MARK: - Recording
	
	func record(_ patient: Patient) {
		record(id: patient.uuid, kind: .patient)
	}
	
	func record(_ note: Note) {
		record(id: note.uuid, kind: .note)
	}
	
		/// Inserts at the front, deduplicating by identifier (move-to-front),
		/// then trims to ``maxEntries``.
	private func record(id: UUID, kind: Entry.Kind) {
		entries.removeAll { $0.id == id }
		entries.insert(Entry(id: id, kind: kind, selectedAt: .now), at: 0)
		if entries.count > Self.maxEntries {
			entries.removeLast(entries.count - Self.maxEntries)
		}
		save()
	}
	
		// MARK: - Garbage collection
	
		/// Drops entries whose identifiers are absent from `validIDs`.
		///
		/// Callers pass the identifiers of every model that should remain reachable
		/// (non-expired patients + existing notes). Comparison happens entirely
		/// in memory — nothing here touches SwiftData.
	func prune(keeping validIDs: Set<UUID>) {
		let pruned = entries.filter { validIDs.contains($0.id) }
		guard pruned.count != entries.count else { return }
		entries = pruned
		save()
	}
	
		// MARK: - Removal
	
	func remove(_ entry: Entry) {
		entries.removeAll { $0.id == entry.id }
		save()
	}
	
	func clearAll() {
		entries.removeAll()
		save()
	}
	
		// MARK: - Persistence
	
	private func save() {
		if let data = try? JSONEncoder().encode(entries) {
			UserDefaults.standard.set(data, forKey: Self.storageKey)
		}
	}
}
