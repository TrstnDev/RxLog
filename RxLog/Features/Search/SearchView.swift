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
			text: trimmedText,
			tokens: []
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
	
	// MARK: - Content
	
	@ViewBuilder
	private func content(sections: [SearchResultSection]) -> some View {
		if isIdle {
			ContentUnavailableView(
				"No Recent Searches",
				systemImage: "waveform.path.ecg.magnifyingglass",
				description: Text("Find patients by alias, ward, or bed - and ward notes by title or content.")
			)
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
				.onTapGesture { viewingPatient = patient }
		case .note(let note, let snippet):
			NoteSearchRow(note: note, snippet: snippet)
				.onTapGesture { editingNote = note }
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
	
	private var noResults: some View {
		Group {
			if trimmedText.isEmpty {
				ContentUnavailableView {
					Label("No Matches", systemImage: "questionmark.folder")
				} description: {
					Text("Nothing matches the selected tokens.")
				}
			} else {
				ContentUnavailableView.search(text: trimmedText)
			}
		}
	}
}

#Preview {
	SearchView()
		.modelContainer(SampleData.previewContainer)
}
