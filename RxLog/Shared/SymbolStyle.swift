//
//  SymbolStyle.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/04.
//
//  Reusable SF symbol customiser - applicable to any symbol via `.symbolStyle(_:)` or use `StyledSymbol` for a variable value.

import SwiftUI

// MARK: - SymbolStyle

/// Complete, value-type description of how to render and animate an SF Symbol
///
/// Built via fluent API and handed to `symbolStyle(_:)` or ``StyledSymbol``
struct SymbolStyle {
	
	// MARK: Rendering attributes
	
	/// `.monochrome` / `.hierarchical` / `.palette` / `.multicolor` (`nil` uses symbol's default)
	var renderingMode: SymbolRenderingMode?
	
	/// `.gradient` / `.flat`
	var colorRenderingMode: SymbolColorRenderingMode?
	
	/// 1 - 3 layer colours
	var colors: [AnyShapeStyle]
	
	/// Drives multi-state symbols (`nil` renders full value)
	var variableValue: Double?
	
	/// Point size and weight
	var font: Font?
	
	// MARK: Continuous animation attributes
	
	/// Animation configuration
	var animation: Animation
	
	/// How an indefinite animation repeats
	var repeatMode: RepeatMode
	
	/// Playback speed multiplier (1 = normal)
	var speed: Double
	
	/// Gate for indefinite effects
	var isActive: Bool
	
	/// Creates a blank style - prefer fluent builder to layer attributes on top
	init(
		renderingMode: SymbolRenderingMode? = nil,
		colorRenderingMode: SymbolColorRenderingMode? = nil,
		colors: [AnyShapeStyle] = [],
		variableValue: Double? = nil,
		font: Font? = nil,
		animation: Animation = .none,
		repeatMode: RepeatMode = .continuous,
		speed: Double = 1,
		isActive: Bool = true
	) {
		self.renderingMode = renderingMode
		self.colorRenderingMode = colorRenderingMode
		self.colors = colors
		self.variableValue = variableValue
		self.font = font
		self.animation = animation
		self.repeatMode = repeatMode
		self.speed = speed
		self.isActive = isActive
	}
}

// MARK: - Configuration vocabulary

extension SymbolStyle {
	
	/// Which parts of a symbol an effect animates
	enum Scope {
		case wholeSymbol
		case byLayer
		case individually	// Draw On/Off only
	}
	
	/// Vertical travel for bounce, scale, appear, and disappear
	enum Direction { case up, down }
	
	/// Spin direction for rotate
	enum Spin { case clockwise, counterClockwise }
	
	/// The eight wiggle directions
	enum WiggleDirection { case up, down, left, right, forward, backward, clockwise, counterClockwise }
	
	/// The two breathe rhythms
	enum Breathe { case plain, pulse }
	
	/// How variable colour fills layers
	enum VariableFill { case iterative, cumulative }
	
	/// What happens to inactive layers in variable colour
	enum InactiveLayers { case dim, hide }
	
	/// How a replaced symbol yields to its successor
	enum Replace { case downUp, upUp, offUp }
	
	/// How an indefinite effect repeats
	enum RepeatMode {
		case once
		case continuous
		case periodic(delay: Double)
	}
	
	/// Every SF Symbol effect, each carrying its configuration
	enum Animation {
		case none
		case bounce(Direction = .up, scope: Scope = .byLayer)
		case pulse(scope: Scope = .byLayer)
		case variableColor(fill: VariableFill = .cumulative, inactive: InactiveLayers = .dim, reverses: Bool = false)
		case scale(Direction = .up, scope: Scope = .byLayer)
		case wiggle(WiggleDirection = .left, scope: Scope = .byLayer)
		case rotate(Spin = .clockwise, scope: Scope = .byLayer)
		case breathe(Breathe = .plain, scope: Scope = .wholeSymbol)
		case replace(Replace = .downUp, scope: Scope = .wholeSymbol)
	}
	
	/// A reveal transition effect that plays when a symbol is inserted and belongs on `symbolReveal(_:speed:)`
	enum Reveal {
		case appear(Direction = .up, scope: Scope = .wholeSymbol)
		case disappear(Direction = .down, scope: Scope = .wholeSymbol)
		case drawOn(scope: Scope = .individually)
		case drawOff(scope: Scope = .individually)
	}
}

// MARK: - Fluent Builder
//
// Every method returns a mutated copy

extension SymbolStyle {
	
	// -------- Rendering ---------------------------------------------------------------
	
	/// Sets the rendering mode directly
	func rendering(_ mode: SymbolRenderingMode?) -> Self { with { $0.renderingMode = mode } }
	
	/// Monochrome fill in a single style
	func monochrome(_ style: some ShapeStyle) -> Self {
		with { $0.renderingMode = .monochrome; $0.colors = [AnyShapeStyle(style)] }
	}
	
	/// Hierarchical fill
	func hierarchical(_ base: some ShapeStyle) -> Self {
		with { $0.renderingMode = .hierarchical; $0.colors = [AnyShapeStyle(base)] }
	}
	
	/// Two-colour palette fill
	func palette(_ a: some ShapeStyle, _ b: some ShapeStyle) -> Self {
		with { $0.renderingMode = .palette; $0.colors = [AnyShapeStyle(a), AnyShapeStyle(b)] }
	}
	
	/// Three-colour palette fill
	func palette(_ a: some ShapeStyle, _ b: some ShapeStyle, _ c: some ShapeStyle) -> Self {
		with { $0.renderingMode = .palette; $0.colors = [AnyShapeStyle(a), AnyShapeStyle(b), AnyShapeStyle(c)] }
	}
	
	/// Multicolour fill, using the colours baked into the symbol
	func multicolor() -> Self { with { $0.renderingMode = .multicolor } }
	
	/// Toggles the iOS 26 gradient fill on (default) or off
	func gradient(_ on: Bool = true) -> Self { with { $0.colorRenderingMode = on ? .gradient : .flat } }
	
	/// Sets layer colours without touching the rendering mode
	func colors(_ a: some ShapeStyle) -> Self { with { $0.colors = [AnyShapeStyle(a)] } }
	func colors(_ a: some ShapeStyle, _ b: some ShapeStyle) -> Self {
		with { $0.colors = [AnyShapeStyle(a), AnyShapeStyle(b)] }
	}
	func colors(_ a: some ShapeStyle, _ b: some ShapeStyle, _ c: some ShapeStyle) -> Self {
		with { $0.colors = [AnyShapeStyle(a), AnyShapeStyle(b), AnyShapeStyle(c)] }
	}
	
	// -------- Symbol value + font -----------------------------------------------------
	
	func variableValue(_ value: Double?) -> Self { with { $0.variableValue = value } }
	func font(_ font: Font?) -> Self { with { $0.font = font } }
	
	// -------- Continuous Animation ----------------------------------------------------
	
	func effect(_ animation: Animation) -> Self { with { $0.animation = animation } }
	func repeats(_ mode: RepeatMode) -> Self { with { $0.repeatMode = mode } }
	func speed(_ speed: Double) -> Self { with { $0.speed = speed } }
	func active(_ active: Bool) -> Self { with { $0.isActive = active } }
	
	/// Copy-and-mutate helper backing every builder above
	private func with(_ mutate: (inout Self) -> Void) -> Self {
		var copy = self
		mutate(&copy)
		return copy
	}
}

// MARK: - View Integration

extension View {
	/// Applies a ``SymbolStyle`` to every SF Symbol in this view
	func symbolStyle(_ style: SymbolStyle) -> some View {
		modifier(SymbolStyleModifier(style: style))
	}
}

/// A symbol image with a ``SymbolStyle`` already applied
struct StyledSymbol: View {
	let systemName: String
	var style: SymbolStyle
	
	init(_ systemName: String, style: SymbolStyle = SymbolStyle()) {
		self.systemName = systemName
		self.style = style
	}
	
	var body: some View {
		Image(systemName: systemName, variableValue: style.variableValue)
			.font(style.font)
			.symbolStyle(style)
	}
}

// MARK: - Symbol Reveals

extension View {
	/// `reveal`: which entrance to play
	/// `speed`: playback multiplier (1 = normal speed)
	func symbolReveal(_ reveal: SymbolStyle.Reveal, speed: Double = 1) -> some View {
		transition(reveal.symbolEffectTransition(speed: speed))
	}
}

extension SymbolStyle.Reveal {
	fileprivate func symbolEffectTransition(speed: Double) -> SymbolEffectTransition {
		let options = SymbolEffectOptions.speed(speed)
		switch self {
		case .appear(let dir, let scope):     return .symbolEffect(Self.appear(dir, scope), options: options)
		case .disappear(let dir, let scope):  return .symbolEffect(Self.disappear(dir, scope), options: options)
		case .drawOn(let scope):              return .symbolEffect(Self.drawOn(scope), options: options)
		case .drawOff(let scope):             return .symbolEffect(Self.drawOff(scope), options: options)
		}
	}
	
	private static func appear(_ dir: SymbolStyle.Direction, _ scope: SymbolStyle.Scope) -> AppearSymbolEffect {
		let directed: AppearSymbolEffect = (dir == .up) ? .appear.up : .appear.down
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
	
	private static func disappear(_ dir: SymbolStyle.Direction, _ scope: SymbolStyle.Scope) -> DisappearSymbolEffect {
		let directed: DisappearSymbolEffect = (dir == .up) ? .disappear.up : .disappear.down
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
	
	private static func drawOn(_ scope: SymbolStyle.Scope) -> DrawOnSymbolEffect {
		let base: DrawOnSymbolEffect = .drawOn
		switch scope {
		case .wholeSymbol:  return base.wholeSymbol
		case .byLayer:      return base.byLayer
		case .individually: return base.individually
		}
	}
	
	private static func drawOff(_ scope: SymbolStyle.Scope) -> DrawOffSymbolEffect {
		let base: DrawOffSymbolEffect = .drawOff
		switch scope {
		case .wholeSymbol:  return base.wholeSymbol
		case .byLayer:      return base.byLayer
		case .individually: return base.individually
		}
	}
}

// MARK: - Application

/// Applies the style's attributes in order: rendering -> colour rendering -> colours -> animation
private struct SymbolStyleModifier: ViewModifier {
	let style: SymbolStyle
	
	func body(content: Content) -> some View {
		content
			.symbolRenderingMode(style.renderingMode)
			.symbolColorRenderingMode(style.colorRenderingMode)
			.modifier(SymbolColorsModifier(colors: style.colors))
			.modifier(SymbolAnimationModifier(
				animation: style.animation,
				options: style.effectOptions,
				isActive: style.isActive
			))
	}
}

/// Applies 0-3 foreground styles
private struct SymbolColorsModifier: ViewModifier {
	let colors: [AnyShapeStyle]
	
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

private extension SymbolStyle {
	/// Translates `repeatMode` + `speed` into Apple's `SymbolEffectOptions`
	var effectOptions: SymbolEffectOptions {
		let base: SymbolEffectOptions = switch repeatMode {
		case .once: .nonRepeating
		case .continuous: .repeat(.continuous)
		case .periodic(let delay): .repeat(.periodic(delay: delay))
		}
		return base.speed(speed)
	}
}

/// Chooses the correct effect surface and concrete effect type for an animation
private struct SymbolAnimationModifier: ViewModifier {
	let animation: SymbolStyle.Animation
	let options: SymbolEffectOptions
	let isActive: Bool
	
	@ViewBuilder
	func body(content: Content) -> some View {
		switch animation {
		case .none:
			content
		case .bounce(let dir, let scope):
			content.symbolEffect(bounce(dir, scope), options: options, isActive: isActive)
		case .pulse(let scope):
			content.symbolEffect(pulse(scope), options: options, isActive: isActive)
		case .variableColor(let fill, let inactive, let reverses):
			content.symbolEffect(variableColor(fill, inactive, reverses), options: options, isActive: isActive)
		case .scale(let dir, let scope):
			content.symbolEffect(scale(dir, scope), options: options, isActive: isActive)
		case .wiggle(let dir, let scope):
			content.symbolEffect(wiggle(dir, scope), options: options, isActive: isActive)
		case .rotate(let spin, let scope):
			content.symbolEffect(rotate(spin, scope), options: options, isActive: isActive)
		case .breathe(let style, let scope):
			content.symbolEffect(breathe(style, scope), options: options, isActive: isActive)
		case .replace(let style, let scope):
			content.contentTransition(.symbolEffect(replace(style, scope), options: options))
		}
	}
	
	// MARK: Concrete Effect Builders
	
	private func bounce(_ dir: SymbolStyle.Direction, _ scope: SymbolStyle.Scope) -> BounceSymbolEffect {
		let directed: BounceSymbolEffect = (dir == .up) ? .bounce.up : .bounce.down
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
	
	private func pulse(_ scope: SymbolStyle.Scope) -> PulseSymbolEffect {
		let base: PulseSymbolEffect = .pulse
		return scope == .wholeSymbol ? base.wholeSymbol : base.byLayer
	}
	
	private func variableColor(_ fill: SymbolStyle.VariableFill, _ inactive: SymbolStyle.InactiveLayers, _ reverses: Bool) -> VariableColorSymbolEffect {
		var effect: VariableColorSymbolEffect = .variableColor
		effect = (fill == .iterative) ? effect.iterative : effect.cumulative
		effect = (inactive == .dim) ? effect.dimInactiveLayers : effect.hideInactiveLayers
		effect = reverses ? effect.reversing : effect.nonReversing
		return effect
	}
	
	private func scale(_ dir: SymbolStyle.Direction, _ scope: SymbolStyle.Scope) -> ScaleSymbolEffect {
		let directed: ScaleSymbolEffect = (dir == .up) ? .scale.up : .scale.down
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
	
	private func wiggle(_ dir: SymbolStyle.WiggleDirection, _ scope: SymbolStyle.Scope) -> WiggleSymbolEffect {
		var effect: WiggleSymbolEffect = .wiggle
		switch dir {
		case .up: effect = effect.up
		case .down: effect = effect.down
		case .left: effect = effect.left
		case .right: effect = effect.right
		case .forward: effect = effect.forward
		case .backward: effect = effect.backward
		case .clockwise: effect = effect.clockwise
		case .counterClockwise: effect = effect.counterClockwise
		}
		return scope == .wholeSymbol ? effect.wholeSymbol : effect.byLayer
	}
	
	private func rotate(_ spin: SymbolStyle.Spin, _ scope: SymbolStyle.Scope) -> RotateSymbolEffect {
		let directed: RotateSymbolEffect = (spin == .clockwise) ? .rotate.clockwise : .rotate.counterClockwise
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
	
	private func breathe(_ style: SymbolStyle.Breathe, _ scope: SymbolStyle.Scope) -> BreatheSymbolEffect {
		let styled: BreatheSymbolEffect = (style == .plain) ? .breathe.plain : .breathe.pulse
		return scope == .wholeSymbol ? styled.wholeSymbol : styled.byLayer
	}
	
	private func replace(_ style: SymbolStyle.Replace, _ scope: SymbolStyle.Scope) -> ReplaceSymbolEffect {
		let directed: ReplaceSymbolEffect
		switch style {
		case .downUp: directed = .replace.downUp
		case .upUp: directed = .replace.upUp
		case .offUp: directed = .replace.offUp
		}
		return scope == .wholeSymbol ? directed.wholeSymbol : directed.byLayer
	}
}
