//
//  OnboardingView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

// MARK: - Page Model

/// Content for a single onboarding pane
struct OnboardingPage: Identifiable {
	let id = UUID()
	let symbol: String
	let title: String
	let description: String
}

// MARK: - Onboarding Flow

/// Paged onboarding with a scroll-driven indicator and a CTA that reveals the last pane
struct OnboardingView: View {
	var onFinished: () -> Void

	/// Scroll position in pages (fractional while scrolling)
	@State private var pageProgress: CGFloat = 0

	private let pages: [OnboardingPage] = [
		OnboardingPage(
			symbol: "heart.text.clipboard.fill",
			title: "Histories at hand",
			description: "Keep patient histories and running notes organised and instantly searchable when it matters."
		),
		OnboardingPage(
			symbol: "blood.pressure.cuff.badge.gauge.with.needle.fill",
			title: "Log in seconds",
			description: "Capture notes, observations, and handovers fast - built for the pace of a busy public ward."
		),
		OnboardingPage(
			symbol: "lock.shield.fill",
			title: "Private by Design",
			description: "Your entries stay on your device. Clinical detail deserves clinical-grade privacy."
		)
	]

	/// Proximity of page `i` to the current position (0...1); Currently unused
	private func centeredness(_ i: Int) -> CGFloat {
		max(0, 1 - abs(pageProgress - CGFloat(i)))
	}

	/// Reveal progress (0...1) of the final-pane CTA
	private var ctaProgress: CGFloat {
		guard pages.count >= 2 else { return 0 }
		return min(max(pageProgress - CGFloat(pages.count - 2), 0), 1)
	}

	var body: some View {
		VStack(spacing: 0) {
			// Skip button
			HStack {
				Spacer()
				Button { onFinished() } label: {
					HStack(spacing: 0) {
						Text("Skip")
							.font(.subheadline)
							.fontWeight(.semibold)
							.padding(5)

						Image(systemName: "chevron.forward")
							.fontWeight(.semibold)
					}
				}
				.foregroundStyle(.secondary)
				.buttonStyle(.glass)
				.padding(.trailing, 30)
				.padding(.top, 8)
			}

			// Swipeable panes
			ScrollView(.horizontal) {
				HStack(spacing: 0) {
					ForEach(pages) { page in
						PaneView(page: page)
							.containerRelativeFrame(.horizontal)
					}
				}
			}
			.scrollTargetBehavior(.paging)
			.scrollIndicators(.hidden)
			.onScrollGeometryChange(for: CGFloat.self) { geo in
				let totalWidth = geo.contentSize.width
				guard totalWidth > 0 else { return 0 }
				return geo.contentOffset.x / (totalWidth / CGFloat(pages.count))
			} action: { _, newValue in
				pageProgress = newValue
			}

			// Custom page indicator
			HStack(spacing: 8) {
				ForEach(pages.indices, id: \.self) { i in
					let activeness = max(0, 1 - abs(pageProgress - CGFloat(i)))
					Capsule()
						.fill(Color.primary.opacity(0.3 + 0.7 * activeness))
						.frame(width: 8 + 12 * activeness, height: 8)
				}
			}
			.padding(.top, 8)
			.padding(.bottom, 15)

			// Final-pane call to action
			Button { onFinished() } label: {
				Text("Continue to RxLog")
					.font(.headline)
					.padding(.horizontal, 12)
					.padding(.vertical, 4)
			}
			.buttonStyle(.glassProminent)
			.tint(.accent)
			.controlSize(.large)
			.opacity(ctaProgress)
			.scaleEffect(0.85 + 0.15 * ctaProgress)
			.offset(y: (1 - ctaProgress) * 30)
			.allowsHitTesting(ctaProgress > 0.95)
			.frame(height: 80)
		}
	}
}

// MARK: - Pane

/// A single onboarding pane: large symbol over a title and description
private struct PaneView: View {
	let page: OnboardingPage

	var body: some View {
		VStack {
			Spacer(minLength: 0)

			VStack(spacing: 28) {
				Image(systemName: page.symbol)
					.font(.system(size: 150, weight: .semibold))
					//.foregroundStyle(Theme.brandGradient)
					.foregroundStyle(Theme.)
					.frame(height: 180)
					.frame(maxWidth: .infinity)
					.scrollTransition(.animated(.bouncy(duration: 0.4)), axis: .horizontal) { content, phase in
						content
							.opacity(phase.isIdentity ? 1 : 0)
							.scaleEffect(phase.isIdentity ? 1 : 0.5)
					}

				VStack(spacing: 12) {
					Text(page.title)
						.font(.system(size: 30, weight: .heavy, design: .rounded))
						.foregroundStyle(.primary)

					Text(page.description)
						.font(.body)
						.fontWeight(.medium)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
						.fixedSize(horizontal: false, vertical: true)
				}
				.frame(height: 150, alignment: .top)
				.padding(.horizontal, 40)
				.scrollTransition(.interactive, axis: .horizontal) { content, phase in
					content.scaleEffect(phase.isIdentity ? 1 : 0.7)
				}
			}

			Spacer(minLength: 0)
		}
	}
}

#Preview {
	OnboardingView(onFinished: {})
}
