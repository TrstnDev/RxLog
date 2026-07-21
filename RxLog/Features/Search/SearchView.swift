//
//  SearchView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//

import SwiftData
import SwiftUI

/// Universal search tab: renders sectioned results for the query state
/// owned by ``MainTabView``'s search field
struct SearchView: View {
	@Query(sort: \Patient.createdAt, order: .reverse) private var patients: [Patient]
	@Query private var notes: [Note]
	
	// Patient results respect same regulatory gate as Patients tab
	@AppStorage(PatientConsent.acceptedVersionKey) private var acceptedVersion = 0
	
	// Search field state
	@State private var searchText = ""
	
	// Result routing
	@State private var viewingPatient: Patient?
	@State private var editingNote: Note?
	
	// Recents
	@State private var recents = RecentSearchesStore()
	
	private var trimmedText: String {
		searchText.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	/// Idle until the user types or picks a token
	private var isIdle: Bool {
		trimmedText.isEmpty
	}
	
	/// Patients are searchable only after the declaration is accepted
	private var searchablePatients: [Patient] {
		acceptedVersion >= PatientConsent.currentVersion ? patients : []
	}
	
	var body: some View {
		// Build sections once per render
		let sections = UniversalSearch.sections(
			patients: searchablePatients,
			notes: notes,
			text: trimmedText
		)
		
		NavigationStack {
			content(sections: sections)
				.navigationTitle("Search")
				.searchable(text: $searchText, prompt: "Search RxLog")
				.navigationDestination(item: $viewingPatient) { patient in
					PatientDetailView(patient: patient)
				}
				.navigationDestination(item: $editingNote) { note in
					NoteEditorView(note: note)
				}
		}
	}
	
	// MARK: - Recents
	
	/// Sweep stale entries: expired patients and deleted notes
	private func garbageCollectRecents() {
		let validPatients = Set(patients.map { $0.persistentModelID.hashValue })
		let validNotes = Set(notes.map { $0.persistentModelID.hashValue })
		recents.gc(validPatientIDs: validPatients, validNoteIDs: validNotes)
	}
	
	private func recentsList() -> some View {
		VStack(alignment: .leading, spacing: 0) {
			ForEach(recents.recentSearches) { entry in
				RecentSearchRow(entry: entry)
			}
		}
		.padding(.horizontal)
	}
	
	// MARK: - Content
	
	@ViewBuilder
	private func content(sections: [SearchResultSection]) -> some View {
		if isIdle {
			if recents.recentSearches.isEmpty {
				ContentUnavailableView(
					"Recent Searches",
					systemImage: "clock.arrow.circlepath",
					description: Text("Find patients by alias, ward, or bed — and ward notes by title or content.")
				)
			} else {
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						Text("Recent")
							.font(.headline.weight(.semibold))
							.foregroundStyle(.secondary)
							.padding(.top, 8)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal)
						
						recentsList()
							.background {
								RoundedRectangle(cornerRadius: 12, style: .continuous)
									.fill(Color(.secondarySystemGroupedBackground))
							}
							.padding(.horizontal)
						
						Button("Clear History", role: .destructive) {
							recents.clearAll()
						}
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.horizontal)
						.padding(.top, 4)
					}
				}
			}
		} else if sections.isEmpty {
			ContentUnavailableView.search(text: trimmedText)
		} else {
			resultsList(sections: sections)
		}
	}
	
	private func resultsList(sections: [SearchResultSection]) -> some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
				ForEach(sections) { section in
					Section {
						ForEach(section.results) { result in
							row(for: result)
								.padding(.horizontal)
						}
					} header: {
						sectionHeader(section.title)
					}
				}
			}
		}
		.scrollDismissesKeyboard(.interactively)
	}
	
	/// Dispatches each result kind to its row and destination
	@ViewBuilder
	private func row(for result: SearchResult) -> some View {
		switch result {
		case .patient(let patient):
			PatientSearchRow(patient: patient)
				.onTapGesture {
					recents.addPatient(patient)
					viewingPatient = patient
				}
		case .note(let note, let snippet):
			NoteSearchRow(note: note, snippet: snippet)
				.onTapGesture {
					recents.addNote(note)
					editingNote = note
				}
		}
	}
	
	/// Frosted pinned header, matching Ward Notes list treatment
	private func sectionHeader(_ title: String) -> some View {
		Text(title)
			.font(.headline.weight(.semibold))
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal)
			.padding(.vertical, 9)
			.background {
				Color(.systemBackground).opacity(0.5)
					.background(.ultraThinMaterial)
			}
	}
}

// MARK: - Recent Search Row

/// A single recent-search entry: icon, display name, type badge, and relative date.
private struct RecentSearchRow: View {
	let entry: RecentSearchesStore.Entry
	
	var systemImage: String {
		switch entry.type {
		case .patient: "person.fill"
		case .note: "text.pad.header"
		}
	}
	
	var typeLabel: String {
		switch entry.type {
		case .patient: "Patient"
		case .note: "Note"
		}
	}
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: systemImage)
				.font(.title3)
				.foregroundStyle(.secondary)
				.frame(width: 32, alignment: .leading)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(entry.displayName)
					.font(.subheadline.weight(.medium))
					.lineLimit(1)
				Text("\(typeLabel) · \(entry.selectedAt, format: .relative(presentation: .numeric)))")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer(minLength: 0)
		}
		.padding(.vertical, 6)
		.contentShape(Rectangle())
	}
}

#Preview {
	SearchView()
		.modelContainer(SampleData.previewContainer)
}
