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
			.foregroundStyle(gloss)
			.shadow(color: .black.opacity(0.15), radius: 7, y: 4)
	}
}

// MARK: - Card

/// A patient's overview tile
struct PatientCard: View {
	let patient: Patient
	
	/// White alias text with a subtle top-to-bottom opacity fade
	private var labelStyle: LinearGradient {
		LinearGradient(colors: [.white, .white.opacity(0.6)], startPoint: .top, endPoint: .bottom)
	}
	
	var body: some View {
		RoundedRectangle(cornerRadius: 30, style: .continuous)
			.fill(
				patient.gradient.linear()
			)
			.overlay {
				VStack(alignment: .leading, spacing: 6) {
					PatientAvatar(glyph: patient.glyph)
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.padding(.top, 4)
					
					Text(patient.displayName)
						.font(.system(size: 15, weight: .heavy, design: .serif))
						.italic()
						.tracking(0.86)
						.foregroundStyle(labelStyle)
						.lineLimit(1)
						.minimumScaleFactor(0.7)
						.frame(maxWidth: .infinity, alignment: .center)
				}
				.padding(18)
			}
			.aspectRatio(1, contentMode: .fit)
			.shadow(color: .black.opacity(0.25), radius: 4, y: 4)
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
