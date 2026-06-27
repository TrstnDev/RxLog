//
//  CalculatorView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

/// Placeholder for the clinical calculators feature
struct CalculatorView: View {
	var body: some View {
		NavigationStack {
			ContentUnavailableView(
				"Calculators Coming Soon",
				systemImage: "function",
				description: Text("Clinical calculators will live here.")
			)
			.navigationTitle("Calculator")
		}
	}
}

#Preview {
	CalculatorView()
}
