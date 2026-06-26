//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

struct WardNotesView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [Note]
    
    @State private var displayStyle: NoteDisplayStyle = .waterfall
    @State private var sortOption: NoteSortOption = .dateModified
    @State private var searchText: String = ""
    @State private var filter = NoteFilter()
    @State private var showingFilter = false
    
    // --- Selection ---
    @State private var isSelecting = false
    @State private var selectedNoteIDs = Set<Note.ID>()
    @State private var showingDeleteConfirmation = false
    
    @State private var editingNote: Note?
    
    // Stage 1 of filter & search - content stored as encoded Data
    private var filteredNotes: [Note] {
        allNotes.filter { note in
            guard filter.matches(note) else { return false }
            guard !searchText.isEmpty else { return true }
            return note.title.localizedStandardContains(searchText)
            || note.plainText.localizedStandardContains(searchText)
        }
    }
    
    // Stage 2 of filter & search - display order of filtered set
    private var sortedNotes: [Note] {
        if let dateKeyPath = sortOption.dateKeyPath {
            return filteredNotes.sorted { $0[keyPath: dateKeyPath] > $1[keyPath: dateKeyPath] }
        } else {
            return filteredNotes.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
    }
    
    // Stage 3 of filter & search - bucket into sections for the grid and list layouts
    private var sections: [NoteSection] {
        if let dateKeyPath = sortOption.dateKeyPath {
            return NoteSectioner.sections(from: sortedNotes, by: dateKeyPath)
        } else {
            return [NoteSection(id: "all", title: nil, notes: sortedNotes)]
        }
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navTitle)
                .navigationBarTitleDisplayMode(isSelecting ? .inline : .large)
                .toolbar { toolbarContent }
                .toolbarVisibility(isSelecting ? .hidden : .automatic, for: .tabBar)
                .overlay(alignment: .bottomTrailing) {
                    if !isSelecting {
                        composeButton
                            .padding(20)
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
    
    // MARK: Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button(allSelected ? "Deselect All" : "Select All") { toggleSelectAll() }
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
                    .disabled(sortedNotes.isEmpty)
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
    
    // MARK: Content
    
    @ViewBuilder
    private var content: some View {
        if allNotes.isEmpty {
            ContentUnavailableView {
                Label("No Notes Yet", systemImage: "note.Text")
            } description: {
                Text("Your ward notes will appear here.")
            }
        } else {
            notesContent
                .scrollDismissesKeyboard(.immediately)
        }
    }
    
    @ViewBuilder
    private var notesContent: some View {
        switch displayStyle {
        
        case .waterfall:
            ScrollView {
                searchBar
                if sortedNotes.isEmpty {
                    noResults
                } else {
                    NoteWaterfall(
                        notes: sortedNotes,
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
                if sortedNotes.isEmpty {
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
            List {
                searchBar
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                
                if sortedNotes.isEmpty {
                    noResults
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.notes) { note in
                                listRow(note)
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            if let title = section.title { Text(title) }
                        }
                        .listSectionSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            
        }
    }
    
    // A list row with a leading selection circle while selecting
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
        .onTapGesture {
            if isSelecting { handleTap(note) }
        }
    }
    
    // MARK: Selection Helpers
    
    private var navTitle: String {
        guard isSelecting else { return "Ward Notes" }
        return selectedNoteIDs.isEmpty ? "Select Notes" : "\(selectedNoteIDs.count) Selected"
    }
    
    private var allSelected: Bool {
        !sortedNotes.isEmpty && selectedNoteIDs.count == sortedNotes.count
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
    
    private func toggleSelectAll() {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedNoteIDs = allSelected ? [] : Set(sortedNotes.map(\.id))
        }
    }
    
    private func setSelecting(_ on: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelecting = on
            if !on { selectedNoteIDs.removeAll() }
        }
    }
    
    // MARK: Bulk actions
    
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
                let body = String(note.content.characters)
                return body.isEmpty ? note.title : "\(note.title)\n\n\(body)"
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
    
    // MARK: Reusable bits
    
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
            Image(systemName: "pencil")
                .font(.title2)
                .fontWeight(.black)
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
