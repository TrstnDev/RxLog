//
//  NoteSectionedList.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

// "List" layout: compact rows grouped into native list sections
struct NoteSectionedList: View {
    let sections: [NoteSection]
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.notes) { note in
                        NoteListRow(note: note)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NoteSectionedList(sections: NoteSectioner.sections(from: SampleData.sampleNotes))
}
