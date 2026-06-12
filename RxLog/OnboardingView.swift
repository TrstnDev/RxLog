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
    
    @State private var selection = 0
    
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
    
    private var isLastPage: Bool { selection == pages.count - 1 }
    
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
            TabView(selection: $selection) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    PaneView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // ----- Custom page indicator -----
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == selection ? .black : .black.opacity(0.3))
                        .frame(width: i == selection ? 20 : 8, height: 8)
                }
            }
            .animation(.bouncy, value: selection)
            .padding(.top, 8)
            .padding(.bottom, 15)
            
            // ----- Glass CTA, only on the final pane -----
            Group {
                if isLastPage {
                    Button { onFinished() } label: {
                        Text("Continue to RxLog")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accent)
                    .controlSize(.large)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(height: 80)
            .animation(.bouncy(duration: 0.75), value: isLastPage)
        }
    }
}

// MARK: - Single pane's visual
private struct PaneView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: page.symbol)
                .font(.system(size: 150, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.accentColorLight,
                            Color.accentColorDark
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                .padding(40)
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                
                Text(page.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.black.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
