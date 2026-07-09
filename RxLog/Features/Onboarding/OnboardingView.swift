//
//  OnboardingView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

// MARK: - Onboarding Symbol Baseline

extension SymbolStyle {
	/// Shared style for draw-on panes (1,2,4,5)
	static let onboardingGlyph = SymbolStyle()
		.hierarchical(Color.accent)
		.gradient(false)
		.font(.system(size: 150, weight: .semibold))
}

// MARK: - Page Model

/// Content for a single onboarding pane
struct OnboardingPage: Identifiable {
	let id = UUID()
	let symbol: String
	let title: String
	let description: String
	var style: SymbolStyle
}

// MARK: - Onboarding Flow

/// Paged onboarding with a scroll-driven indicator and a CTA that reveals the last pane
struct OnboardingView: View {
	var onFinished: () -> Void

	/// Scroll position in pages (fractional while scrolling)
	@State private var pageProgress: CGFloat = 0
	
	@State private var hasAppeared = false

	private static let pages: [OnboardingPage] = [
		OnboardingPage(
			symbol: "heart.text.square.fill",
			title: "Histories at hand",
			description: "Keep patient histories and running notes organised and instantly searchable when it matters.",
			style: .onboardingGlyph
		),
		OnboardingPage(
			symbol: "pencil.and.scribble",
			title: "Log in seconds",
			description: "Capture notes, observations, and handovers fast - built for the pace of a busy public ward.",
			style: .onboardingGlyph
		),
		OnboardingPage(
			symbol: "shareplay",
			title: "Recognise at a glance",
			description: "Every patient carries a colour and a symbol - so you know them on sight, and never by a real name.",
			style: .onboardingGlyph
		),
		OnboardingPage(
			symbol: "radicand.squareroot",
			title: "Calculate with confidence",
			description: "Drug doses, clinical scores, and common formulas - worked out at the bedside, without a scrap of paper.",
			style: .onboardingGlyph
		),
		OnboardingPage(
			symbol: "lock.heart",
			title: "Private by Design",
			description: "Your entries stay on your device. Clinical detail deserves clinical-grade privacy.",
			style: .onboardingGlyph
		)
	]

	/// Reveal progress (0...1) of the final-pane Continue button
	private var ctaProgress: CGFloat {
		PagedCarousel.ctaProgress(pageProgress: pageProgress, pageCount: Self.pages.count)
	}
	
	private func isCurrent(_ index: Int) -> Bool {
		hasAppeared && abs(pageProgress - CGFloat(index)) < 0.5
	}
	
	var body: some View {
		VStack(spacing: 0) {
			skipButton
			pager
			indicator
			continueButton
		}
		.task {
			try? await Task.sleep(for: .milliseconds(150))
			hasAppeared = true
		}
	}
	
	// MARK: - Pane Components
	
	private var skipButton: some View {
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
	}
	
	private var pager: some View {
		ScrollView(.horizontal) {
			HStack(spacing: 0) {
				ForEach(Array(Self.pages.enumerated()), id: \.element.id) { index, page in
					PaneView(page: page, isCurrent: isCurrent(index))
						.containerRelativeFrame(.horizontal)
				}
			}
		}
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.hidden)
		.pageProgressTracking(pageCount: Self.pages.count, into: $pageProgress)
	}
	
	private var indicator: some View {
		ScrollPageIndicator(progress: pageProgress, count: Self.pages.count)
			.padding(.top, 8)
			.padding(.bottom, 15)
	}
	
	private var continueButton: some View {
		Button { onFinished() } label: {
			Text("Continue to RxLog")
				.font(.headline)
				.padding(.horizontal, 12)
				.padding(.vertical, 4)
		}
		.buttonStyle(.glassProminent)
		.tint(.accent)
		.controlSize(.large)
		.ctaReveal(ctaProgress)
		.frame(height: 80)
	}
}

// MARK: - Pane

/// A single onboarding pane: large symbol over a title and description
private struct PaneView: View {
	let page: OnboardingPage
	
	/// Whether this pane's symbol effect should be running
	let isCurrent: Bool
	
	@State private var showGlyph = false

	var body: some View {
		VStack {
			Spacer(minLength: 0)
			VStack(spacing: 28) {
				glyph
					.frame(height: 180)
					.frame(maxWidth: .infinity)
					.accessibilityHidden(true)
					.scrollTransition(.animated(.bouncy(duration: 0.4)), axis: .horizontal) { content, phase in
						content
							.opacity(phase.isIdentity ? 1 : 0)
							.scaleEffect(phase.isIdentity ? 1 : 0.5)
					}
				textBlock
			}
			Spacer(minLength: 0)
		}
		.onChange(of: isCurrent) { _, current in
			if current {
				withAnimation(.easeOut(duration: 1.0)) { showGlyph = true }
			} else {
				showGlyph = false
			}
		}
	}
	
	private var glyph: some View {
		ZStack {
			if showGlyph {
				StyledSymbol(page.symbol, style: page.style)
					.symbolReveal(.drawOn(scope: .individually), speed: 0.5)
			}
		}
	}
	
	private var textBlock: some View {
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
}

#Preview {
	OnboardingView(onFinished: {})
}
