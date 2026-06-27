//
//  Theme.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/26.
//
// App-wide visual identity. Centralising design choices as a single source of truth.

import SwiftUI

// MARK: BRAND

/// <summary>Namespace for app-wide visual constants</summary>
enum Theme {
	static let brandGradient = LinearGradient(
		colors: [Color.accentColorLight, Color.accentColorDark],
		startPoint: .top,
		endPoint: .bottom
	)
}

// MARK: TYPOGRAPHY

/// <summary>Shared monospaced styling for note text</summary>
extension View {
	func noteTypography() -> some View {
		self
			.fontDesign(.monospaced)
			.tracking(-0.3)
	}
}
