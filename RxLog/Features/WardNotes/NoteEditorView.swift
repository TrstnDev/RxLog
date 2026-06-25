//
//  NoteEditorView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/25.
//

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    
    @Bindable var note: Note
    
    @State private var selection = AttributedTextSelection()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $note.title, axis: .vertical)
                .font(.title2)
                .fontWeight(.semibold)
                .noteTypography()
                .textFieldStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
            
            TextEditor(text: $note.content, selection: $selection)
                .noteTypography()
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: note.title) { note.dateModified = .now }
        .onChange(of: note.content) { note.dateModified = .now }
        .onAppear { note.lastViewed = .now }
    }
}

#Preview {
    NavigationStack {
        NoteEditorView(
            note: Note(
                title : "Bed 12 - Mr. Dlamini",
                content: AttributedString(
                    "Day 1 post addendectomy. Obs stable, afebrile. Wound clean and dry."
                )
            )
        )
    }
    .modelContainer(for: Note.self, inMemory: true)
}
