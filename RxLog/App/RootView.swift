//
//  RootView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

// RootView is a lightweight coordinator: only decides whether to still show the splash or move on
struct RootView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var splashFinished = false
    
    var body: some View {
        ZStack {
            if !splashFinished {
                SplashView(onFinished: {
                    withAnimation(.bouncy(duration: 0.4)) { splashFinished = true }
                })
                .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView(onFinished: {
                    withAnimation(.bouncy(duration: 0.5)) { hasCompletedOnboarding = true }
                })
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}
