//
//  SearchView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//

import SwiftData
import SwiftUI

/// Universal search tab: owns its search field state and renders for the query state
/// sectioned results from ``UniversalSearch``
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
	
	/// Idle until the user types
	private var isIdle: Bool {
		trimmedText.isEmpty
	}
	
	/// Patients are searchable only after the declaration is accepted
	private var searchablePatients: [Patient] {
		acceptedVersion >= PatientConsent.currentVersion ? patients : []
	}
	
	/// Recents resolved against live models, preserving recency order.
	///
	/// Resolution is pure in-memory dictionary lookup on model-owned UUIDs —
	/// deleted notes and expired/removed patients fail to resolve and are simply
	/// not shown, so the UI can never surface a dead entry even before
	/// ``pruneRecents()`` runs.
	private var resolvedRecents: [ResolvedRecent] {
		let patientsByID = Dictionary(uniqueKeysWithValues: patients.map { ($0.uuid, $0) })
		let notesByID = Dictionary(uniqueKeysWithValues: notes.map { ($0.uuid, $0) })
		
		return recents.entries.compactMap { entry in
			switch entry.kind {
			case .patient:
				guard let patient = patientsByID[entry.id], !patient.isExpired else { return nil }
				return .patient(patient, entry: entry)
			case .note:
				guard let note = notesByID[entry.id] else { return nil }
				return .note(note, entry: entry)
			}
		}
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
				.onAppear(perform: pruneRecents)
		}
	}
	
		// MARK: - Recents
	
		/// Sweeps stored entries that no longer point at a live, in-window model
	private func pruneRecents() {
		var valid = Set(notes.map(\.uuid))
		for patient in patients where !patient.isExpired {
			valid.insert(patient.uuid)
		}
		recents.prune(keeping: valid)
	}
	
		/// Opens a recent selection and bumps it to the front of the list
	private func open(_ recent: ResolvedRecent) {
		switch recent {
		case .patient(let patient, _):
			recents.record(patient)
			viewingPatient = patient
		case .note(let note, _):
			recents.record(note)
			editingNote = note
		}
	}
	
	private func recentsList(_ items: [ResolvedRecent]) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			ForEach(items) { recent in
				RecentSearchRow(recent: recent)
					.onTapGesture { open(recent) }
					.contextMenu {
						Button("Remove", systemImage: "minus.circle", role: .destructive) {
							recents.remove(recent.entry)
						}
					}
			}
		}
		.padding(.horizontal)
	}
	
		// MARK: - Content
	
	@ViewBuilder
	private func content(sections: [SearchResultSection]) -> some View {
		if isIdle {
			let recentItems = resolvedRecents
			if recentItems.isEmpty {
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
						
						recentsList(recentItems)
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
						PinnedSectionHeader(section.title)
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
					recents.record(patient)
					viewingPatient = patient
				}
		case .note(let note, let snippet):
			NoteSearchRow(note: note, snippet: snippet)
				.onTapGesture {
					recents.record(note)
					editingNote = note
				}
		}
	}
	
}

	// MARK: - Resolved Recent

	/// A recents entry paired with the live model it resolved to
private enum ResolvedRecent: Identifiable {
	case patient(Patient, entry: RecentSearchesStore.Entry)
	case note(Note, entry: RecentSearchesStore.Entry)
	
	var id: UUID {
		entry.id
	}
	
	var entry: RecentSearchesStore.Entry {
		switch self {
		case .patient(_, let entry), .note(_, let entry): entry
		}
	}
	
		/// Display name read from the live model, never a stored snapshot
	var displayName: String {
		switch self {
		case .patient(let patient, _): patient.displayName
		case .note(let note, _): note.displayTitle
		}
	}
}

	// MARK: - Recent Search Row

	/// A single recent-search entry: icon, live display name, type badge, and relative date
private struct RecentSearchRow: View {
	let recent: ResolvedRecent
	
	private var systemImage: String {
		switch recent {
		case .patient: "person.fill"
		case .note: "text.pad.header"
		}
	}
	
	private var typeLabel: String {
		switch recent {
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
				Text(recent.displayName)
					.font(.subheadline.weight(.medium))
					.lineLimit(1)
				Text("\(typeLabel) · \(recent.entry.selectedAt, format: .relative(presentation: .named))")
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
