//
//  Theme.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/26.
//
//	App-wide visual identity. Centralising design choices as a single source of truth.

import SwiftUI

// MARK: - Brand

/// App-wide visual constants
enum Theme {
	/// Vertical brand gradient used across splash, onboarding, and accents
	static let brandGradient = LinearGradient(
		colors: [Color.accentColorLight, Color.accentColorDark],
		startPoint: .top,
		endPoint: .bottom
	)
}

// MARK: - Typography

/// Shared note text style: monospaced with tightened tracking
extension View {
	func noteTypography() -> some View {
		self
			.fontDesign(.monospaced)
			.tracking(-0.3)
	}
}
