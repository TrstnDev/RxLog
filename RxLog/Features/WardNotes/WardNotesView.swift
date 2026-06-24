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
    
    // Single source of display order
    private var sortedNotes: [Note] {
        if let dateKeyPath = sortOption.dateKeyPath {
            return allNotes.sorted { $0[keyPath: dateKeyPath] > $1[keyPath: dateKeyPath] }
        } else {
            return allNotes.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
    }
    
    // Date-bucketed sections for the grid and list layouts
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
                        optionsMenu
                    }
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
            switch displayStyle {
            case .waterfall:
                ScrollView {
                    NoteWaterfall(notes: sortedNotes)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
            case .grid:
                ScrollView {
                    NoteSectionedGrid(sections: sections)
                }
            case .list:
                NoteSectionedList(sections: sections)
            }
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
