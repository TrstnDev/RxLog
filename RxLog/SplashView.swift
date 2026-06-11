//
//  SplashView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

struct SplashView: View {
    @State private var appear = false
    
    var body: some View {
        ZStack {
            // ----- 1. Brand background -----
            LinearGradient(
                colors: [
                    Color.accentColorLight,
                    Color.accentColorDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // ----- 2. Glass logo -----
            Image(systemName: "pills.fill")
                .font(.system(size: 200, weight: .regular))
                .foregroundStyle(.thickMaterial)
                .padding(30)
                // ----- 3. Entrance animation -----
                .scaleEffect(appear ? 1.0 : 0.6)
                .opacity(appear ? 1.0 : 0.0)
        }
        .onAppear {
            // Start entrance the moment the splash is shown
            withAnimation(.smooth(duration: 0.7)) {
                appear = true
            }
        }
    }
}

#Preview {
    SplashView()
}
