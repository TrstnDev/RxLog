//
//  PatientCreationView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/01.
//

import SwiftUI
import SwiftData

/// New Patient flow
struct PatientCreationView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	
	@State private var glyph: AvatarGlyph = .seal
	@State private var centredGlyph: AvatarGlyph? = .seal
	@State private var gradient: AppGradient = .dusk
	@State private var alias: PatientAlias = .character("A", script: .latin)
	@State private var demographics = PatientDemographics()
	
	// Carousel metrics
	private let glyphSize: CGFloat = 46
	private let glyphSpacing: CGFloat = 26
	private let carouselHeight: CGFloat = 92
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 22) {
					VStack(spacing: 8) {
						PatientCard(glyph: glyph, gradient: gradient, glyphSize: 100)
							.frame(width: 180, height: 180)
							.padding(.top, 8)
						
						avatarEditor
					}
					sections
				}
				.padding()
			}
			.navigationTitle("New Patient")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button { dismiss() } label: {
						Image(systemName: "chevron.backward")
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(action: save) {
						Image(systemName: "checkmark")
					}
				}
			}
		}
	}
	
	// MARK: Avatar Editor
	
	/// Centred glyph carousel over tap-to-select colour strip
	private var avatarEditor: some View {
		VStack(spacing: 14) {
			glyphCarousel
			colourStrip
		}
		.padding(.vertical, 14)
		.background {
			RoundedRectangle(cornerRadius: 28, style: .continuous)
				.fill(
					Color(.secondarySystemBackground)
						.shadow(.inner(color: .black.opacity(0.14), radius: 3, y: 3))
				)
		}
		.overlay(alignment: .top) {
			UpwardPointer()
				.fill(Color(.secondarySystemBackground))
				.frame(width: 24, height: 12)
				.offset(y: -10)
		}
	}
	
	/// Horizontal carousel: centred glyph is largest and fully opaque
	private var glyphCarousel: some View {
		GeometryReader { geo in
			let centre = geo.size.width / 2
			let falloff = (glyphSize + glyphSpacing) * 2
			
			ScrollView(.horizontal) {
				HStack(spacing: glyphSpacing) {
					ForEach(AvatarGlyph.allCases, id: \.self) { option in
						Image(systemName: option.symbolName)
							.resizable()
							.scaledToFit()
							.frame(width: glyphSize, height: glyphSize)
							.foregroundStyle(.primary)
							.visualEffect { content, proxy in
								let distance = abs(proxy.frame(in: .named("glyphStrip")).midX - centre)
								let t = min(distance / falloff, 1)
								return content
									.scaleEffect(1 - t * 0.5)
									.opacity(1 - t * 0.6)
							}
					}
				}
				.scrollTargetLayout()
			}
			.coordinateSpace(.named("glyphStrip"))
			.scrollTargetBehavior(.viewAligned)
			.scrollPosition(id: $centredGlyph, anchor: .center)
			.contentMargins(.horizontal, centre - glyphSize / 2, for: .scrollContent)
			.scrollIndicators(.hidden)
		}
		.frame(height: carouselHeight)
		.onChange(of: centredGlyph) { _, new in
			if let new { glyph = new }
		}
	}
	
	/// Tap-to-select colour strip
	private var colourStrip: some View {
		ScrollView(.horizontal) {
			HStack(spacing: 16) {
				ForEach(AppGradient.patientPalette) { option in
					Circle()
						.fill(option.linear())
						.frame(width: 52, height: 52)
						.overlay {
							if option == gradient {
								Circle().stroke(.white, lineWidth: 3)
							}
						}
						.shadow(color: .black.opacity(0.15), radius: 2, y: 1)
						.onTapGesture { withAnimation(.snappy) { gradient = option } }
				}
			}
			.padding(.horizontal, 22)
			.frame(height: 62)
		}
		.scrollIndicators(.hidden)
	}
	
	// MARK: Sections
	
	private var sections: some View {
		VStack(spacing: 0) {
			sectionRow("Alias")
			Divider().padding(.leading, 20)
			sectionRow("Age")
			Divider().padding(.leading, 20)
			sectionRow("Sex & Gender Expression")
			Divider().padding(.leading, 20)
			sectionRow("HIV Status")
		}
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
	}
	
	private func sectionRow(_ title: String) -> some View {
		HStack {
			Text(title)
			Spacer()
			Image(systemName: "chevron.down")
				.font(.footnote.weight(.semibold))
		}
		.foregroundStyle(.secondary)
		.padding(.horizontal, 20)
		.padding(.vertical, 18)
		.contentShape(Rectangle())
	}
	
	// MARK: Save
	
	private func save() {
		let patient = Patient(alias: alias, glyph: glyph, gradient: gradient, demographics: demographics)
		modelContext.insert(patient)
		dismiss()
	}
}

// MARK: - Pointer Shape

/// A small upward-pointing triangle used as the panel's pointer toward the glyph
private struct UpwardPointer: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: rect.midX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
		path.closeSubpath()
		return path
	}
}

#Preview {
	PatientCreationView()
		.modelContainer(for: Patient.self, inMemory: true)
}
