//
//  PinnedSectionHeader.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/23.
//

import SwiftUI

/// Frosted section header for pinned headers in scrolling lists
///
/// Deliberately a material rather than Liquid Glass
struct PinnedSectionHeader: View {
	private let title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(title)
			.font(.headline.weight(.semibold))
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.horizontal)
			.padding(.vertical, 9)
			.background {
				Color(.systemBackground).opacity(0.5)
					.background(.ultraThinMaterial)
			}
	}
}

#Preview {
	VStack(spacing: 40) {
		PinnedSectionHeader("Today")
		PinnedSectionHeader("September 2025")
	}
}
