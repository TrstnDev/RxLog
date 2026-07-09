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
		start.mix(with: .white, by: 0.25)
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
	
	/// Retrieves height of the current active window scene
	private var activeWindowHeight: CGFloat {
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
			return windowScene.screen.bounds.height
		}
		return 852 	// Safe fallback (iPhone 15 Pro / standard bounds)
	}
	
	func body(content: Content) -> some View {
		content
			.hidden()	// reserved exact layout dimensions of text/icon
			.overlay {
				GeometryReader { geo in
					let yPos = geo.frame(in: .global).midY
					let linearFraction = max(0, min(1, yPos / activeWindowHeight))
					
					// Define tight transition zone
					let transitionStart: CGFloat = 0.6
					let transitionEnd: CGFloat = 0.7
					
					// Remap linear fraction so it only shifts within that window
					let steepFraction = max(0, min(1, (linearFraction - transitionStart) / (transitionEnd - transitionStart)))
					
					// Apply mathematical smoothstep to prevent abrupt colour snapping
					let smoothFraction = 4 * (steepFraction * steepFraction)
					
					// Mix the colours using the new highly contrasted S-Curve
					let dynamicColor = theme.darkText.mix(with: theme.lightText, by: smoothFraction)
					
					content
						.foregroundStyle(dynamicColor)
				}
			}
	}
}
