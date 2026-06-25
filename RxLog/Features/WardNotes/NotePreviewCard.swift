//
//  NotePreviewCard.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

// A single note preview - title plus content snippet
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
        .background(Color("NotePreviewBackground"))
        .overlay(alignment: .topTrailing) {
            if note.isFavourite {
                favouriteBadge
            }
        }
        // Clip after overlay so fade scrim follows rounded corner
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        //.shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
    
    // Favourite star, top-right, on a gradient scrim
    private var favouriteBadge: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color("NotePreviewBackground").opacity(0),
                    Color("NotePreviewBackground")
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 90, height: 40)
            
            Image(systemName: "star.fill")
                .font(.subheadline)
                .foregroundStyle(.yellow)
                .padding([.top, .trailing], 14)
        }
    }
}
