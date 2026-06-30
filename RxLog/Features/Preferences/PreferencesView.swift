//
//  PreferencesView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/30.
//

import SwiftUI

/// Placeholder for the app preferences feature
struct PreferencesView: View {
	var body: some View {
		NavigationStack {
			ContentUnavailableView(
				"Preferences Coming Soon",
				systemImage: "slider.vertical.3",
				description: Text("App settings will live here.")
			)
			.navigationTitle("Preferences")
		}
	}
}

#Preview {
	PreferencesView()
}
