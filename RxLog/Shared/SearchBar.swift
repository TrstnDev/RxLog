//
//  SearchBar.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

struct SearchBar: View {
	@Binding var text: String
	var prompt: String = "Search notes"

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)

			TextField(prompt, text: $text)
				.autocorrectionDisabled()
				.textInputAutocapitalization(.never)

			if !text.isEmpty {
				Button {
					text = ""
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Clear search")
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.glassEffect()
	}
}
