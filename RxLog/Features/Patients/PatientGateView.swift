//
//  PatientGateView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/30.
//

import SwiftUI

// MARK: - Consent Record

/// Versioned record of the user's acceptance of the patient-data legal declaration
///
/// Increment `currentVersion` whenever the declaration wording changes; users who accepted older versions are re-prompted on next entry
enum PatientConsent {
	static let currentVersion = 1
	static let acceptedVersionKey = "patientConsentAcceptedVersion"
	static let acceptedDateKey = "patientConsentAcceptedDate"
}

// MARK: - Pane Model

/// Content for a single splash pane
private struct GatePane: Identifiable {
	let id = UUID()
	let icon: String?
	let heading: String?
	let intro: String?
	let footnote: String?
	let bullets: [GateBullet]
}

/// One bullet point
private struct GateBullet: Identifiable {
	let id = UUID()
	let lead: String
	let detail: String
}

// MARK: - Regulatory Gate

/// First-run gate for Patients feature: four compliance panes leading to legal declaration
struct PatientGateView: View {
	/// Invoked when user accepts the legal declaration
	var onAccept: () -> Void
	
	/// Scroll position in panes
	@State private var pageProgress: CGFloat = 0
	@State private var showingDeclaration = false
	
	private let panes: [GatePane] = [
		GatePane(
			icon: nil,
			heading: nil,
			intro: "Welcome to the Patient Loggin module. This feature is designed to assist you in structuring clinical histories, examinations, and complaints efficiently. To ensure absolute compliance with the Protection of Personal Information Act (POPIA) and HPCSA ethical guidelines regarding patient confidentiality, strict data guardrails have been hardcoded into this application.",
			footnote: "Please review our data architecture and compliance protocols before continuing",
			bullets: []
		),
		GatePane(
			icon: "lock.fill",
			heading: "100% Local, Air-Gapped Storage",
			intro: nil,
			footnote: nil,
			bullets: [
				GateBullet(lead: "Zero Cloud Syncing: ", detail: "All patient profiles and clinical logs are stored entirely locally on this specific device."),
				GateBullet(lead: "No Internet Transmission: ", detail: "Data is never uploaded to the cloud, a central server, or any external database."),
				GateBullet(lead: "No Device-to-Device Sharing: ", detail: "Profiles cannot be shared between devices or exported in this version. A future update may introduce secure, fully redacted Markdown exports.")
			]
		),
		GatePane(
			icon: "nosign",
			heading: "Strict De-identification",
			intro: "To prevent the accidental processing of identifiable Personal Information:",
			footnote: nil,
			bullets: [
				GateBullet(lead: "No Real Names: ", detail: "You are strictly prohibited from entering a patient's legal name or surname."),
				GateBullet(lead: "Built-in Naming Conventions: ", detail: "You must exclusively use the app's structured identifiers (Ward/Bed numbers, pseudonyms, or aliases) in conjunction with the profile icon and colour to identify a patient.")
			]
		),
		GatePane(
			icon: "stopwatch.fill",
			heading: "Automatic Data Retention & Expiration",
			intro: nil,
			footnote: nil,
			bullets: [
				GateBullet(lead: "1-Week Lifespan: ", detail: "To comply with data minimisation principles, patient entries automatically expire and are permanently deleted from this device after one week."),
				GateBullet(lead: "Manual Overrides: ", detail: "You must explicitly adjust the expiration setting within a patient's profile if a longer tracking period is clinically required.")
			]
		)
	]
	
	/// Reveal progress (0...1) of final pane declaration button
	private var ctaProgress: CGFloat {
		guard panes.count >= 2 else { return 0 }
		return min(max(pageProgress - CGFloat(panes.count - 2), 0), 1)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			header
			
			// Swipeable panes
			ScrollView(.horizontal) {
				HStack(spacing: 0) {
					ForEach(panes) { pane in
						GatePaneView(pane: pane)
							.containerRelativeFrame(.horizontal)
					}
				}
			}
			.scrollTargetBehavior(.paging)
			.scrollIndicators(.hidden)
			.onScrollGeometryChange(for: CGFloat.self) { geo in
				let totalWidth = geo.contentSize.width
				guard totalWidth > 0 else { return 0 }
				return geo.contentOffset.x / (totalWidth / CGFloat(panes.count))
			} action: { _, newValue in
				pageProgress = newValue
			}
			
			indicator
			
			declarationButton
		}
		.sheet(isPresented: $showingDeclaration) {
			LegalDeclarationSheet(onAgree: {
				showingDeclaration = false;
				onAccept()
			})
		}
	}
	
	// MARK: - Subviews
	
	/// Fixed brand header shown above every pane
	private var header: some View {
		VStack(alignment: .leading, spacing: 16) {
			Image(systemName: "person.crop.rectangle.stack.fill")
				.font(.system(size: 96, weight: .semibold))
				.foregroundStyle(Theme.brandGradient)
			
			VStack(alignment: .leading, spacing: 0) {
				Text("Welcome to")
					.font(.system(size: 32, weight: .bold))
					.foregroundStyle(.primary)
				Text("Patient &\nHistory Logging")
					.font(.system(size: 38, weight: .heavy))
					.foregroundStyle(Color.accent)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal, 30)
		.padding(.top, 20)
	}
	
	/// Scroll-driven page indicator
	private var indicator: some View {
		HStack(spacing: 8) {
			ForEach(panes.indices, id: \.self) { i in
				let activeness = max(0, 1 - abs(pageProgress - CGFloat(i)))
				Capsule()
					.fill(Color.primary.opacity(0.3 + 0.7 * activeness))
					.frame(width: 8 + 12 * activeness, height: 8)
			}
		}
		.padding(.vertical, 16)
	}
	
	/// Final-pane call to action that opens declaration sheet
	private var declarationButton: some View {
		Button { showingDeclaration = true } label: {
			Text("Legal Declaration & Acknowledgement")
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
		.padding(.bottom, 20)
		.frame(height: 80)
	}
}

// MARK: - Pane

/// Renders one compliance pane
private struct GatePaneView: View {
	let pane: GatePane
	
	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			if let icon = pane.icon, let heading = pane.heading {
				HStack(spacing: 10) {
					Image(systemName: icon)
						.font(.title2)
						.foregroundStyle(Color.accent)
					Text(heading)
						.font(.title3)
						.fontWeight(.bold)
				}
			}
			
			if let intro = pane.intro {
				Text(intro)
					.font(.body)
					.foregroundStyle(.primary)
					.fixedSize(horizontal: false, vertical: true)
			}
			
			ForEach(pane.bullets) { bullet in
				HStack(alignment: .top, spacing: 12) {
					Image(systemName: "arrow.right.circle.fill")
						.font(.body)
						.foregroundStyle(.primary)
					(Text(bullet.lead).fontWeight(.semibold) + Text(" " + bullet.detail))
						.font(.body)
						.foregroundStyle(.primary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			
			if let footnote = pane.footnote {
				(Text(footnote + " ").foregroundStyle(.secondary))
			}
		}
	}
}
