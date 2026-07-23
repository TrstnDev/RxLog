//
//  SearchComponents.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/21.
//
// Row views for universal search results: patient and ward-note hits

import SwiftUI

// MARK: - Patient Row

/// A patient hit: mini gradient title, alias, and date added
struct PatientSearchRow: View {
	let patient: Patient
	
	var body: some View {
		HStack(spacing: 12) {
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.fill(patient.gradient.linear())
				.frame(width: 40, height: 40)
				.overlay {
					PatientAvatar(glyph: patient.glyph, size: 22)
				}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(patient.displayName)
					.font(.headline)
					.lineLimit(1)
				Text("Added \(patient.createdAt.formatted(date: .abbreviated, time: .omitted))")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer(minLength: 0)
		}
		.padding(.vertical, 4)
		.contentShape(Rectangle())
	}
}

// MARK: - Note Row

/// A note hit: icon title, title, and one-line preview with match tinted
struct NoteSearchRow: View {
	let note: Note
	let snippet: AttributedString?
	
	/// Snippet with emphasised runs tinted accent, or note's opening line
	private var subtitle: AttributedString? {
		if let snippet {
			var styled = snippet
			for run in styled.runs where run.inlinePresentationIntent == .stronglyEmphasized {
				styled[run.range].foregroundColor = .accent
			}
			return styled
		}
		
		let opening = note.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
		return opening.isEmpty ? nil : AttributedString(opening)
	}
	
	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "text.pad.header")
				.font(.title3)
				.foregroundStyle(.white)
				.frame(width: 40, height: 40)
				.background(
					Color.accent,
					in: RoundedRectangle(cornerRadius: 10, style: .continuous)
				)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(note.displayTitle)
					.font(.headline)
					.lineLimit(1)
				if let subtitle {
					Text(subtitle)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			.noteTypography()
			
			Spacer(minLength: 0)
			
			if note.isFavourite {
				Image(systemName: "star.fill")
					.font(.caption)
					.foregroundStyle(.yellow)
			}
		}
		.padding(.vertical, 4)
		.contentShape(Rectangle())
	}
}
