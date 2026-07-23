	//
	//  SampleData.swift
	//  RxLog
	//
	//  Created by Tristan Kriel on 2026/06/24.
	//

#if DEBUG

import SwiftData
import SwiftUI

	/// Dev-only fixtures and the shared in-memory preview container.
	///
	/// `previewContainer` registers the full app schema and seeds every sample set,
	/// so any preview can attach it and query any model. The sample arrays are
	/// computed properties, minting fresh instances on each access — a `@Model`
	/// instance is a reference type bound to one container and must never be shared.
@MainActor
enum SampleData {
	
		/// Mirrors the schema registered in `RxLogApp`; keep the two in sync when adding models.
	static let previewContainer: ModelContainer = {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let container = try! ModelContainer(for: Note.self, Patient.self, configurations: config)
		for note in sampleNotes {
			container.mainContext.insert(note)
		}
		for patient in samplePatients {
			container.mainContext.insert(patient)
		}
		return container
	}()
	
		// MARK: - Notes
	
		/// Covers the display-pipeline state space: every date bucket (including the
		/// previous-year month title), all sort orderings, favourites across buckets,
		/// an untitled note, rich formatting, and a long body with a deep search match.
	static var sampleNotes: [Note] {
		[
			Note(
				title: "Bed 12 — Mr. Dlamini, post-op review",
				content: AttributedString("Day 1 post appendectomy. Obs stable, afebrile. Wound clean and dry. For mobilisation today."),
				dateCreated: daysAgo(0), dateModified: daysAgo(0), lastViewed: daysAgo(0),
				isFavourite: true
			),
			Note(
				title: "Ward round — 08:00 handover",
				content: AttributedString("Three new admissions overnight. Bed 4 awaiting bloods. Bed 9 for discharge pending TTOs."),
				dateCreated: daysAgo(0),
				dateModified: daysAgo(0),
				lastViewed: daysAgo(0)
			),
			Note(
				title: "Medication review — Bed 7",
				content: AttributedString("Reduce furosemide to 20mg OD. Monitor U&Es. Hold metformin pending eGFR."),
				dateCreated: daysAgo(1),
				dateModified: daysAgo(1),
				lastViewed: daysAgo(1)
			),
			Note(
				title: "On-call notes",
				content: AttributedString("Bleeped re: Bed 2 chest pain. ECG unremarkable, troponin negative. For repeat in 6h."),
				dateCreated: daysAgo(5),
				dateModified: daysAgo(3),
				lastViewed: daysAgo(2),
				isFavourite: true
			),
			Note(
				title: "Audit — hand hygiene compliance",
				content: AttributedString("Week 3 figures collated. Compliance up to 91%. Feedback to nursing team scheduled."),
				dateCreated: daysAgo(20),
				dateModified: daysAgo(20),
				lastViewed: daysAgo(18)
			),
			Note(
				title: "Teaching — interpreting ABGs",
				content: AttributedString("Notes from the F1 teaching session. A step-by-step approach to acid–base interpretation."),
				dateCreated: daysAgo(60),
				dateModified: daysAgo(55),
				lastViewed: daysAgo(40)
			),
			Note(
				title: "MoCA Exam steps",
				content: AttributedString("Listing the steps of the Montreal Cognitive Assessment: Visuospatial & Executive, Memory, Attention, Language, Abstraction and Orientation. Total points: 30. Normal range is 26 or higher; add one point for anyone with 12 years or less of formal education."),
				dateCreated: daysAgo(9), dateModified: daysAgo(0), lastViewed: daysAgo(0),
				isFavourite: true
			),
			Note(
				title: "Signs of ruptured Ectopic Pregnancy",
				content: AttributedString("Sudden excruciating abdominal/pelvic pain, dizziness, fainting, signs of shock, unique sharp pain radiating to the tip of the shoulder."),
				dateCreated: daysAgo(34), dateModified: daysAgo(13), lastViewed: daysAgo(6),
				isFavourite: true
			),
			Note(
				title: "The 5Ps of Compartment Syndrome",
				content: AttributedString("Pain, Paresthesia, Pallor, Pulselessness, and Paralysis. Do not wait for all 5 signs before intervening - if all 5 are present it is usually already advanced and tissue necrosis is imminent or already present!"),
				dateCreated: daysAgo(47), dateModified: daysAgo(0), lastViewed: daysAgo(1),
				isFavourite: true
			),
			Note(
				title: "Congestive heart failure patient",
				content: AttributedString("Started on lasix and beta-blockers - monitor progress."),
				dateCreated: daysAgo(65), dateModified: daysAgo(0), lastViewed: daysAgo(1),
				isFavourite: true
			),
			// Untitled — exercises the "Untitled Note" fallback and empty-title layouts
			Note(
				title: "",
				content: AttributedString("Chase Bed 4 potassium result before 18:00 — repeat ECG if still below 3.0."),
				dateCreated: daysAgo(0), dateModified: daysAgo(0), lastViewed: daysAgo(0)
			),
			// Rich formatting — proves the AttributedString JSON round-trip and editor rendering
			Note(
				title: "Allergy alert — Bed 3",
				content: allergyAlertBody,
				dateCreated: daysAgo(2), dateModified: daysAgo(2), lastViewed: daysAgo(1),
				isFavourite: true
			),
			// Previous calendar year — exercises the month-plus-year section title branch
			Note(
				title: "Reflection — paediatrics rotation",
				content: AttributedString("End-of-rotation reflection: neonatal resus confidence much improved; want more exposure to paediatric fluid calculations next block."),
				dateCreated: daysAgo(300), dateModified: daysAgo(300), lastViewed: daysAgo(120)
			),
			// Long single-line body; "handover" sits deep in the line for snippet lead-in + ranking tests
			Note(
				title: "Clerking — Bed 15, 68M breathlessness",
				content: AttributedString("Presenting complaint: three days of progressive breathlessness on a background of COPD. On examination widespread wheeze, sats 91% on room air, apyrexial. Impression: infective exacerbation. Plan: salbutamol nebs, oral prednisone, chest physio, repeat gas in one hour. Discussed at evening handover."),
				dateCreated: daysAgo(0), dateModified: daysAgo(0), lastViewed: daysAgo(0)
			)
		]
	}
	
		/// Mirrors the attribute set the note editor writes (SwiftUI font, underline,
		/// strikethrough), so the fixture round-trips through the same encode path.
	private static var allergyAlertBody: AttributedString {
		var body = AttributedString("Documented allergy: ")
		
		var drug = AttributedString("penicillin — anaphylaxis (2019)")
		drug.font = Font.system(.body, design: .monospaced).bold()
		drug.underlineStyle = .single
		body.append(drug)
		
		body.append(AttributedString(". Previous script "))
		
		var superseded = AttributedString("amoxicillin 500mg TDS")
		superseded.strikethroughStyle = .single
		body.append(superseded)
		
		body.append(AttributedString(" replaced with azithromycin 500mg OD."))
		return body
	}
	
		// MARK: - Patients
	
		/// Covers the demographic state space: both alias modes and scripts, all four
		/// age units (including singular forms), every HIV pathway (positive ± ARVs,
		/// negative ± PrEP, unknown, not recorded), partial and empty profiles, pale
		/// and dark gradients, a near-expiry profile, and one already-expired profile.
	static var samplePatients: [Patient] {
		[
			// Fully recorded adult — HIV positive, on ARVs, adherent
			Patient(
				alias: .character("A", script: .latin),
				glyph: .seal,
				gradient: .berry,
				demographics: PatientDemographics(
					age: PatientAge(value: 34, unit: .years),
					biologicalSex: .female,
					gender: .cisgenderFemale,
					pronouns: .sheHer,
					hiv: HIVStatus(
						status: .positive,
						lastTestDate: daysAgo(90),
						arvsPrescribed: true,
						arvRegimen: "TDF/3TC/DTG",
						arvCompliant: true
					)
				)
			),
			// HIV negative, on PrEP, adherent
			Patient(
				alias: .wardBed(ward: 3, bed: 12),
				glyph: .hexagon,
				gradient: .jade,
				demographics: PatientDemographics(
					age: PatientAge(value: 27, unit: .years),
					biologicalSex: .male,
					gender: .cisgenderMale,
					pronouns: .heHim,
					hiv: HIVStatus(
						status: .negative,
						lastTestDate: daysAgo(30),
						onPrEP: true,
						prepRegimen: "TDF/FTC",
						prepCompliant: true
					)
				)
			),
			// Infant — age in months, HIV status not yet resolved
			Patient(
				alias: .character("β", script: .greek),
				glyph: .circle,
				gradient: .bubblegum,
				demographics: PatientDemographics(
					age: PatientAge(value: 8, unit: .months),
					biologicalSex: .female,
					hiv: HIVStatus(status: .unknown)
				)
			),
			// Neonate — singular age unit, intersex, minimal record
			Patient(
				alias: .wardBed(ward: 1, bed: 4),
				glyph: .capsulePortrait,
				gradient: .winter,
				demographics: PatientDemographics(
					age: PatientAge(value: 1, unit: .weeks),
					biologicalSex: .intersex
				)
			),
			// Days-old neonate
			Patient(
				alias: .wardBed(ward: 1, bed: 7),
				glyph: .ovalPortrait,
				gradient: .petal,
				demographics: PatientDemographics(
					age: PatientAge(value: 4, unit: .days),
					biologicalSex: .female
				)
			),
			// Empty profile — every demographic renders "Not recorded"
			Patient(
				alias: .character("ω", script: .greek),
				glyph: .shield,
				gradient: .abyss
			),
			// Transgender man — HIV negative, not on PrEP, tested a year ago
			Patient(
				alias: .character("K", script: .latin),
				glyph: .diamond,
				gradient: .violet,
				demographics: PatientDemographics(
					age: PatientAge(value: 41, unit: .years),
					biologicalSex: .female,
					gender: .transgenderMan,
					pronouns: .heHim,
					hiv: HIVStatus(
						status: .negative,
						lastTestDate: daysAgo(365)
					)
				)
			),
			// Non-binary adult — HIV positive, ARVs prescribed, non-adherent
			Patient(
				alias: .wardBed(ward: 7, bed: 21),
				glyph: .triangle,
				gradient: .sunburn,
				demographics: PatientDemographics(
					age: PatientAge(value: 19, unit: .years),
					biologicalSex: .other,
					gender: .nonBinary,
					pronouns: .theyThem,
					hiv: HIVStatus(
						status: .positive,
						arvsPrescribed: true,
						arvRegimen: "TDF/3TC/DTG",
						arvCompliant: false
					)
				)
			),
			// Elderly — created six days ago, expires tomorrow
			Patient(
				alias: .character("Z", script: .latin),
				glyph: .pentagon,
				gradient: .cacao,
				demographics: PatientDemographics(
					age: PatientAge(value: 78, unit: .years),
					biologicalSex: .male,
					gender: .cisgenderMale,
					pronouns: .heHim
				),
				createdAt: daysAgo(6)
			),
			// Already expired — verifies search exclusion and the retention sweep
			Patient(
				alias: .wardBed(ward: 2, bed: 18),
				glyph: .octagon,
				gradient: .dusk,
				demographics: PatientDemographics(
					age: PatientAge(value: 52, unit: .years),
					biologicalSex: .male
				),
				createdAt: daysAgo(9)
			)
		]
	}
	
		// MARK: - Helpers
	
	private static func daysAgo(_ days: Int) -> Date {
		Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
	}
}

/// Living spec of export output; exercises the modified-date threshold,
/// untitled headings, and stitching against the fixtures
#Preview("Export Output") {
	ScrollView {
		Text(NoteExporter.stitchedMarkdown(for: SampleData.sampleNotes))
			.font(.system(.footnote, design: .monospaced))
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
	}
}

#endif
