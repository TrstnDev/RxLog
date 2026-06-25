//
//  NoteSectionedGrid.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

// "Grid" layout: full-width note cards stacked under date-sectioned headers
struct NoteSectionedGrid: View {
    let sections: [NoteSection]
    
    var isSelecting: Bool = false
    var selectedIDs: Set<Note.ID> = []
    var onToggle: (Note) -> Void = { _ in }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    if let title = section.title {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                    ForEach(section.notes) { note in
                        NotePreviewCard(note: note)
                            .noteSelectable(
                                isSelecting: isSelecting,
                                isSelected: selectedIDs.contains(note.id),
                                onToggle: { onToggle(note) }
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    ScrollView {
        NoteSectionedGrid(sections: NoteSectioner.sections(from: SampleData.sampleNotes))
    }
}
