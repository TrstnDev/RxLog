//
//  PagedCarouselChrome.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/09.
//
//  Shared chrome for scroll-driven paged carousels

import SwiftUI

// MARK: - Progress Maths

/// Helpers for scroll-driven paged carousels
enum PagedCarousel {
	/// Reveal progress (0...1) of a final-pane CTA, given fractional page progress
	static func ctaProgress(pageProgress: CGFloat, pageCount: Int) -> CGFloat {
		guard pageCount >= 2 else { return 0 }
		return min(max(pageProgress - CGFloat(pageCount - 2), 0), 1)
	}
}

// MARK: - Page Progress Tracking

extension View {
	/// Publishes the fractional page position of a horizontally paging ScrollView into `progress`
	func pageProgressTracking(pageCount: Int, into progress: Binding<CGFloat>) -> some View {
		onScrollGeometryChange(for: CGFloat.self) { geometry in
			let totalWidth = geometry.contentSize.width
			guard totalWidth > 0 else { return 0 }
			return geometry.contentOffset.x / (totalWidth / CGFloat(pageCount))
		} action: { _, newValue in
			progress.wrappedValue = newValue
		}
	}
}

// MARK: - Page Indicator

/// Scroll-driven capsule page indicator
struct ScrollPageIndicator: View {
	let progress: CGFloat
	let count: Int
	
	var body: some View {
		HStack(spacing: 8) {
			ForEach(0..<count, id: \.self) { index in
				let activeness = max(0, 1 - abs(progress - CGFloat(index)))
				Capsule()
					.fill(Color.primary.opacity(0.3 + 0.7 * activeness))
					.frame(width: 8 + 12 * activeness, height: 8)
			}
		}
	}
}

// MARK: - CTA Reveal

extension View {
	/// Fades, scales, and lifts a call-to-action in as `progress` approaches 1; interactive from 0.95
	func ctaReveal(_ progress: CGFloat) -> some View {
		self
			.opacity(progress)
			.scaleEffect(0.85 + 0.15 * progress)
			.offset(y: (1 - progress) * 30)
			.allowsHitTesting(progress > 0.95)
	}
}
