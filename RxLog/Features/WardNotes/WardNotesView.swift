//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

struct WardNotesView: View {
    
    // SwiftData live fetch
    @Query(sort: \Note.dateModified, order: .reverse)
    private var notes: [Note]
    
    // Current layout, defaults to waterfall
    @State private var displayStyle: NoteDisplayStyle = .waterfall
    
    // Date-bucketed sections for the grid and list layouts
    private var sections: [NoteSection] {
        NoteSectioner.sections(from: notes)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Ward Notes")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if notes.isEmpty {
            ContentUnavailableView {
                Label("No Notes Yet", systemImage: "note.Text")
            } description: {
                Text("Your ward notes will appear here.")
            }
        } else {
            switch displayStyle {
            case .waterfall:
                ScrollView {
                    NoteWaterfall(notes: notes)
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
}

#Preview {
    WardNotesView()
        .modelContainer(SampleData.previewContainer)
}
