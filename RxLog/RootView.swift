//
//  RootView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

// RootView is a lightweight coordinator: only decides whether to still show the splash or move on
struct RootView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive {
                ContentView()
                    .transition(.opacity)
            } else {
                SplashView(onFinished: {})
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.2))
            
            withAnimation(.smooth(duration: 0.6)) {
                isActive = true
            }
        }
    }
}
