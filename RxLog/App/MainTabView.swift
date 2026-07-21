//
//  MainTabView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// Root tab bar: Patients, Calculator, Ward Notes, and universal Search
struct MainTabView: View {
	
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
	}
}

#Preview {
	MainTabView()
		.modelContainer(SampleData.previewContainer)
}
