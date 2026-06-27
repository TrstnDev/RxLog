//
//  NoteComponents.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/27.
//
//  Reusable visual building blocks for presenting notes: preview card, compact list row, waterfall and grid layout containers

import SwiftData
import SwiftUI

// MARK: - Preview Card

/// A note preview: title over a multi-line snippet
struct NotePreviewCard: View {
	let note: Note

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(note.title)
				.font(.headline)
				.fontWeight(.bold)
				.lineLimit(2)
			Text(note.content)
				.font(.subheadline)
				.fontWeight(.medium)
				.foregroundStyle(.secondary)
				.lineLimit(6)
		}
		.noteTypography()
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16)
		.background(Color.notePreviewBackground)
		.overlay(alignment: .topTrailing) {
			if note.isFavourite { favouriteBadge }
		}
		.clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
	}

	/// Favourite star over a gradient scrim
	private var favouriteBadge: some View {
		ZStack(alignment: .topTrailing) {
			LinearGradient(
				colors: [Color.notePreviewBackground.opacity(0), Color.notePreviewBackground],
				startPoint: .leading,
				endPoint: .trailing
			)
			.frame(width: 90, height: 40)
			Image(systemName: "star.fill")
				.font(.subheadline)
				.foregroundStyle(.yellow)
				.padding([.top, .trailing], 14)
		}
	}
}

// MARK: - List Row

/// Compact one-line row for the list layout
struct NoteListRow: View {
	let note: Note

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: "note.text")
				.font(.title3)
				.foregroundStyle(.white)
				.frame(width: 40, height: 40)
				.background(
					Color.accent,
					in: RoundedRectangle(cornerRadius: 10, style: .continuous)
				)
			VStack(alignment: .leading, spacing: 2) {
				Text(note.title)
					.font(.headline)
					.lineLimit(1)
				Text(note.plainText)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(1)
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
	}
}

// MARK: - Waterfall Layout

/// Manual two-column masonry layout
struct NoteWaterfall: View {
	let notes: [Note]
	var columnCount: Int = 2
	var spacing: CGFloat = 12
	var isSelecting: Bool = false
	var selectedIDs: Set<Note.ID> = []
	var onTap: (Note) -> Void = { _ in }

	/// Notes distributed round-robin across columns
	private var columns: [[Note]] {
		var buckets = Array(repeating: [Note](), count: columnCount)
		for (index, note) in notes.enumerated() {
			buckets[index % columnCount].append(note)
		}
		return buckets
	}

	var body: some View {
		HStack(alignment: .top, spacing: spacing) {
			ForEach(Array(columns.enumerated()), id: \.offset) { _, columnNotes in
				LazyVStack(spacing: spacing) {
					ForEach(columnNotes) { note in
						NotePreviewCard(note: note)
							.noteSelectable(
								isSelecting: isSelecting,
								isSelected: selectedIDs.contains(note.id),
								onTap: { onTap(note) }
							)
					}
				}
			}
		}
	}
}

// MARK: - Grid Layout

/// Full-width cards stacked under date-section headers
struct NoteSectionedGrid: View {
	let sections: [NoteSection]
	var isSelecting: Bool = false
	var selectedIDs: Set<Note.ID> = []
	var onTap: (Note) -> Void = { _ in }

	var body: some View {
		LazyVStack(alignment: .leading, spacing: 24) {
			ForEach(sections) { section in
				VStack(alignment: .leading, spacing: 12) {
					if let title = section.title {
						Text(title)
							.font(.subheadline.weight(.semibold))
							.foregroundStyle(.secondary)
							.padding(.leading, 4)
					}
					ForEach(section.notes) { note in
						NotePreviewCard(note: note)
							.noteSelectable(
								isSelecting: isSelecting,
								isSelected: selectedIDs.contains(note.id),
								onTap: { onTap(note) }
							)
					}
				}
			}
		}
		.padding(.horizontal)
		.padding(.top, 8)
	}
}

// MARK: - Previews

#Preview("Card") {
	NotePreviewCard(note: SampleData.sampleNotes[0])
		.frame(width: 220)
		.padding()
}

#Preview("Grid") {
	ScrollView {
		NoteSectionedGrid(sections: NoteSectioner.sections(from: SampleData.sampleNotes))
	}
}
