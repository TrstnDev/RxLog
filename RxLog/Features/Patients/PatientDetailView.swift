//
//  PatientDetailView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/08.
//

import SwiftUI
import SwiftData

struct PatientDetailView: View {
	let patient: Patient
	
	@Environment(\.dismiss) private var dismiss
	
	@State private var logsExpanded = true
	
	// Dark, gradient-hued ink for everything sitting over the light upper region
	private var ink: Color { patient.gradient.darkText }
	
	var body: some View {
		ScrollView {
			VStack(spacing: 18) {
				hero
				actionRows
				addExamination
				logsSection
			}
			.padding(.horizontal, 16)
			.padding(.top, 15)
			.padding(.bottom, 32)
		}
		.background { patient.gradient.linear().ignoresSafeArea() }
		.toolbar {
			ToolbarItem(placement: .principal) {
				VStack(spacing: 1) {
					Text(patient.displayName)
						.font(.system(size: 16, weight: .bold))
					Text("Added \(patient.createdAt.formatted(date: .numeric, time: .shortened))")
						.font(.system(size: 12, weight: .medium))
						.opacity(0.6)
				}
				.lineLimit(1)
				.minimumScaleFactor(0.7)
				.foregroundStyle(ink)
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					// TODO: overflow menu - edit details, delete
				} label: {
					Image(systemName: "ellipsis")
						.foregroundStyle(ink.mix(with: .black, by: 0.5))
						.fontWeight(.semibold)
				}
				.accessibilityLabel("Options")
			}
		}
		.toolbarBackground(.hidden, for: .navigationBar)
		.toolbarColorScheme(.light, for: .navigationBar)
		.navigationBarTitleDisplayMode(.inline)
		.environment(\.colorScheme, .dark)
		.toolbarVisibility(.hidden, for: .tabBar)
	}
	
	// MARK: - Hero
	
	private var hero: some View {
		HStack(alignment: .center, spacing: 10) {
			heroGlyph
			demographics
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding(.vertical, 8)
	}
	
	private var heroGlyph: some View {
		Image(systemName: patient.glyph.symbolName)
				.resizable()
				.scaledToFit()
				.frame(width: 140, height: 140)
				.reactiveContrast(for: patient.gradient)
		}
	
	private var demographics: some View {
		let demo = patient.demographics
		return Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 7) {
			demoRow("Age", demo.age?.displayString)
			demoRow("Sex", demo.biologicalSex?.label)
			demoRow("Gender", demo.gender?.label)
			demoRow("Pronouns", demo.pronouns?.label)
			GridRow {
				Text("HIV Status:")
					.fontWeight(.bold)
					.gridColumnAlignment(.leading)
				hivValue(demo.hiv)
			}
		}
		.font(.system(size: 16))
		.reactiveContrast(for: patient.gradient)
		.lineLimit(1)
		.minimumScaleFactor(0.7)
	}
	
	private func demoRow(_ label: String, _ value: String?) -> some View {
		GridRow {
			Text("\(label):")
				.fontWeight(.bold)
				.gridColumnAlignment(.leading)
			if let value {
				Text(value)
			} else {
				notRecorded
			}
		}
	}
	
	@ViewBuilder private func hivValue(_ hiv: HIVStatus?) -> some View {
		if let hiv {
			Image(systemName: hivSymbol(hiv.status))
				.font(.system(size: 18, weight: .semibold))
		} else {
			notRecorded
		}
	}
	
	private var notRecorded: some View {
		Image(systemName: "questionmark.message")
			.font(.system(size: 17, weight: .semibold))
	}
	
	private func hivSymbol(_ status: HIVStatus.Status) -> String {
		switch status {
		case .positive: "plus.circle.fill"
		case .negative: "minus.circle.fill"
		case .unknown: "questionmark.circle.fill"
		}
	}
	
	// MARK: - Action Rows
	
	private var actionRows: some View {
		VStack(spacing: 12) {
			HStack(spacing: 12) {
				actionButton(historyTitle, systemImage: "heart.text.clipboard") { /* TODO: history editor */ }
				actionButton("Log Check-Up", systemImage: "thermometer.variable.and.figure") { /* TODO: check-up entry */ }
			}
			HStack(spacing: 12) {
				actionButton("Log Vitals", systemImage: "lungs") { /* TODO: vitals entry */ }
				actionButton("Log Procedure", systemImage: "ivfluid.bag") { /* TODO: procedure entry */ }
			}
		}
		.padding(.top, 5)
	}
	
	private var hasHistory: Bool { false }
	private var historyTitle: String { hasHistory ? "Edit History" : "Add History" }
	
	private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack(spacing: 8) {
				Image(systemName: systemImage)
					.font(.system(size: 20, weight: .semibold))
					.frame(width: 26)
				Text(title)
					.font(.system(size: 15, weight: .semibold))
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.frame(maxWidth: .infinity)
			}
			.reactiveContrast(for: patient.gradient)
			.padding(.leading, 12)
			.padding(.trailing, 8)
			.frame(maxWidth: .infinity)
			.frame(height: 55)
		}
		.buttonStyle(.glass)
		.controlSize(.small)
	}
	
	// MARK: - Add examination
	
	private var addExamination: some View {
		Button { /* TODO: examination-type menu (General ± systems / system-only) */ } label: {
			HStack(spacing: 10) {
				Image(systemName: "stethoscope")
					.font(.system(size: 19, weight: .semibold))
				Text("Add Examination")
					.font(.system(size: 15, weight: .semibold))
				Spacer(minLength: 0)
				HStack(spacing: 6) {
					Text("System").font(.system(size: 14, weight: .semibold))
					Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
				}
				.padding(.horizontal, 14)
				.padding(.vertical, 10)
				.glassEffect()
			}
			.reactiveContrast(for: patient.gradient)
			.padding(.leading, 12)
			.padding(.trailing, 8)
			.frame(height: 55)
		}
		.buttonStyle(.glass)
		.controlSize(.small)
	}
	
	// MARK: - Logs
	
	private var logsSection: some View {
		DisclosureGroup(isExpanded: $logsExpanded) {
			Text("No records logged yet.")
				.font(.system(size: 16))
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.top, 10)
		} label: {
			Text("Logs")
				.font(.system(size: 18, weight: .bold))
		}
		.reactiveContrast(for: patient.gradient)
		.padding(.top, 16)
	}
}

#Preview {
	NavigationStack {
		PatientDetailView(
			patient: Patient(
				alias: .character("A", script: .latin),
				glyph: .seal,
				gradient: .sunburn,
				demographics: PatientDemographics(
					age: PatientAge(value: 27, unit: .years),
					biologicalSex: .male,
					gender: .cisgenderMale,
					pronouns: nil,
					hiv: HIVStatus(status: .negative)
				)
			)
		)
	}
	.modelContainer(for: Patient.self, inMemory: true)
}
