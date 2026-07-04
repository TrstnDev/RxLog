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
	
	static let firstNames: [String] = [
		"Jane", "John", "Alex", "Sam", "Jordan", "Taylor", "Casey", "Morgan", "Riley", "Quinn"
	]
	
	static let lastNames: [String] = [
		"Doe", "Roe", "Bloggs", "Smith", "Stone", "Rivers", "Vale", "Frost", "Snow", "Fields"
	]
}

// MARK: - Alias Editor

/// Edits a patient's ``PatientAlias`` via three methods
struct AliasEditor: View {
	@Binding var alias: PatientAlias
	
	enum Mode: String, CaseIterable, Identifiable {
		case character = "Character"
		case wardBed = "Ward & Bed No."
		case pseudonym = "Pseudonym"
		var id: String { rawValue }
	}
	
	@State private var mode: Mode = .character
	@State private var character = "A"
	@State private var script: PatientAlias.Script = .latin
	@State private var ward = 1
	@State private var bed = 1
	@State private var firstName = AliasPools.firstNames[0]
	@State private var lastName = AliasPools.lastNames[0]
	
	/// The alias composed from current method + its state; single source of truth
	private var composed: PatientAlias {
		switch mode {
		case .character: .character(character, script: script)
		case .wardBed: .wardBed(ward: ward, bed: bed)
		case .pseudonym: .pseudonym(first: firstName, last: lastName)
		}
	}
	
	var body: some View {
		VStack(spacing: 18) {
			ModeSelector(selection: $mode)
			
			Text(composed.displayName)
				.font(.title2.weight(.bold))
				.lineLimit(1)
				.minimumScaleFactor(0.7)
			
			controls
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
		case .pseudonym: pseudonymControls
		}
	}
	
	private var characterControls: some View {
		Menu {
			Picker("Alphabet", selection: $script) {
				Text("Greek").tag(PatientAlias.Script.greek)
				Text("Latin").tag(PatientAlias.Script.latin)
			}
			Picker("Character", selection: $character) {
				ForEach(letters(for: script), id: \.self) { Text($0).tag($0) }
			}
		} label: {
			AliasPill(sample: sample(for: script), title: scriptName(script))
		}
	}
	
	private var wardBedControls: some View {
		HStack(spacing: 12) {
			Menu {
				Picker("Ward", selection: $ward) {
					ForEach(1...40, id: \.self) { Text("\($0)").tag($0) }
				}
			} label: {
				AliasPill(systemImage: "building.2.fill", title: "Ward")
			}
			Menu {
				Picker("Bed", selection: $bed) {
					ForEach(1...60, id: \.self) { Text("\($0)").tag($0) }
				}
			} label: {
				AliasPill(systemImage: "bed.double.fill", title: "Bed")
			}
		}
	}
	
	private var pseudonymControls: some View {
		HStack(spacing: 12) {
			Menu {
				Picker("First Name", selection: $firstName) {
					ForEach(AliasPools.firstNames, id: \.self) { Text($0).tag($0) }
				}
			} label: {
				AliasPill(title: "First Name")
			}
			Menu {
				Picker("Last Name", selection: $lastName) {
					ForEach(AliasPools.lastNames, id: \.self) { Text($0).tag($0) }
				}
			} label: {
				AliasPill(title: "Last Name")
			}
		}
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

// MARK: - Alias Pill

/// Tappable pill label used inside the alias menu
private struct AliasPill: View {
	var systemImage: String? = nil
	var sample: String? = nil
	let title: String
	
	var body: some View {
		HStack(spacing: 6) {
			if let systemImage {
				Image(systemName: systemImage).foregroundStyle(.tint)
			}
			if let sample {
				Text(sample).fontWeight(.bold).foregroundStyle(.tint)
			}
			Text(title).foregroundStyle(.primary)
			Image(systemName: "chevron.right")
				.font(.caption2.weight(.semibold))
				.foregroundStyle(.secondary)
		}
		.font(.subheadline)
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(Color(.tertiarySystemFill), in: Capsule(style: .continuous))
	}
}
