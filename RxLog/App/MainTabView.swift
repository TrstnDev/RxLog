//
//  MainTabView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// Root tab bar: Patients, Calculator, Ward Notes, and universal Search
///
/// Owns the search field state
struct MainTabView: View {
	@State private var searchText = ""
	@State private var searchTokens: [SearchToken] = []
	
	/// Offers every token not already applied; system only reads this
	private var suggestedTokens: Binding<[SearchToken]> {
		Binding(
			get: { SearchToken.allCases.filter { !searchTokens.contains($0) } },
			set: { _ in }
		)
	}
	
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
