//
//  NotePreviewCard.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

struct NotePreviewCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
                .lineLimit(2)
                .fontWeight(.bold)
            
            Text(note.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(6)
                .fontWeight(.medium)
        }
        .noteTypography()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color("NotePreviewBackground"),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
    }
}
