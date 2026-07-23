//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// Ward Notes home screen: searchable, filterable notes with multi-select and three layouts
struct WardNotesView: View {
	@Environment(\.modelContext) private var modelContext
	@Query private var allNotes: [Note]
	
	// Presentation
	@AppStorage("wardNotesDisplayStyle") private var displayStyle: NoteDisplayStyle = .waterfall
	@AppStorage("wardNotesSortOption") private var sortOption: NoteSortOption = .dateModified
	@State private var filter = NoteFilter()
	@State private var showingFilter = false
	
	// Selection
	@State private var isSelecting = false
	@State private var selectedNoteIDs = Set<Note.ID>()
	@State private var pendingDeletion: PendingDeletion?
	
	/// Editor routing
	@State private var editingNote: Note?
	
	/// Pipeline cache
	@State private var cachedSections: [NoteSection] = []
	
	/// Single hash over every input the pipeline reads
	private var pipelineFingerprint: Int {
		var hasher = Hasher()
		hasher.combine(filter)
		hasher.combine(sortOption)
		for note in allNotes {
			hasher.combine(note.id)
			hasher.combine(note.title)
			hasher.combine(note.dateCreated)
			hasher.combine(note.dateModified)
			hasher.combine(note.lastViewed)
			hasher.combine(note.isFavourite)
		}
		return hasher.finalize()
	}
	
	var body: some View {
		// Serve from the cache, dropping just-deleted notes before fingerprint recompute lands
		let sections = cachedSections.compactMap { section -> NoteSection? in
			let live = section.notes.filter { !$0.isDeleted }
			return live.isEmpty ? nil : NoteSection(id: section.id, title: section.title, notes: live)
		}
		let visibleNotes = sections.flatMap(\.notes)
		
		NavigationStack {
			content(sections: sections, visibleNotes: visibleNotes)
				.navigationTitle(navTitle)
				.toolbarTitleDisplayMode(isSelecting ? .inline : .large)
				.toolbar { toolbarContent(visibleNotes: visibleNotes) }
				.toolbarVisibility(isSelecting ? .hidden : .automatic, for: .tabBar)
				.sheet(isPresented: $showingFilter) {
					NoteFilterSheet(filter: $filter)
				}
				.alert("Delete Notes?", item: $pendingDeletion) { pending in
					Button("Delete", role: .destructive) { delete(pending.ids) }
					Button("Cancel", role: .cancel) {}
				} message: { pending in
					Text("This permanently deletes ^[\(pending.ids.count) note](inflect: true) and can't be undone.")
				}
				.navigationDestination(item: $editingNote) { note in
					NoteEditorView(note: note)
				}
		}
		.onChange(of: pipelineFingerprint, initial: true) {
			cachedSections = NoteListPipeline.sections(
				from: allNotes,
				filter: filter,
				sortOption: sortOption
			)
		}
	}
	
	// MARK: - Toolbar
	
	@ToolbarContentBuilder
	private func toolbarContent(visibleNotes: [Note]) -> some ToolbarContent {
		if isSelecting {
			ToolbarItem(placement: .topBarLeading) {
				Button(allSelected(in: visibleNotes) ? "Deselect All" : "Select All") {
					toggleSelectAll(in: visibleNotes)
				}
			}
			
			ToolbarItem(placement: .topBarTrailing) {
				Button("Done") { setSelecting(false) }
					.fontWeight(.semibold)
			}
			
			ToolbarItemGroup(placement: .bottomBar) {
				ShareLink(item: shareText) {
					Label("Share", systemImage: "square.and.arrow.up")
				}
				.disabled(selectedNoteIDs.isEmpty)
				
				Spacer()
				
				Button {
					favouriteSelected()
				} label: {
					Label(
						allSelectedAreFavourite ? "Unfavourite" : "Favourite",
						systemImage: allSelectedAreFavourite ? "star.slash" : "star"
					)
				}
				.disabled(selectedNoteIDs.isEmpty)
				
				Spacer()
				
				Button(role: .destructive) {
					pendingDeletion = PendingDeletion(ids: selectedNoteIDs)
				} label: {
					Label("Delete", systemImage: "trash")
				}
				.disabled(selectedNoteIDs.isEmpty)
			}
		} else {
			ToolbarOverflowMenu {
				Section {
					Button("Select", systemImage: "checkmark.circle") {
						setSelecting(true)
					}
					.disabled(visibleNotes.isEmpty)
					
					Button {
						showingFilter = true
					} label: {
						Label(
							"Filter",
							systemImage: filter.isActive
							? "line.3.horizontal.decrease.circle.fill"
							: "line.3.horizontal.decrease.circle"
						)
					}
				}
				
				Section {
					Picker("Display Style", selection: $displayStyle) {
						ForEach(NoteDisplayStyle.allCases) { style in
							Label(style.label, systemImage: style.systemImage).tag(style)
						}
					}
					.pickerStyle(.inline)
				}
				
				Section {
					Picker("Sort By", selection: $sortOption) {
						ForEach(NoteSortOption.allCases) { option in
							Text(option.label).tag(option)
						}
					}
					.pickerStyle(.inline)
				}
				
				Section {
					Button("Export", systemImage: "square.and.arrow.up") { }
				}
			}
			
				// Primary creation action: pinned so it never collapses into overflow
			ToolbarItem(placement: .topBarPinnedTrailing) {
				Button {
					compose()
				} label: {
					Image(systemName: "pencil.and.scribble")
				}
				.buttonStyle(.glassProminent)
				.accessibilityLabel("New Note")
			}
		}
	}
	
	// MARK: - Content
	
	@ViewBuilder
	private func content(sections: [NoteSection], visibleNotes: [Note]) -> some View {
		if allNotes.isEmpty {
			ContentUnavailableView {
				Label("No Notes Yet", systemImage: "note.text")
			} description: {
				Text("Your ward notes will appear here.")
			}
		} else {
			notesContent(sections: sections, visibleNotes: visibleNotes)
				.scrollDismissesKeyboard(.immediately)
		}
	}
	
	@ViewBuilder
	private func notesContent(sections: [NoteSection], visibleNotes: [Note]) -> some View {
		switch displayStyle {
		case .waterfall:
			ScrollView {
				if visibleNotes.isEmpty {
					noResults
				} else {
					NoteWaterfall(
						notes: visibleNotes,
						isSelecting: isSelecting,
						selectedIDs: selectedNoteIDs,
						onTap: handleTap
					)
					.padding(.horizontal)
				}
			}
			
		case .grid:
			ScrollView {
				if visibleNotes.isEmpty {
					noResults
				} else {
					NoteSectionedGrid(
						sections: sections,
						isSelecting: isSelecting,
						selectedIDs: selectedNoteIDs,
						onTap: handleTap
					)
				}
			}
			
		case .list:
			ScrollView {
				if visibleNotes.isEmpty {
					noResults
				} else {
						// Pinned headers + lazy rows
					LazyVStack(alignment: .leading, spacing: 20, pinnedViews: [.sectionHeaders]) {
						ForEach(sections) { section in
							Section {
								ForEach(section.notes) { note in
									listRow(note)
										.padding(.horizontal)
										.swipeActions(edge: .leading) {
											if !isSelecting {
												Button {
													note.isFavourite.toggle()
												} label: {
													Label(note.isFavourite ? "Unfavourite" : "Favourite",
														  systemImage: note.isFavourite ? "star.slash" : "star")
												}
												.tint(.yellow)
											}
										}
										.swipeActions(edge: .trailing) {
											if !isSelecting {
												Button(role: .destructive) {
													modelContext.delete(note)
												} label: {
													Label("Delete", systemImage: "trash")
												}
											}
										}
								}
							} header: {
								if let title = section.title {
									PinnedSectionHeader(title)
								}
							}
						}
					}
					.swipeActionsContainer()
				}
			}
			.scrollDismissesKeyboard(.immediately)
		}
	}
	
	/// List row with a leading selection circle while selecting
	private func listRow(_ note: Note) -> some View {
		HStack(spacing: 12) {
			if isSelecting {
				SelectionIndicator(isSelected: selectedNoteIDs.contains(note.id))
					.transition(.scale.combined(with: .opacity))
			}
			NoteListRow(note: note)
		}
		.contentShape(Rectangle())
		.onTapGesture { handleTap(note) }
	}
	
	// MARK: - Selection Helpers
	
	private var navTitle: String {
		guard isSelecting else { return "Ward Notes" }
		return selectedNoteIDs.isEmpty ? "Select Notes" : "\(selectedNoteIDs.count) Selected"
	}
	
	private func allSelected(in visibleNotes: [Note]) -> Bool {
		!visibleNotes.isEmpty && selectedNoteIDs.count == visibleNotes.count
	}
	
	private func toggleSelection(_ note: Note) {
		if selectedNoteIDs.contains(note.id) {
			selectedNoteIDs.remove(note.id)
		} else {
			selectedNoteIDs.insert(note.id)
		}
	}
	
	private func handleTap(_ note: Note) {
		if isSelecting {
			toggleSelection(note)
		} else {
			editingNote = note
		}
	}
	
	private func toggleSelectAll(in visibleNotes: [Note]) {
		withAnimation(.easeInOut(duration: 0.15)) {
			selectedNoteIDs = allSelected(in: visibleNotes) ? [] : Set(visibleNotes.map(\.id))
		}
	}
	
	private func setSelecting(_ on: Bool) {
		withAnimation(.easeInOut(duration: 0.2)) {
			isSelecting = on
			if !on { selectedNoteIDs.removeAll() }
		}
	}
	
	// MARK: - Bulk Actions
	
	private var selectedNotes: [Note] {
		allNotes.filter { selectedNoteIDs.contains($0.id) }
	}
	
	private var allSelectedAreFavourite: Bool {
		!selectedNotes.isEmpty && selectedNotes.allSatisfy(\.isFavourite)
	}
	
	/// Plain-text rendering of the selected notes for the share sheet
	private var shareText: String {
		selectedNotes
			.map { note in
				note.plainText.isEmpty ? note.title : "\(note.title)\n\n\(note.plainText)"
			}
			.joined(separator: "\n\n---\n\n")
	}
	
	private func favouriteSelected() {
		let newValue = !allSelectedAreFavourite
		for note in selectedNotes {
			note.isFavourite = newValue
		}
		setSelecting(false)
	}
	
	/// Deletes the captured snapshot of note IDs, then exits selection
	private func delete(_ ids: Set<Note.ID>) {
		for note in allNotes where ids.contains(note.id) {
			modelContext.delete(note)
		}
		setSelecting(false)
	}
	
	// MARK: - Subviews
	
	private var noResults: some View {
		ContentUnavailableView {
			Label("No Matching Notes", systemImage: "line.3.horizontal.decrease.circle")
		} description: {
			Text("No notes match the current filters.")
		} actions: {
			Button("Clear Filters") { filter = NoteFilter() }
		}
		.frame(maxWidth: .infinity)
		.padding(.top, 40)
	}
	
	/// Inserts a blank note and opens it in the editor
	private func compose() {
		let note = Note()
		modelContext.insert(note)
		editingNote = note
	}
}

// MARK: - Pending Deletion

/// Bulk-delete request captured at the moment the user asks so confirmation acts exactly on selection
private struct PendingDeletion: Identifiable {
	let id = UUID()
	let ids: Set<Note.ID>
}

#Preview {
	WardNotesView()
		.modelContainer(SampleData.previewContainer)
}
