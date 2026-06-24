//
//  WardNotesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

struct WardNotesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Notes Yet",
                systemImage: "note.text",
                description: Text("Ward notes and handovers will appear here.")
            )
            .navigationTitle("Ward Notes")
        }
    }
}

#Preview {
    WardNotesView()
}
