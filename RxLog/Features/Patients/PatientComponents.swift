//
//  PatientComponents.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/01.
//

import SwiftUI

// MARK: - Avatar

/// A patient's glyph rendered as glossy translucent white, fading top-to-bottom
///
/// Sizes to its container; used on overview card and profile header
struct PatientAvatar: View {
	let glyph: AvatarGlyph
	var size: CGFloat = 100
	
	/// White fill with vertical opacity fade
	private var gloss: LinearGradient {
		LinearGradient(
			colors: [
				.white.opacity(0.8),
				.white.opacity(0.625),
				.white.opacity(0.45),
				.white.opacity(0.275),
				.white.opacity(0.1)
			],
			startPoint: .top,
			endPoint: .bottom
		)
	}
	
	var body: some View {
		Image(systemName: glyph.symbolName)
			.resizable()
			.scaledToFit()
			.frame(width: size, height: size)
			.foregroundStyle(gloss)
			.shadow(color: .black.opacity(0.15), radius: 7, y: 4)
	}
}

// MARK: - Card

/// A patient's gradient tile
///
/// Drives from a `Patient` via the convenience initialiser
struct PatientCard: View {
	let glyph: AvatarGlyph
	let gradient: AppGradient
	var label: String? = nil
	var glyphSize: CGFloat = 100
	
	/// White alias text with a subtle top-to-bottom opacity fade
	private var labelStyle: LinearGradient {
		LinearGradient(colors: [.white, .white.opacity(0.6)], startPoint: .top, endPoint: .bottom)
	}
	
	var body: some View {
		RoundedRectangle(cornerRadius: 30, style: .continuous)
			.fill(
				gradient.linear()
			)
			.overlay {
				VStack(spacing: 6) {
					PatientAvatar(glyph: glyph, size: glyphSize)
						.frame(maxWidth: .infinity, maxHeight: .infinity)
					
					if let label {
						Text(label)
							.font(.system(size: 15, weight: .heavy, design: .serif))
							.italic()
							.tracking(0.86)
							.foregroundStyle(labelStyle)
							.lineLimit(1)
							.minimumScaleFactor(0.7)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
				.padding(18)
			}
			.aspectRatio(1, contentMode: .fit)
			.shadow(color: .black.opacity(0.25), radius: 4, y: 4)
	}
}

extension PatientCard {
	/// Builds a card from a stored patient, showing its alias label
	init(patient: Patient) {
		self.init(glyph: patient.glyph, gradient: patient.gradient, label: patient.displayName)
	}
}

// MARK: - Preview

#Preview {
	ScrollView {
		LazyVGrid(
			columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
			spacing: 16
		) {
			ForEach(Patient.samples) { patient in
				PatientCard(patient: patient)
			}
		}
		.padding()
	}
}
