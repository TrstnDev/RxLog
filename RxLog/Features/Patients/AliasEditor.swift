//
//  AliasEditor.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/04.
//

import SwiftUI

// MARK: - Alias Pools

/// Curated, de-identified pools the alias editor draws from
enum AliasPools {
	/// Lowercase Greek letters
	static let greek: [String] = [
		"α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ",
		"ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω"
	]
	
	/// Uppercase Latin letters
	static let latin: [String] = (UInt8(ascii: "A")...UInt8(ascii: "Z")).map { String(UnicodeScalar($0)) }
}

// MARK: - Alias Editor

/// Edits a patient's ``PatientAlias`` via three methods
struct AliasEditor: View {
	@Binding var alias: PatientAlias
	
	enum Mode: String, CaseIterable, Identifiable {
		case character = "Character"
		case wardBed = "Ward & Bed No."
		var id: String { rawValue }
	}
	
	@State private var mode: Mode = .character
	@State private var character = "A"
	@State private var script: PatientAlias.Script = .latin
	@State private var ward = 1
	@State private var bed = 1
	
	/// The alias composed from current method + its state; single source of truth
	private var composed: PatientAlias {
		switch mode {
		case .character: .character(character, script: script)
		case .wardBed: .wardBed(ward: ward, bed: bed)
		}
	}
	
	var body: some View {
		VStack(spacing: 18) {
				Picker("Alias type", selection: $mode) {
					ForEach(Mode.allCases) { mode in
						Text(mode.rawValue).tag(mode)
					}
				}
				.pickerStyle(.segmented)

			Text(composed.displayName)
				.font(.title2.weight(.bold))
				.lineLimit(1)
				.minimumScaleFactor(0.7)
			
			controls
				.id(mode)
				.transition(.blurReplace)
				.animation(.smooth(duration: 0.3), value: mode)
		}
		.onChange(of: composed) { _, newValue in
			alias = newValue
		}
		.onChange(of: script) { _, newScript in
			let pool = letters(for: newScript)
			if !pool.contains(character) { character = pool.first ?? "A" }
		}
	}
	
	// MARK: - Method Controls
	
	@ViewBuilder private var controls: some View {
		switch mode {
		case .character: characterControls
		case .wardBed: wardBedControls
		}
	}
	
	private var characterControls: some View {
		HStack(spacing: 30) {
			Menu {
				Picker("Alphabet", selection: $script) {
					Text("Latin").tag(PatientAlias.Script.latin)
					Text("Greek").tag(PatientAlias.Script.greek)
				}
			} label: {
				HStack(spacing: 6) {
					Text(sample(for: script))
						.fontWeight(.bold)
					Text(scriptName(script))
						.foregroundStyle(.primary)
					Image(systemName: "chevron.up.chevron.down")
						.font(.caption2.weight(.semibold))
						.foregroundStyle(.secondary)
				}
			}
			.padding(.leading, 18)
			
			Menu {
				Picker("Character", selection: $character) {
					ForEach(letters(for: script), id: \.self) { Text($0).tag($0) }
				}
			} label: {
				Text(character)
					.font(.headline)
					.foregroundStyle(.primary)
					.frame(minWidth: 10)
			}
			.buttonStyle(.glass)
			.padding(.trailing, 10)
		}
		.padding(.vertical, 8)
		.background(Color(.tertiarySystemFill), in: Capsule(style: .continuous))
	}
	
	private var wardBedControls: some View {
		HStack(spacing: 0) {
			numberWheel("Ward", selection: $ward)
			numberWheel("Bed", selection: $bed)
		}
	}
	
	private func numberWheel(_ title: String, selection: Binding<Int>) -> some View {
		VStack(spacing: 2) {
			Text(title)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(.secondary)
			
			Picker(title, selection: selection) {
				ForEach(0...99, id: \.self) { number in
					Text("\(number)").tag(number)
				}
			}
			.pickerStyle(.wheel)
			.labelsHidden()
			.frame(height: 130)
		}
		.frame(maxWidth: .infinity)
	}
	
	// MARK: - Helpers
	
	private func letters(for script: PatientAlias.Script) -> [String] {
		script == .greek ? AliasPools.greek : AliasPools.latin
	}
	private func sample(for script: PatientAlias.Script) -> String {
		script == .greek ? "β" : "B"
	}
	private func scriptName(_ script: PatientAlias.Script) -> String {
		script == .greek ? "Greek" : "Latin"
	}
}

// MARK: - Mode Selector

/// Custom segmented control
private struct ModeSelector: View {
	@Binding var selection: AliasEditor.Mode
	@Namespace private var namespace
	
	var body: some View {
		HStack(spacing: 4) {
			ForEach(AliasEditor.Mode.allCases) { mode in
				let isSelected = mode == selection
				Text(mode.rawValue)
					.font(.footnote.weight(.semibold))
					.lineLimit(1)
					.minimumScaleFactor(0.75)
					.foregroundStyle(isSelected ? .white : .primary)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 9)
					.background {
						if isSelected {
							Capsule(style: .continuous)
								.fill(.tint)
								.matchedGeometryEffect(id: "selectedSegment", in: namespace)
						}
					}
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.snappy(duration: 0.3)) { selection = mode }
					}
			}
		}
		.padding(4)
		.background(Color(.tertiarySystemFill), in: Capsule(style: .continuous))
	}
}
