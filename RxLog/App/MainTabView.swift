//
//  MainTabView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// Root tab bar: Patients, Calculator, and Ward Notes
struct MainTabView: View {
	var body: some View {
		TabView {
			Tab("Patients", systemImage: "person.2.fill") {
				PatientsView()
			}
			Tab("Calculator", systemImage: "function") {
				CalculatorView()
			}
			Tab("Ward Notes", systemImage: "note.text") {
				WardNotesView()
			}
		}
		.tabBarMinimizeBehavior(.onScrollDown)
	}
}

#Preview {
	MainTabView()
		.modelContainer(SampleData.previewContainer)
}
