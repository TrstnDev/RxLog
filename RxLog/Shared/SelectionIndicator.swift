//
//  SelectionIndicator.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/22.
//

import SwiftUI

/// Circular checkbox shown on selectable content in Select mode
///
/// Shared across features: note cards and rows (Ward Notes)
struct SelectionIndicator: View {
	let isSelected: Bool
	
	var body: some View {
		ZStack {
			Circle()
				.fill(isSelected ? Color.accentColor : Color(.systemBackground))
				.overlay {
					Circle().strokeBorder(
						isSelected ? .clear : Color.gray.opacity(0.5),
						lineWidth: 2.0
					)
				}
			if isSelected {
				Image(systemName: "checkmark")
					.font(.system(size: 13, weight: .bold))
					.foregroundStyle(.white)
			}
		}
		.frame(width: 25, height: 25)
	}
}

#Preview {
	HStack(spacing: 20) {
		SelectionIndicator(isSelected: false)
		SelectionIndicator(isSelected: true)
	}
	.padding()
}
