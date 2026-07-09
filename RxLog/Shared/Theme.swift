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
	case barbie		= "Barbie"
	case berry 		= "Berry"
	case bubblegum	= "Bubblegum"
	case cacao		= "Cacao"
	case creamsicle	= "Creamsicle"
	case dusk		= "Dusk"
	case guava		= "Guava"
	case jade		= "Jade"
	case lime		= "Lime"
	case majorana	= "Majorana"
	case moss		= "Moss"
	case olive		= "Olive"
	case petal		= "Petal"
	case pine		= "Pine"
	case sunburn	= "Sunburn"
	case turquoise	= "Turquoise"
	case violet		= "Violet"
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
	
	// Dark, gradient-hued colour for text and icons in patient detail view (top of screen)
	var darkText: Color {
		end.mix(with: .black, by: 0.5)
	}
	
	// Bright, gradient-hued colour for text and icons in patient detail view (bottom of screen)
	var lightText: Color {
		start.mix(with: .white, by: 0.7)
	}
}

// MARK: - Reactive Theme Contrast

extension View {
	/// Shifts foreground colour seamlessly based on element's vertical position over the gradient
	/// Interpolates mathematically between the theme's dark and light text colours during scroll
	func reactiveContrast(for theme: AppGradient) -> some View {
		self.modifier(ReactiveContrastModifier(theme: theme))
	}
}

fileprivate struct ReactiveContrastModifier: ViewModifier {
	let theme: AppGradient
	
	/// Transition zone as fractions of the viewport height
	private let transitionStart: CGFloat = 0.55
	private let transitionEnd: CGFloat = 0.65
	
	@State private var fraction: CGFloat = 0
	
	func body(content: Content) -> some View {
		content
			.foregroundStyle(theme.darkText.mix(with: theme.lightText, by: smoothed(fraction)))
			.onGeometryChange(for: CGFloat.self) { proxy in
				guard let viewport = proxy.bounds(of: .scrollView) else { return 0 }
				return proxy.frame(in: .scrollView).midY / viewport.height
			} action: { fraction = $0 }
	}
	
	/// Remaps the raw viewport fraction into the transition zone, then applies smoothstep
	private func smoothed(_ raw: CGFloat) -> CGFloat {
		let t = min(max((raw - transitionStart) / (transitionEnd - transitionStart), 0), 1)
		return t * t * (3 - 2 * t)
	}
}
