//
//  NoteSelection.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/25.
//

import SwiftUI

// Circular checkbox shown on notes during Select mode
struct SelectionIndicator: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                .overlay {
                    Circle().strokeBorder(
                        isSelected ? .clear : Color.gray.opacity(0.5),
                        lineWidth: 1.5
                    )
                }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}

// Adds select-mode behaviour to a note card
struct NoteSelectable: ViewModifier {
    let isSelecting: Bool
    let isSelected: Bool
    var cornerRadius: CGFloat = 25
    let onTap: () -> Void
    
    // Incremented on each tap of a card; drives bounce animation
    @State private var bounceTrigger = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if isSelecting {
                    SelectionIndicator(isSelected: isSelected)
                        .padding(10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .overlay {
                if isSelecting && isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture {
                if isSelecting { bounceTrigger += 1 }
                onTap()
            }
            .keyframeAnimator(initialValue: 1.0, trigger: bounceTrigger) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                SpringKeyframe(0.91, duration: 0.14, spring: .snappy)
                SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
            }
    }
}

extension View {
    func noteSelectable(
        isSelecting: Bool,
        isSelected: Bool,
        cornerRadius: CGFloat = 25,
        onTap: @escaping () -> Void
    ) -> some View {
        modifier(NoteSelectable(
            isSelecting: isSelecting,
            isSelected: isSelected,
            cornerRadius: cornerRadius,
            onTap: onTap
        ))
    }
}
