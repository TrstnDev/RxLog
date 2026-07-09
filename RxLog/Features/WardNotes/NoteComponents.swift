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

// MARK: - Search

/// Glass-styled search field with an inline clear button
struct SearchBar: View {
	@Binding var text: String
	var prompt: String = "Search notes"
	
	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.secondary)
			
			TextField(prompt, text: $text)
				.autocorrectionDisabled()
				.textInputAutocapitalization(.never)
			
			if !text.isEmpty {
				Button {
					text = ""
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Clear search")
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.glassEffect()
	}
}

// MARK: - Selection

// MARK: Selection Indicator

/// Circular checkbox shown on a note in Select mode
struct SelectionIndicator: View {
	let isSelected: Bool
	
	var body: some View {
		ZStack {
			Circle()
				.fill(isSelected ? Color.accentColor : Color(.systemBackground))
				.overlay {
					Circle().strokeBorder(
						isSelected ? .clear : Color.gray.opacity(0.5),
						lineWidth: 1.5
					)
				}
			if isSelected {
				Image(systemName: "checkmark")
					.font(.system(size: 13, weight: .bold))
					.foregroundStyle(.white)
			}
		}
		.frame(width: 24, height: 24)
	}
}

// MARK: Selectable Modifier

/// Adds select-mode behaviour to a card: indicator, highlight border, and tap bounce
struct NoteSelectable: ViewModifier {
	let isSelecting: Bool
	let isSelected: Bool
	var cornerRadius: CGFloat = 25
	let onTap: () -> Void
	
		/// Retriggers the bounce animation on each tap
	@State private var bounceTrigger = 0
	
	func body(content: Content) -> some View {
		content
			.overlay(alignment: .topLeading) {
				if isSelecting {
					SelectionIndicator(isSelected: isSelected)
						.padding(10)
						.transition(.scale.combined(with: .opacity))
				}
			}
			.overlay {
				if isSelecting && isSelected {
					RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
						.strokeBorder(Color.accentColor, lineWidth: 3)
				}
			}
			.contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
			.onTapGesture {
				if isSelecting { bounceTrigger += 1 }
				onTap()
			}
			.keyframeAnimator(initialValue: 1.0, trigger: bounceTrigger) { view, scale in
				view.scaleEffect(scale)
			} keyframes: { _ in
				SpringKeyframe(0.91, duration: 0.14, spring: .snappy)
				SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
			}
	}
}

// MARK: View + noteSelectable

/// Applies `NoteSelectable` to a card
extension View {
	func noteSelectable(
		isSelecting: Bool,
		isSelected: Bool,
		cornerRadius: CGFloat = 25,
		onTap: @escaping () -> Void
	) -> some View {
		modifier(NoteSelectable(
			isSelecting: isSelecting,
			isSelected: isSelected,
			cornerRadius: cornerRadius,
			onTap: onTap
		))
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
