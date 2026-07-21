//
//  SearchModel.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//
// Value layer for universal search: tokens, result types and search engine

import Foundation
import SwiftData

// MARK: - Tokens

/// Filter chips offered in universal search field
nonisolated enum SearchToken: String, CaseIterable, Identifiable, Hashable {
	case patient
	case ward
	case bed
	case note
	case favourite
	case expiring
	
	var id: Self { self }
	
	var label: String {
		switch self {
		case .patient: "Patient"
		case .ward: "Ward"
		case .bed: "Bed"
		case .note: "Note"
		case .favourite: "Favourite"
		case .expiring: "Expiring Soon"
		}
	}
	
	var systemImage: String {
		switch self {
		case .patient: "person.fill"
		case .ward: "building.fill"
		case .bed: "bed.double.fill"
		case .note: "text.pad.header"
		case .favourite: "star.fill"
		case .expiring: "hourglass"
		}
	}
	
	/// Tokens that scope results to patient domain
	static let patientScoped: Set<SearchToken> = [.patient, .ward, .bed, .expiring]
	
	/// Tokens that scope results to note domain
	static let noteScoped: Set<SearchToken> = [.note, .favourite]
}

// MARK: Results

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

// MARK: -Engine

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
		text: String,
		tokens: [SearchToken]
	) -> [SearchResultSection] {
		let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
		let tokenSet = Set(tokens)
		guard !query.isEmpty || !tokenSet.isEmpty else { return [] }
		
		// A domain is included when no tokens are active, or one of its tokens is
		let includePatients = tokenSet.isEmpty || !tokenSet.isDisjoint(with: SearchToken.patientScoped)
		let includeNotes = tokenSet.isEmpty || !tokenSet.isDisjoint(with: SearchToken.noteScoped)
		
		var sections: [SearchResultSection] = []
		
		if includePatients {
			let hits = matchPatients(patients, query: query, tokens: tokenSet)
			if !hits.isEmpty {
				sections.append(SearchResultSection(id: "patients", title: "Patients", results: hits))
			}
		}
		
		if includeNotes {
			let hits = matchNotes(notes, query: query, tokens: tokenSet)
			if !hits.isEmpty {
				sections.append(SearchResultSection(id: "notes", title: "Ward Notes", results: hits))
			}
		}
		
		return sections
	}
	
	// MARK: Patients
	
	private static func matchPatients(
		_ patients: [Patient],
		query: String,
		tokens: Set<SearchToken>
	) -> [SearchResult] {
		let number = Int(query)
		
		return patients
			.filter { !$0.isExpired }
			.filter { patient in
				if tokens.contains(.expiring),
				   patient.expiresAt.timeIntervalSinceNow > expiringWindow {
					return false
				}
				
				// Ward/bed tokens gate to ward-bed aliases
				if tokens.contains(.ward) || tokens.contains(.bed) {
					guard case .wardBed(let ward, let bed) = patient.alias else { return false }
					if let number {
						if tokens.contains(.ward) && ward != number { return false }
						if tokens.contains(.bed) && bed != number { return false }
						return true
					}
				}
				
				guard !query.isEmpty else { return true }
				return patient.displayName.localizedStandardContains(query)
			}
			.sorted { $0.createdAt > $1.createdAt }
			.map { SearchResult.patient($0) }
	}
	
	// MARK: Notes
	
	private static func matchNotes(
		_ notes: [Note],
		query: String,
		tokens: Set<SearchToken>
	) -> [SearchResult] {
		/// Title hits rank above body-only hits
		struct Ranked {
			let note: Note
			let snippet: AttributedString?
			let rank: Int
		}
		
		let ranked: [Ranked] = notes.compactMap { note in
			if tokens.contains(.favourite) && !note.isFavourite { return nil }
			
			// Token-only browsing: no text means every gated note matches
			guard !query.isEmpty else { return Ranked(note: note, snippet: nil, rank: 1) }
			
			let titleHit = note.title.localizedStandardContains(query)
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
