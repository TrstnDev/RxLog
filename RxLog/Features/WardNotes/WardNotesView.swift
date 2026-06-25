//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

struct WardNotesView: View {
    
    @Query private var allNotes: [Note]
    
    @State private var displayStyle: NoteDisplayStyle = .waterfall
    @State private var sortOption: NoteSortOption = .dateModified
    @State private var searchText: String = ""
    @State private var filter = NoteFilter()
    @State private var showingFilter = false
    
    // Stage 1 of filter & search - content stored as encoded Data
    private var filteredNotes: [Note] {
        allNotes.filter { note in
            guard filter.matches(note) else { return false }
            guard !searchText.isEmpty else { return true }
            return note.title.localizedStandardContains(searchText)
                || String(note.content.characters).localizedStandardContains(searchText)
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
                .navigationTitle("Ward Notes")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        filterButton
                    }
                    
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        optionsMenu
                    }
                }
                .sheet(isPresented: $showingFilter) {
                    NoteFilterSheet(filter: $filter)
                }
        }
    }
    
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
                    NoteWaterfall(notes: sortedNotes)
                        .padding(.horizontal)
                }
            }
        case .grid:
            ScrollView {
                searchBar
                if sortedNotes.isEmpty {
                    noResults
                } else {
                    NoteSectionedGrid(sections: sections)
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
                                NoteListRow(note: note)
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
