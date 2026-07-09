//
//  Theme.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/26.
//
//	App-wide visual identity. Centralising design choices as a single source of truth.

import SwiftUI

// MARK: - Gradients

/// The app's named gradients, each backed one-to-one by a namespaced colour pair in the asset catalogue: `Gradients/<RawValue>/Start` and `Gradients/<RawValue>/End`
///
/// `accent` is the reserved brand gradient; the remaining cases form the patient-profile palette
nonisolated enum AppGradient: String, CaseIterable, Identifiable, Codable {
	case accent 	= "Accent"
	case abyss		= "Abyss"
	case berry 		= "Berry"
	case cacao		= "Cacao"
	case dusk		= "Dusk"
	case jade		= "Jade"
	case lime		= "Lime"
	case majorana	= "Majorana"
	case moss		= "Moss"
	case olive		= "Olive"
	case petal		= "Petal"
	case sunburn	= "Sunburn"
	case volt		= "Volt"
	case winter		= "Winter"
	
	var id: String { rawValue }
	
	/// Selectable gradients for patient profiles
	static var patientPalette: [AppGradient] { allCases.filter { $0 != .accent } }
	
	/// The two asset colours backing the gradient
	private var start: Color { Color("Gradients/\(rawValue)/Start") }
	private var end: Color { Color("Gradients/\(rawValue)/End") }
	
	/// Builds gradient; defaults to a vertical top -> bottom sweep
	func linear(startPoint: UnitPoint = .top, endPoint: UnitPoint = .bottom) -> LinearGradient {
		LinearGradient(colors: [start, end], startPoint: startPoint, endPoint: endPoint)
	}
	
	// Dark, gradient-hued colour for text and icons in patient detail view
	var darkText: Color {
		end.mix(with: .black, by: 0.45)
	}
	
	// Brightened version of gradient for a glassy glyph hero
	var glassGlyph: LinearGradient {
		LinearGradient(
			colors: [start.mix(with: .white, by: 0.5), end.mix(with: .white, by: 0.3)],
			startPoint: .top,
			endPoint: .bottom
		)
	}
}

// MARK: - Inline Styling

/// Lets any `ShapeStyle` slot accept `.app(_:)`
extension ShapeStyle where Self == LinearGradient {
	static func app(_ gradient: AppGradient, start: UnitPoint = .top, end: UnitPoint = .bottom) -> LinearGradient {
		gradient.linear(startPoint: start, endPoint: end)
	}
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
