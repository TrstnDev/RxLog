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
                .tracking(-0.5)
                .fontWeight(.bold)
            
            Text(note.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(6)
                .tracking(-0.3)
                .fontWeight(.medium)
        }
        .fontDesign(.monospaced)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color("NotePreviewBackground"),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
    }
}
