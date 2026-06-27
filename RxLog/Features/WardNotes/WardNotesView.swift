//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

/// <summary>Ward Notes home screen</summary>
struct WardNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [Note]
    
    // Presentation knobs
	@AppStorage("wardNotesDisplayStyle") private var displayStyle: NoteDisplayStyle = .waterfall
    @AppStorage("wardNotesSortOption") private var sortOption: NoteSortOption = .dateModified
    @State private var searchText = ""
    @State private var filter = NoteFilter()
    @State private var showingFilter = false
    
    // Selection
    @State private var isSelecting = false
    @State private var selectedNoteIDs = Set<Note.ID>()
    @State private var showingDeleteConfirmation = false
    
    // Editor routing
    @State private var editingNote: Note?
    
    var body: some View {
        // Run filter -> sort -> section pipeline once per render
        let sections = NoteListPipeline.sections(
            from: allNotes,
            searchText: searchText,
            filter: filter,
            sortOption: sortOption
        )
        let visibleNotes = sections.flatMap(\.notes)
        
        NavigationStack {
            content(sections: sections, visibleNotes: visibleNotes)
                .navigationTitle(navTitle)
                .navigationBarTitleDisplayMode(isSelecting ? .inline : .large)
                .toolbar { toolbarContent(visibleNotes: visibleNotes) }
                .toolbarVisibility(isSelecting ? .hidden : .automatic, for: .tabBar)
                .overlay(alignment: .bottomTrailing) {
                    if !isSelecting {
                        composeButton
                            .padding(15)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .sheet(isPresented: $showingFilter) {
                    NoteFilterSheet(filter: $filter)
                }
                .alert(
                    "Delete \(selectedNoteIDs.count) \(selectedNoteIDs.count == 1 ? "Note" : "Notes")?",
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button("Delete", role: .destructive) { deleteSelected() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This can't be undone.")
                }
                .navigationDestination(item: $editingNote) { note in
                    NoteEditorView(note: note)
        }
        }
    }
    
    // MARK: TOOLBAR
    
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
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedNoteIDs.isEmpty)
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select") { setSelecting(true) }
                    .disabled(visibleNotes.isEmpty)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
            
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            ToolbarItem(placement: .topBarTrailing) {
                optionsMenu
            }
        }
    }
    
    // MARK: CONTENT
    
    @ViewBuilder
    private func content(sections: [NoteSection], visibleNotes: [Note]) -> some View {
        if allNotes.isEmpty {
            ContentUnavailableView {
                Label("No Notes Yet", systemImage: "note.Text")
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
                searchBar
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
                searchBar
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
				searchBar
				if visibleNotes.isEmpty {
					noResults
				} else {
					LazyVStack(alignment: .leading, spacing: 25) {
						ForEach(sections) { section in
							VStack(alignment: .leading, spacing: 15) {
								if let title = section.title {
									Text(title)
										.font(.subheadline.weight(.medium))
										.foregroundStyle(.tertiary)
										//.padding(.leading)
								}
								VStack(spacing: 25) {
									ForEach(section.notes) { note in
										listRow(note)
									}
								}
							}
						}
					}
					.padding(.horizontal)
					.padding(.top, 8)
				}
			}
            
        }
    }
    
    /// <summary>A list row with a leading selection circle while selecting</summary>
    @ViewBuilder
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
    
    // MARK: SELECTION HELPERS
    
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
    
    private func handleTap(_ note: Note){
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
    
    // MARK: BULK ACTIONS
    
    private var selectedNotes: [Note] {
        allNotes.filter { selectedNoteIDs.contains($0.id) }
    }
    
    private var allSelectedAreFavourite: Bool {
        !selectedNotes.isEmpty && selectedNotes.allSatisfy(\.isFavourite)
    }
    
    // Plain-text rendering of the selected notes for the share sheet
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
    
    private func deleteSelected() {
        for note in selectedNotes {
            modelContext.delete(note)
        }
        setSelecting(false)
    }
    
    // MARK: REUSABLE PIECES
    
    private var searchBar: some View {
        SearchBar(text: $searchText)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
    
    private var noResults: some View {
        Group {
            if !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ContentUnavailableView {
                    Label("No Matching Notes", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("No notes match the current filters.")
                } actions: {
                    Button("Clear Filters") { filter = NoteFilter() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private var filterButton: some View {
        Button {
            showingFilter = true
        } label: {
            Label("Filter", systemImage: filter.isActive
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
    }
    
    private var composeButton: some View {
        Button {
            compose()
        } label: {
            Image(systemName: "pencil.and.scribble")
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 45, height: 45)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .accessibilityLabel("New Note")
    }
    
    // Creates a blank note, inserts it, and opens the editor
    private func compose() {
        let note = Note()
        modelContext.insert(note)
        editingNote = note
    }
    
    // Options menu
    private var optionsMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                ForEach(NoteSortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            
            Picker("Display Style", selection: $displayStyle) {
                ForEach(NoteDisplayStyle.allCases) { style in
                    Label(style.label, systemImage: style.systemImage).tag(style)
                }
            }
            
            Divider()
            
            // Stubs
            Button("Export", systemImage: "square.and.arrow.up") { }
            Button("Stats", systemImage: "chart.bar") { }
        } label: {
            Label("Options", systemImage: "ellipsis")
        }
    }
}

#Preview {
    WardNotesView()
        .modelContainer(SampleData.previewContainer)
}
