//
//  PatientsView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

/// Patients tab entry point
///
/// Gates the feature behind the one-time regulatory declaration, then shows the patient list
struct PatientsView: View {
	@AppStorage(PatientConsent.acceptedVersionKey) private var acceptedVersion = 0
	@AppStorage(PatientConsent.acceptedDateKey) private var acceptedDateISO = ""
	
	/// Whether the user has accepted the declaration version currently in force
	private var hasAcceptedCurrentTerms: Bool {
		acceptedVersion >= PatientConsent.currentVersion
	}
	
	var body: some View {
		ZStack {
			if hasAcceptedCurrentTerms {
				PatientsHome()
					.transition(.opacity)
			} else {
				PatientGateView(onAccept: recordAcceptance)
					.transition(.opacity)
			}
		}
	}
	
	/// Persists acceptance of the current declaration, then reveals the feature
	private func recordAcceptance() {
		acceptedDateISO = ISO8601DateFormatter().string(from: .now)
		withAnimation(.bouncy(duration: 0.5)) {
			acceptedVersion = PatientConsent.currentVersion
		}
	}
}

// MARK: - Home

/// The patient overview: a two-column grid of profile cards
///
/// Expired profiles are swept on appear (data minimisation), so the grid only shows profiles still inside their retention window
private struct PatientsHome: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Patient.createdAt, order: .reverse) private var patients: [Patient]
	
	@State private var isSelecting = false
	@State private var selection = Set<Patient.ID>()
	@State private var sortOption: SortOption = .recentlyAdded
	@State private var showingCreation = false
	@State private var viewingPatient: Patient?
	
	private let columns = [
		GridItem(.flexible(), spacing: 16),
		GridItem(.flexible(), spacing: 16)
	]
	
	/// The grid's ordering options
	private enum SortOption: String, CaseIterable, Identifiable {
		case recentlyAdded = "Recently Added"
		case expiringSoon = "Expiring Soon"
		case name = "Name"
		var id: String { rawValue }
	}
	
	/// Profiles ordered by the current sort choice
	private var sortedPatients: [Patient] {
		switch sortOption {
		case .recentlyAdded: patients
		case .expiringSoon: patients.sorted { $0.expiresAt < $1.expiresAt }
		case .name:
			patients
				.map { (name: $0.displayName, patient: $0) }
				.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
				.map { $0.patient }
		}
	}
	
	var body: some View {
		NavigationStack {
			content
				.navigationTitle("Patients")
				.toolbar { toolbarContent }
				.navigationDestination(item: $viewingPatient) { patient in
					PatientDetailView(patient: patient)
				}
		}
		.fullScreenCover(isPresented: $showingCreation) {
			PatientCreationView()
		}
		.onAppear(perform: sweepExpired)
	}
	
	// MARK: - Content
	
	@ViewBuilder private var content: some View {
		if patients.isEmpty {
			ContentUnavailableView(
				"No Patients Yet",
				systemImage: "person.3.fill",
				description: Text("Tap the add button to create a patient profile.")
			)
		} else {
			ScrollView {
				LazyVGrid(columns: columns, spacing: 16) {
					ForEach(sortedPatients) { patient in
						card(for: patient)
					}
				}
				.padding()
			}
		}
	}
	
	private func card(for patient: Patient) -> some View {
		PatientCard(patient: patient)
			.overlay(alignment: .topTrailing) {
				if isSelecting {
					SelectionIndicator(isSelected: selection.contains(patient.id))
						.padding(10)
				}
			}
			.onTapGesture {
				if isSelecting {
					toggleSelection(patient)
				} else {
					viewingPatient = patient
				}
			}
			.contextMenu {
				if !isSelecting {
					Button(role: .destructive) {
						modelContext.delete(patient)
					} label: {
						Label("Delete", systemImage: "trash")
					}
				}
			}
	}
	
	// MARK: - Toolbar
	
	@ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button(isSelecting ? "Done" : "Select") {
				withAnimation(.snappy) {
					if isSelecting { selection.removeAll() }
					isSelecting.toggle()
				}
			}
			.disabled(patients.isEmpty && !isSelecting)
		}
		
		if isSelecting {
			ToolbarItem(placement: .topBarTrailing) {
				Button(role: .destructive, action: deleteSelected) {
					Image(systemName: "trash")
				}
				.disabled(selection.isEmpty)
			}
		} else {
			ToolbarItemGroup(placement: .topBarTrailing) {
				Menu {
					Picker("Sort", selection: $sortOption) {
						ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
					}
				} label: {
					Image(systemName: "line.3.horizontal.decrease")
				}
			}
				
			// Primary creation action
			ToolbarItem(placement: .topBarPinnedTrailing) {
				Button { showingCreation = true } label: {
					Image(systemName: "plus")
				}
				.fontWeight(.semibold)
				.buttonStyle(.glassProminent)
				.accessibilityLabel("Add new Patient")
			}
		}
	}
	
	// MARK: - Actions
	
	/// Permanently deletes profiles past their expiry; runs on tab open, per retention policy
	private func sweepExpired() {
		for patient in patients where patient.isExpired {
			modelContext.delete(patient)
		}
	}
	
	private func toggleSelection(_ patient: Patient) {
		if selection.contains(patient.id) {
			selection.remove(patient.id)
		} else {
			selection.insert(patient.id)
		}
	}
	
	private func deleteSelected() {
		for patient in patients where selection.contains(patient.id) {
			modelContext.delete(patient)
		}
		withAnimation(.snappy) {
			selection.removeAll()
			isSelecting = false
		}
	}
}

#Preview("Coordinator") {
	PatientsView()
}

#Preview("Overview") {
	let container = try! ModelContainer(
		for: Patient.self,
		configurations: ModelConfiguration(isStoredInMemoryOnly: true)
	)
	for patient in Patient.samples {
		container.mainContext.insert(patient)
	}
	return PatientsHome()
		.modelContainer(container)
}
