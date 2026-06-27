//
//  SampleData.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

@MainActor
enum SampleData {
	static let previewContainer: ModelContainer = {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let container = try! ModelContainer(for: Note.self, configurations: config)
		for note in sampleNotes {
			container.mainContext.insert(note)
		}
		return container
	}()

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
				title: "Signs of  ruptured Ectopic Pregnancy",
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
			)
		]
	}

	private static func daysAgo(_ days: Int) -> Date {
		Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
	}
}
