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
	
	// State of a brand-new, untouched patient creation view
	private static let defaultGlyph: AvatarGlyph = .seal
	private static let defaultGradient: AppGradient = .accent
	private static let defaultAlias: PatientAlias = .character("A", script: .latin)
	
	@State private var glyph: AvatarGlyph = .seal
	@State private var scrolledGlyph: AvatarGlyph? = .seal
	@State private var gradient: AppGradient = .dusk
	@State private var scrolledGradient: AppGradient? = .dusk
	@State private var alias: PatientAlias = .character("A", script: .latin)
	@State private var demographics = PatientDemographics()
	
	// Disclosure sections own their own expansion
	@State private var aliasExpanded = true
	@State private var ageExpanded = false
	@State private var sexGenderExpanded = false
	@State private var hivExpanded = false
	
	// Validation alerts
	@State private var showDiscardConfirmation = false
	@State private var showDuplicateWarning = false
	
	// MARK: - Derived validation states
	
	private var avatarPersonalized: Bool {
		glyph != Self.defaultGlyph || gradient != Self.defaultGradient
	}
	
	private var aliasPersonalized: Bool {
		alias != Self.defaultAlias
	}
	
	private var canSave: Bool {
		avatarPersonalized && aliasPersonalized
	}
	
	private var hasUnsavedChanges: Bool {
		avatarPersonalized || aliasPersonalized || demographics != PatientDemographics()
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 22) {
					VStack(spacing: 8) {
						PatientCard(glyph: glyph, gradient: gradient, glyphSize: 100)
							.frame(width: 180, height: 180)
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
					Button(action: attemptDismiss) {
						Image(systemName: "chevron.backward")
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(action: attemptSave) {
						Image(systemName: "checkmark")
					}
					.buttonStyle(.glassProminent)
					.tint(.accent)
					.disabled(!canSave)
				}
			}
			.alert("Discard this patient?", isPresented: $showDiscardConfirmation) {
				Button("Discard", role: .destructive) { dismiss() }
				Button("Keep Editing", role: .cancel) { }
			} message: {
				Text("This profile hasn't been saved yet. Your progress will be lost.")
			}
			.alert("Duplicate patient", isPresented: $showDuplicateWarning) {
				Button("OK", role: .cancel) { }
			} message: {
				Text("A patient with this same symbol, colour, and alias already exists. Change any one of the three to create a distinct profile.")
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
			
			Spacer()
			
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
							Circle()
								.strokeBorder(.white, lineWidth: 3)
						}
					}
			}
		}
		.padding(.top, 30)
		.padding(.bottom, 20)
		.padding(.horizontal, 4)
		.background {
			NotchedPanel(cornerRadius: 28, pointerWidth: 30, pointerHeight: 13, tipRadius: 5)
				.fill(
					Color(.secondarySystemBackground)
						.shadow(.inner(color: .black.opacity(0.22), radius: 5, y: 2))
				)
		}
		.onChange(of: scrolledGlyph) { _, newValue in
			if let newValue {
				withAnimation(.easeInOut(duration: 0.2)) { glyph = newValue }
			}
		}
		.onChange(of: scrolledGradient) { _, newValue in
			if let newValue {
				withAnimation(.easeInOut(duration: 0.2)) { gradient = newValue }
			}
		}
	}
	
	// MARK: - Sections
	
	private var sections: some View {
		VStack(spacing: 0) {
			disclosure("Alias", summary: alias.displayName, isExpanded: $aliasExpanded) {
				AliasEditor(alias: $alias)
			}
			rowDivider
			disclosure("Age", summary: ageSummary, isExpanded: $ageExpanded, onExpand: seedAgeIfNeeded) {
				ageEditor
			}
			rowDivider
			disclosure("Sex & Gender", summary: sexGenderSummary, isExpanded: $sexGenderExpanded) {
				sexGenderEditor
			}
			rowDivider
			disclosure("HIV Status", summary: hivSummary, isExpanded: $hivExpanded, onExpand: seedHIVIfNeeded) {
				hivEditor
			}
		}
		.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
	}
	
	private var rowDivider: some View { Divider().padding(.leading, 20) }
	
	private func disclosure<Content: View>(
		_ title: String,
		summary: String,
		isExpanded: Binding<Bool>,
		onExpand: @escaping () -> Void = {},
		@ViewBuilder content: @escaping () -> Content
	) -> some View {
		DisclosureGroup(isExpanded: expansionBinding(isExpanded, onExpand: onExpand)) {
			content()
				.padding(.top, 6)
				.padding(.bottom, 16)
		} label: {
			HStack {
				Text(title)
					.foregroundStyle(.primary)
				Spacer(minLength: 8)
				if !isExpanded.wrappedValue {
					Text(summary)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			.padding(.vertical, 14)
			.contentShape(Rectangle())
		}
		.padding(.horizontal, 20)
	}
	
	private func expansionBinding(_ state: Binding<Bool>, onExpand: @escaping () -> Void) -> Binding<Bool> {
		Binding(
			get: { state.wrappedValue },
			set: { expanding in
				if expanding { onExpand() }
				withAnimation(.snappy(duration: 0.3)) { state.wrappedValue = expanding }
			}
		)
	}
	
	private func seedAgeIfNeeded() {
		if demographics.age == nil { demographics.age = PatientAge(value: 30, unit: .years) }
	}
	
	private func seedHIVIfNeeded() {
		if demographics.hiv == nil { demographics.hiv = HIVStatus() }
	}
	
	// MARK: - Collapsed-row summaries
	
	private var ageSummary: String { demographics.age?.displayString ?? "Not specified" }
	private var sexGenderSummary: String { demographics.gender?.label ?? demographics.biologicalSex?.label ?? "Not specified" }
	private var hivSummary: String { demographics.hiv?.status.label ?? "Not recorded" }
	
	// MARK: - Age
	
	private var ageEditor: some View {
		Group {
			if let age = Binding($demographics.age) {
				VStack(spacing: 12) {
					Picker("Unit", selection: age.unit) {
						ForEach(PatientAge.Unit.allCases) { Text($0.label).tag($0) }
					}
					.pickerStyle(.segmented)
					.labelsHidden()
					
					Picker("Age", selection: age.value) {
						ForEach(0...120, id: \.self) { Text("\($0)").tag($0) }
					}
					.pickerStyle(.wheel)
					.labelsHidden()
					.frame(height: 130)
				}
			}
		}
	}
	
	// MARK: - Sex & Gender
	
	private var sexGenderEditor: some View {
		VStack(alignment: .leading, spacing: 18) {
			demographicField("Biological Sex", selection: $demographics.biologicalSex, options: BiologicalSex.allCases) { $0.label }
			demographicField("Gender", selection: $demographics.gender, options: Gender.allCases) { $0.label }
			demographicField("Pronouns", selection: $demographics.pronouns, options: Pronouns.allCases) { $0.label }
		}
	}
	
	private func demographicField<T: Identifiable & Hashable>(
		_ caption: String,
		selection: Binding<T?>,
		options: [T],
		label: @escaping (T) -> String
	) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(caption)
				.font(.subheadline.weight(.semibold))
				.foregroundStyle(.secondary)
			Menu {
				Picker(caption, selection: selection) {
					Text("Not specified").tag(T?.none)
					ForEach(options) { option in
						Text(label(option)).tag(T?.some(option))
					}
				}
			} label: {
				HStack {
					Text(selection.wrappedValue.map(label) ?? "Not specified")
						.foregroundStyle(selection.wrappedValue == nil ? .secondary : .primary)
						.lineLimit(1)
					Spacer()
					Image(systemName: "chevron.up.chevron.down")
						.font(.footnote.weight(.semibold))
						.foregroundStyle(.secondary)
				}
				.padding(.horizontal, 14)
				.padding(.vertical, 11)
				.background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
			}
			.buttonStyle(.plain)   // render the label as a neutral field, not a tinted button
		}
	}
	
	// MARK: - HIV
	
	private var hivEditor: some View {
			// Seeded on expand, so this unwrap succeeds while the section is open.
		Group {
			if let hiv = Binding($demographics.hiv) {
				HIVStatusEditor(hiv: hiv)
			}
		}
	}
	
	// MARK: - Actions
	
	private func attemptDismiss() {
		if hasUnsavedChanges {
			showDiscardConfirmation = true
		} else {
			dismiss()
		}
	}
	
	private func attemptSave() {
		if isDuplicateIdentity() {
			showDuplicateWarning = true
		} else {
			save()
		}
	}
	
	private func isDuplicateIdentity() -> Bool {
		let now = Date.now
		let descriptor = FetchDescriptor<Patient>(predicate: #Predicate { $0.expiresAt > now })
		guard let active = try? modelContext.fetch(descriptor) else { return false }
		return active.contains { $0.glyph == glyph && $0.gradient == gradient && $0.alias == alias }
	}
	
	private func save() {
		let patient = Patient(alias: alias, glyph: glyph, gradient: gradient, demographics: demographics)
		modelContext.insert(patient)
		dismiss()
	}
}

// MARK: - HIV status editor

private struct HIVStatusEditor: View {
	@Binding var hiv: HIVStatus
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Picker("Status", selection: $hiv.status) {
				ForEach(HIVStatus.Status.allCases) { Text($0.label).tag($0) }
			}
			.pickerStyle(.segmented)
			.labelsHidden()
			
				// The visible fields are a pure function of `status`; no imperative show/hide.
			statusFields
				.animation(.snappy(duration: 0.28), value: hiv.status)
			
			lastTestedField
		}
		.padding(.trailing, 4)
	}
	
	@ViewBuilder private var statusFields: some View {
		switch hiv.status {
		case .positive:
			VStack(alignment: .leading, spacing: 16) {
				Toggle("On antiretrovirals (ARVs)", isOn: $hiv.arvsPrescribed)
				if hiv.arvsPrescribed {
					regimenField("ARV regimen (e.g. TDF/3TC/DTG)", text: $hiv.arvRegimen)
					Toggle("Adherent to ARVs", isOn: $hiv.arvCompliant)
				}
			}
				// Keyed to the toggle, not to `hiv` as a whole, so typing the regimen doesn't animate.
			.animation(.snappy(duration: 0.28), value: hiv.arvsPrescribed)
		case .negative:
			VStack(alignment: .leading, spacing: 16) {
				Toggle("On PrEP", isOn: $hiv.onPrEP)
				if hiv.onPrEP {
					regimenField("PrEP regimen (e.g. TDF/FTC)", text: $hiv.prepRegimen)
					Toggle("Adherent to PrEP", isOn: $hiv.prepCompliant)
				}
			}
			.animation(.snappy(duration: 0.28), value: hiv.onPrEP)
		case .unknown:
			EmptyView()
		}
	}
	
	private var lastTestedField: some View {
		VStack(alignment: .leading, spacing: 16) {
			Toggle("Last test date known", isOn: lastTestedKnown)
			if let date = Binding($hiv.lastTestDate) {
					// `in: ...Date.now` forbids future dates; `.date` drops the time component.
				DatePicker("Last tested", selection: date, in: ...Date.now, displayedComponents: .date)
			}
		}
		.animation(.snappy(duration: 0.28), value: hiv.lastTestDate != nil)
	}
	
	private var lastTestedKnown: Binding<Bool> {
		Binding(
			get: { hiv.lastTestDate != nil },
			set: { hiv.lastTestDate = $0 ? Date.now : nil }
		)
	}
	
		// Modern filled text field, replacing the dated bezeled `.roundedBorder` look.
	private func regimenField(_ placeholder: String, text: Binding<String>) -> some View {
		TextField(placeholder, text: text)
			.textFieldStyle(.plain)
			.padding(.horizontal, 14)
			.padding(.vertical, 11)
			.background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
	
	var body: some View {
		GeometryReader { proxy in
			let sideInset = proxy.size.width / 2 - itemSize / 2
			let containerWidth = proxy.size.width
			let falloff = (itemSize + spacing) * 2
			
			ScrollView(.horizontal) {
				HStack(spacing: spacing) {
					ForEach(items, id: \.self) { item in
						content(item, item == selection)
							.frame(width: itemSize, height: itemSize)
							.visualEffect { view, geometry in
								let viewportWidth = geometry.bounds(of: .scrollView)?.width ?? containerWidth
								let centre = viewportWidth / 2
								let itemMidX = geometry.frame(in: .scrollView).midX
								let t = min(abs(itemMidX - centre) / falloff, 1)
								return view
									.scaleEffect(1 - t * 0.45)
									.opacity(1 - t * 0.6)
							}
					}
				}
				.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew, anchor: .center))
			.scrollPosition(id: $selection, anchor: .center)
			.safeAreaPadding(.horizontal, sideInset)
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

// MARK: - Disclosure Section

/// Collapsible section: tappable header with chevron revealing its content
private struct DisclosureSection<Content: View>: View {
	let title: String
	var summary: String? = nil          // optional collapsed-state value; defaulted so existing calls are unaffected
	@Binding var isExpanded: Bool
	@ViewBuilder var content: () -> Content
	
	var body: some View {
		VStack(spacing: 0) {
			Button {
				withAnimation(.snappy) { isExpanded.toggle() }
			} label: {
				HStack(spacing: 8) {
					Text(title)
					Spacer(minLength: 8)
						// Surface the current value inline when collapsed, the way Settings rows do.
					if let summary, !isExpanded {
						Text(summary)
							.foregroundStyle(.tertiary)
							.lineLimit(1)
					}
					Image(systemName: "chevron.right")
						.font(.footnote.weight(.semibold))
						.rotationEffect(.degrees(isExpanded ? 90 : 0))
				}
				.foregroundStyle(.secondary)
				.padding(.horizontal, 20)
				.padding(.vertical, 18)
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			if isExpanded {
				content()
					.padding(.horizontal, 20)
					.padding(.bottom, 18)
			}
		}
	}
}

#Preview {
	PatientCreationView()
		.modelContainer(for: Patient.self, inMemory: true)
}
