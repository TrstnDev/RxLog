//
//  GradientPlayground.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/09.
//

import SwiftUI

struct GradientPlayground: View {
	private var startColor: Color
	private var endColor: Color
	
	private var gradientPreview: LinearGradient {
		LinearGradient(
			colors: [startColor, endColor],
			startPoint: .top,
			endPoint: .bottom
		)
	}
	
	private var ink: Color {
		endColor.mix(with: .black, by: 0.45)
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 18) {
				/* Content goes here */
			}
			.padding(.horizontal, 16)
			.padding(.top, 8)
			.padding(.bottom, 32)
		}
		.background { gradientPreview.ignoresSafeArea() }
		.toolbar(.hidden, for: .navigationBar)
	}
	
	
	// MARK: - Header
	
	private var header: some View {
		HStack {
			circleButton("chevron.backward") { }
			Spacer()
			circleButton("ellipsis") { }
		}
		.overlay {
			VStack(spacing: 1) {
				Text("Patient X")
					.font(.system(size: 18, weight: .bold))
				Text("Added 2026/07/09, 22:22")
					.font(.system(size: 13, weight: .medium))
					.opacity(0.6)
			}
			.lineLimit(1)
			.minimumScaleFactor(0.7)
			.padding(.horizontal, 64)
		}
		.foregroundStyle(ink)
		.padding(.vertical, 8)
	}
	
	private func circleButton(_ systemName: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Image(systemName: systemName)
				.font(.system(size: 18, weight: .semibold))
				.foregroundStyle(ink)
				.frame(width: 37, height: 37)
		}
		.buttonStyle(.glass)
		.controlSize(.small)
		.buttonBorderShape(.circle)
	}

	
}
