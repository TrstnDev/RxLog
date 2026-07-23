//
//  UniversalSearch.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//
// Value layer for universal search: tokens, result types and search engine

import Foundation
import SwiftData

// MARK: - Results

/// Single search hit
///
/// Adding a new searchable feature = add a case here + a matcher in ``UniversalSearch`` + a row in `SearchComponents`
enum SearchResult: Identifiable {
	case patient(Patient)
	case note(Note, snippet: AttributedString?)
	
	var id: PersistentIdentifier {
		switch self {
		case .patient(let patient): patient.persistentModelID
		case .note(let note, _): note.persistentModelID
		}
	}
}

/// A titled group of hits from one domain
struct SearchResultSection: Identifiable {
	let id: String
	let title: String
	let results: [SearchResult]
}

// MARK: - Engine

/// Single transform from raw models + query state to display-ready sections
enum UniversalSearch {
	
	/// Matches inside this window before expiry count as "expiring soon"
	private static let expiringWindow: TimeInterval = 48 * 3_600
	
	/// Characters of lead-in context shown before a body match
	private static let snippetLeadIn = 28
	
	/// Applies token scoping and text matching, returning one section per domain
	/// - Returns: Empty when there is nothing to search for (idle state)
	static func sections(
		patients: [Patient],
		notes: [Note],
		text: String
	) -> [SearchResultSection] {
		let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !query.isEmpty else { return [] }
		
		var sections: [SearchResultSection] = []
		
		let patientHits = matchPatients(patients, query: query)
		if !patientHits.isEmpty {
			sections.append(SearchResultSection(id: "patients", title: "Patients", results: patientHits))
		}
		
		let noteHits = matchNotes(notes, query: query)
		if !noteHits.isEmpty {
			sections.append(SearchResultSection(id: "notes", title: "Ward Notes", results: noteHits))
		}
		
		return sections
	}
	
	// MARK: Patients
	
	private static func matchPatients(
		_ patients: [Patient],
		query: String,
	) -> [SearchResult] {
		patients
			.filter { !$0.isExpired }
			.filter { patient in
				patient.displayName.localizedStandardContains(query)
			}
			.sorted { $0.createdAt > $1.createdAt }
			.map { SearchResult.patient($0) }
	}
	
	// MARK: Notes
	
	private static func matchNotes(
		_ notes: [Note],
		query: String,
	) -> [SearchResult] {
		/// Title hits rank above body-only hits
		struct Ranked {
			let note: Note
			let snippet: AttributedString?
			let rank: Int
		}
		
		let ranked: [Ranked] = notes.compactMap { note in
			let titleHit = note.displayTitle.localizedStandardContains(query)
			let bodySnippet = snippet(in: note.plainText, matching: query)
			guard titleHit || bodySnippet != nil else { return nil }
			
			return Ranked(note: note, snippet: bodySnippet, rank: titleHit ? 0 : 1)
		}
		
		return ranked
			.sorted {
				if $0.rank != $1.rank { return $0.rank < $1.rank }
				return $0.note.dateModified > $1.note.dateModified
			}
			.map { SearchResult.note($0.note, snippet: $0.snippet) }
	}
	
	// MARK: Snippet
	
	/// Builds a one-line window around first body-match, marking the match with `.stronglyEmphasized`
	static func snippet(in body: String, matching query: String) -> AttributedString? {
		guard !query.isEmpty,
			  let match = body.localizedStandardRange(of: query) else { return nil }
		
		// Constrain the window to the line containing the match
		let line = body.lineRange(for: match)
		
		// Walk back up to `snippetLeadIn` characters of context
		let leadRoom = body.distance(from: line.lowerBound, to: match.lowerBound)
		let leadIn = min(leadRoom, snippetLeadIn)
		var start = body.index(match.lowerBound, offsetBy: -leadIn)
		let clippedFront = start > line.lowerBound
		
		// Avoid opening mid-word, skip forward to next word boundary
		if clippedFront,
		   let space = body[start..<match.lowerBound].firstIndex(where: \.isWhitespace) {
			start = body.index(after: space)
		}
		
		let window = body[start..<line.upperBound]
			.trimmingCharacters(in: .whitespacesAndNewlines)
		
		var snippet = AttributedString((clippedFront ? "..." : "") + window)
		
		// Re-find match inside the snippet to mark it
		if let highlight = snippet.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
			snippet[highlight].inlinePresentationIntent = .stronglyEmphasized
		}
		
		return snippet
	}
}
