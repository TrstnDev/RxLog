//
//  NoteListRow.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

// Compact one-line row for list layout
struct NoteListRow: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(
                    Color("NotePreviewBackground"),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .noteTypography()
            
            Spacer(minLength: 0)
            
            if note.isFavourite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}
