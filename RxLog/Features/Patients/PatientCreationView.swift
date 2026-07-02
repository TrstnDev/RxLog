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
	@State private var scrolledGlyph: AvatarGlyph? = .seal
	@State private var gradient: AppGradient = .dusk
	@State private var scrolledGradient: AppGradient? = .dusk
	
	@State private var alias: PatientAlias = .character("A", script: .latin)
	@State private var demographics = PatientDemographics()
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 22) {
					VStack(spacing: 12) {
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
	
	// MARK: - Avatar Editor
	
	/// Centred glyph carousel over tap-to-select colour strip
	private var avatarEditor: some View {
		VStack(spacing: 6) {
			CarouselPicker(
				items: AvatarGlyph.allCases,
				selection: $scrolledGlyph,
				itemSize: 46,
				spacing: 26
			) { option, _ in
				Image(systemName: option.symbolName)
					.resizable()
					.scaledToFit()
					.foregroundStyle(.primary)
			}
			
			CarouselPicker(
				items: AppGradient.patientPalette,
				selection: $scrolledGradient,
				itemSize: 52,
				spacing: 18
			) { option, isSelected in
				Circle()
					.fill(option.linear())
					.overlay {
						if isSelected {
							Circle().stroke(.white, lineWidth: 3)
						}
					}
			}
		}
		.padding(.top, 30)
		.padding(.bottom, 20)
		.padding(.horizontal, 4)
		.background {
			NotchedPanel(cornerRadius: 28, pointerWidth: 44, pointerHeight: 12, tipRadius: 6)
				.fill(
					Color(.secondarySystemBackground)
						.shadow(.drop(color: .black.opacity(0.12), radius: 8, y: 4))
						.shadow(.inner(color: .black.opacity(0.10), radius: 3, y: 2))
				)
		}
		.onChange(of: scrolledGlyph) { _, newValue in
			if let newValue { glyph = newValue }
		}
		.onChange(of: scrolledGradient) { _, newValue in
			if let newValue { gradient = newValue }
		}
	}
	
	// MARK: - Sections
	
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
	
	// MARK: - Save
	
	private func save() {
		let patient = Patient(alias: alias, glyph: glyph, gradient: gradient, demographics: demographics)
		modelContext.insert(patient)
		dismiss()
	}
}

// MARK: - Carousel Picker

private struct CarouselPicker<Item: Hashable, Content: View>: View {
	let items: [Item]
	@Binding var selection: Item?
	let itemSize: CGFloat
	let spacing: CGFloat
	
	// Draws each item
	@ViewBuilder let content: (_ item: Item, _ isSelected: Bool) -> Content
	
	// Coordinate-space name for the track
	private static var trackSpace: String { "carousel.track" }
	
	var body: some View {
		GeometryReader { proxy in
			let centre = proxy.size.width / 2
			let falloff = (itemSize + spacing) * 2
			
			ScrollView(.horizontal) {
				HStack(spacing: spacing) {
					ForEach(items, id: \.self) { item in
						content(item, item == selection)
							.frame(width: itemSize, height: itemSize)
							.visualEffect { view, geometry in
								let itemCentre = geometry.frame(in: .named(Self.trackSpace)).midX
								let t = min(abs(itemCentre - centre) / falloff, 1)
								return view
									.scaleEffect(1 - t * 0.45)
									.opacity(1 - t * 0.6)
							}
					}
				}
				.scrollTargetLayout()
			}
			.coordinateSpace(.named(Self.trackSpace))
			.scrollTargetBehavior(.viewAligned)
			.scrollPosition(id: $selection, anchor: .center)
			.contentMargins(.horizontal, centre - itemSize / 2, for: .scrollContent)
			.scrollIndicators(.hidden)
		}
		.frame(height: itemSize)
	}
}

// MARK: - Notched Panel

/// Rounded rectangle with an upward, round-tpped pointer notched into its top
private struct NotchedPanel: Shape {
	var cornerRadius: CGFloat = 28
	var pointerWidth: CGFloat = 44
	var pointerHeight: CGFloat = 12
	var tipRadius: CGFloat = 6
	var baseRadius: CGFloat = 5
	
	func path(in rect: CGRect) -> Path {
		let bodyTop = rect.minY + pointerHeight
		let cx = rect.midX
		let r = min(cornerRadius, (rect.height - pointerHeight) / 2, rect.width / 2)
		
		// Vertices, walked clockwise
		let bodyTopLeft  = CGPoint(x: rect.minX, y: bodyTop)
		let baseLeft     = CGPoint(x: cx - pointerWidth / 2, y: bodyTop)
		let tip          = CGPoint(x: cx, y: rect.minY)
		let baseRight    = CGPoint(x: cx + pointerWidth / 2, y: bodyTop)
		let bodyTopRight = CGPoint(x: rect.maxX, y: bodyTop)
		let bottomRight  = CGPoint(x: rect.maxX, y: rect.maxY)
		let bottomLeft   = CGPoint(x: rect.minX, y: rect.maxY)
		
		var path = Path()
		path.move(to: CGPoint(x: rect.minX + r, y: bodyTop))                                 // top edge, past TL
		path.addArc(tangent1End: baseLeft, tangent2End: tip, radius: baseRadius)   			 // up the left flank
		path.addArc(tangent1End: tip, tangent2End: baseRight, radius: tipRadius)             // round the tip
		path.addArc(tangent1End: baseRight, tangent2End: bodyTopRight, radius: baseRadius)   // down the right flank
		path.addArc(tangent1End: bodyTopRight, tangent2End: bottomRight, radius: r)          // TR corner
		path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: r)            // BR corner
		path.addArc(tangent1End: bottomLeft, tangent2End: bodyTopLeft, radius: r)            // BL corner
		path.addArc(tangent1End: bodyTopLeft, tangent2End: baseLeft, radius: r)              // TL corner
		path.closeSubpath()
		return path
	}
}

#Preview {
	PatientCreationView()
		.modelContainer(for: Patient.self, inMemory: true)
}
