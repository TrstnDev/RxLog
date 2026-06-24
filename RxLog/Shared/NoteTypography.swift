//
//  NoteTypography.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

extension View {
    // Shared monospace styling for note text (preview cards, list rows, and editor)
    func noteTypography() -> some View {
        self
            .fontDesign(.monospaced)
            .tracking(-0.3)
    }
}
