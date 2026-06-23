//
//  OnboardingView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

// MARK: - Data model for a single pane
struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let description: String
}

// MARK: - The onboarding flow
struct OnboardingView: View {

    var onFinished: () -> Void

    @State private var pageProgress: CGFloat = 0

    // Static content
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

    private var currentPage: Int {
        min(max(Int(pageProgress.rounded()), 0), pages.count - 1)
    }
    
    private var ctaProgress: CGFloat {
        guard pages.count >= 2 else { return 0 }
        let raw = pageProgress - CGFloat(pages.count - 2)
        return min(max(raw, 0), 1)
    }

    var body: some View {
        VStack(spacing: 0) {

            // ----- Skip button -----
            HStack {
                Spacer()
                Button() { onFinished() } label: {
                    HStack(spacing: 0) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(5)

                        Image(systemName: "chevron.forward")
                            .fontWeight(.semibold)
                    }
                }
                    .foregroundStyle(.black.opacity(0.8))
                    .buttonStyle(.glass)
                    .padding(.trailing, 30)
                    .padding(.top, 8)
            }

            // ----- Swipeable panes -----
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
                let paneWidth = totalWidth / CGFloat(pages.count)
                return geo.contentOffset.x / paneWidth
            } action: { _, newValue in
                pageProgress = newValue
            }

            // ----- Custom page indicator -----
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? .black : .black.opacity(0.3))
                        .frame(width: i == currentPage ? 20 : 8, height: 8)
                }
            }
            .animation(.bouncy, value: currentPage)
            .padding(.top, 8)
            .padding(.bottom, 15)

            // ----- Glass CTA, only on the final pane -----
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

// MARK: - Single pane's visual
private struct PaneView: View {
    let page: OnboardingPage
    
    var body: some View{
        VStack {
            Spacer(minLength: 0)
            
            VStack(spacing: 28) {
                Image(systemName: page.symbol)
                    .font(.system(size: 150, weight: .semibold))
                    .foregroundStyle(brandGradient)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                    
                    Text(page.description)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(height: 150, alignment: .top)
                .padding(.horizontal, 40)
            }
            
            Spacer(minLength: 0)
        }
    }
}

private var brandGradient: LinearGradient {
    LinearGradient(
        colors: [Color.accentColorLight, Color.accentColorDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

#Preview {
    OnboardingView(onFinished: {})
}
