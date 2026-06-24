//
//  SampleData.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

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
            )
        ]
    }
    
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
