//
//  Selectable.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/23.
//

import SwiftUI

/// Adds select-mode behaviour to any card: indicator, highlight border, and tap bounce
struct Selectable: ViewModifier {
	let isSelecting: Bool
	let isSelected: Bool
	let cornerRadius: CGFloat
	let onTap: () -> Void
	
	/// Retriggers the bounce animation on each tap
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
				SpringKeyframe(0.91, duration: 0.14, spring: .bouncy)
				SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
			}
	}
}

// MARK: - View + Selectable

/// Applies `Selectable` to a card
extension View {
	func selectable(
		isSelecting: Bool,
		isSelected: Bool,
		cornerRadius: CGFloat,
		onTap: @escaping () -> Void
	) -> some View {
		modifier(Selectable(
			isSelecting: isSelecting,
			isSelected: isSelected,
			cornerRadius: cornerRadius,
			onTap: onTap
		))
	}
}
