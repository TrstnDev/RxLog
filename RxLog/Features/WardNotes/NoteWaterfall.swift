//
//  NoteWaterfall.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

struct NoteWaterfall: View {
    let notes: [Note]
    var columnCount: Int = 2
    var spacing: CGFloat = 12
    
    private var columns: [[Note]] {
        var buckets = Array(repeating: [Note](), count: columnCount)
        for (index, note) in notes.enumerated() {
            buckets[index % columnCount].append(note)
        }
        return buckets
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, columnNotes in
                LazyVStack(spacing: spacing) {
                    ForEach(columnNotes) { note in
                        NotePreviewCard(note: note)
                    }
                }
            }
        }
    }
}
