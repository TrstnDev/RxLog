//
//  SplashView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

struct SplashView: View {
    
    var onFinished: () -> Void
    
    private enum Phase {
        case launching
        case visible
        case zooming
    }
    
    @State private var phase: Phase = .launching
    
    private var logoScale: CGFloat {
        switch phase {
        case .launching:
            0.2
        case .visible:
            1.0
        case .zooming:
            10.0
        }
    }
    
    private var logoOpacity: Double {
        switch phase {
        case .launching:
            0
        case .visible:
            1
        case .zooming:
            0
        }
    }
    
    private var washOpacity: Double {
        phase == .zooming ? 1 : 0
    }
    
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
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            
            Color(.systemBackground)
                .ignoresSafeArea()
                .opacity(washOpacity)
                .allowsHitTesting(false)
        }
        .task {
            // 1. ENTRANCE - fade + scale up
            withAnimation(.bouncy(duration: 0.8)) { phase = .visible }
            
            // 2. HOLD
            try? await Task.sleep(for: .seconds(1.0))
            
            // 3. ZOOM + WASH
            withAnimation(.bouncy(duration: 0.7)) { phase = .zooming }
            
            // 4. HANDOFF
            try? await Task.sleep(for: .seconds(0.5))
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
