//
//  SymbolStyle.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/04.
//
//  Reusable SF symbol customiser - applicable to any symbol via `.symbolStyle(_:)` or use `StyledSymbol` for a variable value.

import SwiftUI

// MARK: - Configuration Enums
// Small choices that map onto the Symbol's framework effect-configuration properties

/// Whether an effect animates each layer in turn, or the whole symbol
enum SymbolScope { case wholeSymbol, byLayer }

/// Vertical direction for bounce/scale/appear/disappear
enum SymbolVDirection { case up, down }

/// Rotation direction
enum SymbolRotation { case clockwise, counterClockwise }

/// Wiggle direction
enum SymbolWiggle { case up, down, left, right, forward, backward, clockwise, counterClockwise }

/// Breathe styles: `plain` (scale) or `pulse` (opacity)
enum SymbolBreathe { case plain, pulse }

/// Variable-colour fill: `iterative` lights one layer at a time; `cumulative` keeps them lit
enum VariableColorFill { case iterative, cumulative }

/// How non-highlighted variable-colour layers render
enum InactiveLayers { case dim, hide }

/// Replace directions (direction old symbol leaves / new one enters)
enum SymbolReplace { case downUp, upUp, offUp }

/// Repeat behaviour for indefinite effects
enum SymbolRepeatMode { case once, continuous, periodic(delay: Double) }

// MARK: - Animation

/// Every SF Symbol effect, with its own configuration
enum SymbolAnimation {
	case none
	
	/// Indefinite - via ``symbolEffect(_:options:isActive:)``
	case bounce(SymbolVDirection = .up, scope: SymbolScope = .wholeSymbol)
	case pulse(scope: SymbolScope = .byLayer)
	case variableColor(VariableColorFill = .cumulative, inactive: InactiveLayers = .dim, reverses: Bool = false)
	case scale(SymbolVDirection = .up, scope: SymbolScope = .byLayer)
	case wiggle(SymbolWiggle = .left, scope: SymbolScope = .byLayer)
	case rotate(SymbolRotation = .clockwise, scope: SymbolScope = .byLayer)
	case breathe(SymbolBreathe = .plain, scope: SymbolScope = .wholeSymbol)
	
	/// Transition (fires on insert/remove) - via ``.transition(.symbolEffect(_:))``
	case appear(SymbolVDirection = .up, scope: SymbolScope = .wholeSymbol)
	case disappear(SymbolVDirection = .down, scope: SymbolScope = .wholeSymbol)
	case drawOn(scope: SymbolScope = .wholeSymbol)
	case drawOff(scope: SymbolScope = .wholeSymbol)
	
	/// Content transition (fires on symbol-name change) - via ``.contentTransition(.symbolEffect(.replace))``
	case replace(SymbolReplace = .downUp, scope: SymbolScope = .wholeSymbol)
}

// MARK: - Style

/// Complete symbol styling value: rendering + colours + animation
struct SymbolStyle {
	// Rendering
	var renderingMode: SymbolRenderingMode? = nil
	var colorRenderingMode: SymbolColorRenderingMode? = nil
	var colors: [Color] = []
	var variableValue: Double? = nil
	var font: Font? = nil
	
	// Animation
	var animation: SymbolAnimation = .none
	var repeatMode: SymbolRepeatMode = .continuous
	var speed: Double = 1.0
	var isActive: Bool = true
}

// MARK: - Fluent Builder

extension SymbolStyle {
	func rendering(_ mode: SymbolRenderingMode?) -> Self { with { $0.renderingMode = mode } }
	func gradient(_ on: Bool = true) -> Self { with { $0.colorRenderingMode = on ? .gradient : .flat } }
	func colors(_ colors: Color...) -> Self { with { $0.colors = colors } }
	func variableValue(_ value: Double?) -> Self { with { $0.variableValue = value } }
	func font(_ font: Font?) -> Self { with { $0.font = font } }
	func effect(_ animation: SymbolAnimation) -> Self { with { $0.animation = animation } }
	func repeats(_ mode: SymbolRepeatMode) -> Self { with { $0.repeatMode = mode } }
	func speed(_ speed: Double) -> Self { with { $0.speed = speed } }
	func active(_ active: Bool) -> Self { with { $0.isActive = active } }

	/// Copy-and-mutate helper underpinning fluent API
	private func with(_ mutate: (inout Self) -> Void) -> Self {
		var copy = self
		mutate(&copy)
		return copy
	}
}

// MARK: - Application

extension View {
	/// Applies a ``SymbolStyle`` to any symbol image in this view
	func symbolStyle(_ style: SymbolStyle) -> some View {
		modifier(SymbolStyleModifier(style: style))
	}
}

/// A self-contained styled symbol
struct StyledSymbol: View {
	let systemName: String
	var style: SymbolStyle = SymbolStyle()
	
	var body: some View {
		Image(systemName: systemName, variableValue: style.variableValue)
			.font(style.font)
			.symbolStyle(style)
	}
}

// MARK: - Modifiers

/// Applies the whole style: value-typed rendering modifiers then the animation
private struct SymbolStyleModifier: ViewModifier {
	let style: SymbolStyle
	
	func body(content: Content) -> some View {
		content
			.symbolRenderingMode(style.renderingMode)
			.symbolColorRenderingMode(style.colorRenderingMode)
			.modifier(SymbolForegroundColors(colors: style.colors))
			.modifier(SymbolAnimationDispatch(style: style))
	}
}

/// Chooses the `foregroundStyle` overload matching the number of colours supplied (0-3)
private struct SymbolForegroundColors: ViewModifier {
	let colors: [Color]
	
	@ViewBuilder
	func body(content: Content) -> some View {
		switch colors.count {
		case 0: content
		case 1: content.foregroundStyle(colors[0])
		case 2: content.foregroundStyle(colors[0], colors[1])
		default: content.foregroundStyle(colors[0], colors[1], colors[2])
		}
	}
}

/// Maps each `SymbolAnimation` case onto one of the four effect surfaces
private struct SymbolAnimationDispatch: ViewModifier {
	let style: SymbolStyle
	
	/// Options for repeating indefinite effects: repeat behaviour + speed
	private var options: SymbolEffectOptions {
		let base: SymbolEffectOptions
		
		switch style.repeatMode {
		case .once:
			base = .nonRepeating
		case .continuous:
			base = .repeat(.continuous)
		case .periodic(let delay):
			base = .repeat(.periodic(delay: delay))
		}
		return base.speed(style.speed)
	}
	
	/// Options for one-shot transitions/replace: speed only
	private var oneShotOptions: SymbolEffectOptions { .default.speed(style.speed) }
	
	@ViewBuilder
	func body(content: Content) -> some View {
		switch style.animation {
		case .none:
			content
			
		// ---- Indefinite ------------------------------------------------------------------------------
		case .bounce(let dir, let scope):
			content.symbolEffect(bounce(dir, scope), options: options, isActive: style.isActive)
		case .pulse(let scope):
			content.symbolEffect(pulse(scope), options: options, isActive: style.isActive)
		case .variableColor(let fill, let inactive, let reverses):
			content.symbolEffect(variableColor(fill, inactive, reverses), options: options, isActive: style.isActive)
		case .scale(let dir, let scope):
			content.symbolEffect(scale(dir, scope), options: options, isActive: style.isActive)
		case .wiggle(let dir, let scope):
			content.symbolEffect(wiggle(dir, scope), options: options, isActive: style.isActive)
		case .rotate(let dir, let scope):
			content.symbolEffect(rotate(dir, scope), options: options, isActive: style.isActive)
		case .breathe(let bStyle, let scope):
			content.symbolEffect(breathe(bStyle, scope), options: options, isActive: style.isActive)
		
		// ---- Transition ------------------------------------------------------------------------------
		case .appear(let dir, let scope):
			content.transition(.symbolEffect(appear(dir, scope), options: oneShotOptions))
		case .disappear(let dir, let scope):
			content.transition(.symbolEffect(disappear(dir, scope), options: oneShotOptions))
		case .drawOn(let scope):
			content.transition(.symbolEffect(drawOn(scope), options: oneShotOptions))
		case .drawOff(let scope):
			content.transition(.symbolEffect(drawOff(scope), options: oneShotOptions))
			
		// ---- Content transition ----------------------------------------------------------------------
		case .replace(let rStyle, let scope):
			content.contentTransition(.symbolEffect(replace(rStyle, scope), options: oneShotOptions))
		}
	}
	
	// MARK: - Effect Builders
	
	private func bounce(_ dir: SymbolVDirection, _ scope: SymbolScope) -> BounceSymbolEffect {
		let directed: BounceSymbolEffect = (dir == .up) ? .bounce.up : .bounce.down
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
	
	private func pulse(_ scope: SymbolScope) -> PulseSymbolEffect {
		let base: PulseSymbolEffect = .pulse
		return scope == .byLayer ? base.byLayer : base.wholeSymbol
	}
	
	private func variableColor(_ fill: VariableColorFill, _ inactive: InactiveLayers, _ reverses: Bool) -> VariableColorSymbolEffect {
		var e: VariableColorSymbolEffect = .variableColor
		e = (fill == .iterative) ? e.iterative : e.cumulative
		e = (inactive == .dim) ? e.dimInactiveLayers : e.hideInactiveLayers
		e = reverses ? e.reversing : e.nonReversing
		return e
	}
	
	private func scale(_ dir: SymbolVDirection, _ scope: SymbolScope) -> ScaleSymbolEffect {
		let directed: ScaleSymbolEffect = (dir == .up) ? .scale.up : .scale.down
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
	
	private func wiggle(_ dir: SymbolWiggle, _ scope: SymbolScope) -> WiggleSymbolEffect {
		var e: WiggleSymbolEffect = .wiggle
		switch dir {
		case .up:               e = e.up
		case .down:             e = e.down
		case .left:             e = e.left
		case .right:            e = e.right
		case .forward:          e = e.forward
		case .backward:         e = e.backward
		case .clockwise:        e = e.clockwise
		case .counterClockwise: e = e.counterClockwise
		}
		return scope == .byLayer ? e.byLayer : e.wholeSymbol
	}
	
	private func rotate(_ dir: SymbolRotation, _ scope: SymbolScope) -> RotateSymbolEffect {
		let directed: RotateSymbolEffect = (dir == .clockwise) ? .rotate.clockwise : .rotate.counterClockwise
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
	
	private func breathe(_ style: SymbolBreathe, _ scope: SymbolScope) -> BreatheSymbolEffect {
		let styled: BreatheSymbolEffect = (style == .plain) ? .breathe.plain : .breathe.pulse
		return scope == .byLayer ? styled.byLayer : styled.wholeSymbol
	}
	
	private func appear(_ dir: SymbolVDirection, _ scope: SymbolScope) -> AppearSymbolEffect {
		let directed: AppearSymbolEffect = (dir == .up) ? .appear.up : .appear.down
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
	
	private func disappear(_ dir: SymbolVDirection, _ scope: SymbolScope) -> DisappearSymbolEffect {
		let directed: DisappearSymbolEffect = (dir == .up) ? .disappear.up : .disappear.down
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
	
	private func drawOn(_ scope: SymbolScope) -> DrawOnSymbolEffect {
		let base: DrawOnSymbolEffect = .drawOn
		return scope == .byLayer ? base.byLayer : base.wholeSymbol
	}
	
	private func drawOff(_ scope: SymbolScope) -> DrawOffSymbolEffect {
		let base: DrawOffSymbolEffect = .drawOff
		return scope == .byLayer ? base.byLayer : base.wholeSymbol
	}
	
	private func replace(_ style: SymbolReplace, _ scope: SymbolScope) -> ReplaceSymbolEffect {
		let directed: ReplaceSymbolEffect
		switch style {
		case .downUp: directed = .replace.downUp
		case .upUp:   directed = .replace.upUp
		case .offUp:  directed = .replace.offUp
		}
		return scope == .byLayer ? directed.byLayer : directed.wholeSymbol
	}
}
