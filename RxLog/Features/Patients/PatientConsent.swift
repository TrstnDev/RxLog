//
//  PatientConsent.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/22.
//

/// Versioned record of user's acceptance of the patient-data legal declaration
///
/// Increment `currentVersion` whenever the declaration wording changes; users will be re-prompted
nonisolated enum PatientConsent {
	static let currentVersion = 1
	static let acceptedVersionKey = "patientConsentAcceptedVersion"
	static let acceptedDateKey = "patientConsentAcceptedDate"
}
