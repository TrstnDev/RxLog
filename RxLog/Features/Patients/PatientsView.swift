//
//  PatientsView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

/// Placeholder for the patient records feature
struct PatientsView: View {
	var body: some View {
		NavigationStack {
			ContentUnavailableView(
				"No Patients Yet",
				systemImage: "person.2.fill",
				description: Text("Patient records will appear here.")
			)
			.navigationTitle("Patients")
		}
	}
}

#Preview {
	PatientsView()
}
