//
//  NoteSectionedGrid.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

// "Grid" layout: full-width note cards stacked under date-sectioned headers
struct NoteSectionedGrid: View {
    let sections: [NoteSection]
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    
                    ForEach(section.notes) { note in
                        NotePreviewCard(note: note)
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
