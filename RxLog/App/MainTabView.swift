//
//  MainTabView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// Root tab bar: Patients, Calculator, Ward Notes and universal Search
///
/// Also owns retention sweep, running it at launch and each return to the foreground
struct MainTabView: View {
	@Environment(\.modelContext) private var modelContext
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some View {
		TabView {
			Tab("Patients", systemImage: "person.2.fill") {
				PatientsView()
			}
			Tab("Calculators", systemImage: "function") {
				CalculatorView()
			}
			Tab("Ward Notes", systemImage: "note.text") {
				WardNotesView()
			}
			Tab(role: .search) {
				SearchView()
			}
		}
		.tabBarMinimizeBehavior(.onScrollDown)
		.tabViewSearchActivation(.searchTabSelection)
		.task { sweepExpiredPatients() }
		.onChange(of: scenePhase) { _, phase in
			if phase == .active { sweepExpiredPatients() }
		}
	}
	
	/// Permanently erases patients past their retention window via a store-level batch delete
	private func sweepExpiredPatients() {
		let now = Date.now
		try? modelContext.delete(model: Patient.self, where: #Predicate { $0.expiresAt < now })
		try? modelContext.save()
	}
}

#Preview {
	MainTabView()
		.modelContainer(SampleData.previewContainer)
}
