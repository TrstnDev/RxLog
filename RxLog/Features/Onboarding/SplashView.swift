//
//  SplashView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftUI

/// Animated launch screen: the brand mark fades in, holds, then zooms out before `onFinished`
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
			Theme.brandGradient
				.ignoresSafeArea()
            
			Image(systemName: "pills.fill")
				.font(.system(size: 200, weight: .regular))
				.foregroundStyle(.thickMaterial)
				.padding(30)
				.scaleEffect(logoScale)
				.opacity(logoOpacity)
            
			// Opaque wash during the zoom
			Color(.systemBackground)
				.ignoresSafeArea()
				.opacity(washOpacity)
				.allowsHitTesting(false)
		}
		.task {
			withAnimation(.bouncy(duration: 0.8)) { phase = .visible }
			try? await Task.sleep(for: .seconds(1.0))
			withAnimation(.bouncy(duration: 0.7)) { phase = .zooming }
			try? await Task.sleep(for: .seconds(0.5))
			onFinished()
		}
	}
}

#Preview {
	SplashView(onFinished: {})
}
