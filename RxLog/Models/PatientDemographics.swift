//
//  PatientDemographics.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/01.
//

import Foundation

// MARK: - Demographics Aggregate

/// A patient's optional clinical demographics
///
/// Every field is optional so a profile can be created with only an alias and completed later
nonisolated struct PatientDemographics: Codable, Hashable {
	var age: PatientAge?
	var biologicalSex: BiologicalSex?
	var gender: Gender?
	var pronouns: Pronouns?
	var hiv: HIVStatus?
	
	init(
		age: PatientAge? = nil,
		biologicalSex: BiologicalSex? = nil,
		gender: Gender? = nil,
		pronouns: Pronouns? = nil,
		hiv: HIVStatus? = nil
	) {
		self.age = age
		self.biologicalSex = biologicalSex
		self.gender = gender
		self.pronouns = pronouns
		self.hiv = hiv
	}
}

// MARK: - Age

/// An age as a value and unit, so neonatal and paediatric ages read in months, weeks, or days
nonisolated struct PatientAge: Codable, Hashable {
	var value: Int
	var unit: Unit
	
	nonisolated enum Unit: String, Codable, CaseIterable, Identifiable {
		case years, months, weeks, days
		var id: String { rawValue }
		var label: String { rawValue.capitalized }
	}
	
	var displayString: String {
		let word = value == 1 ? String(unit.rawValue.dropLast()) : unit.rawValue
		return "\(value) \(word)"
	}
}

// MARK: - Biological Sex

/// Natal/biological sex, kept distinct from gender identity
nonisolated enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
	case male, female, intersex, other
	var id: String { rawValue }
	var label: String {
		switch self {
		case .male: "Male (A.M.A.B.)"
		case .female: "Female (A.F.A.B.)"
		case .intersex: "Intersex"
		case .other: "Other"
		}
	}
}

// MARK: - Gender

/// Gender identity
nonisolated enum Gender: String, Codable, CaseIterable, Identifiable {
	case cisgenderMale, cisgenderFemale, transgenderMan, transgenderWoman, nonBinary, genderFluid, agender, other
	var id: String { rawValue }
	var label: String {
		switch self {
		case .cisgenderMale: "Cisgender Male"
		case .cisgenderFemale: "Cisgender Female"
		case .transgenderMan: "Transgender Man"
		case .transgenderWoman: "Transgender Woman"
		case .nonBinary: "Non-Binary"
		case .genderFluid: "Genderfluid"
		case .agender: "Agender"
		case .other: "Other"
		}
	}
}

// MARK: - Pronouns

/// Personal pronouns, a preset subject/object pair
nonisolated enum Pronouns: String, Codable, CaseIterable, Identifiable {
	case heHim, sheHer, theyThem, other
	var id: String { rawValue }
	
	var subject: String {
		switch self {
		case .heHim: "He"
		case .sheHer: "She"
		case .theyThem: "They"
		case .other: ""
		}
	}
	var object: String {
		switch self {
		case .heHim: "Him"
		case .sheHer: "Her"
		case .theyThem: "Them"
		case .other: ""
		}
	}
	var label: String {
		self == .other ? "Other" : "\(subject)/\(object)"
	}
}

// MARK: - HIV Status

/// HIV status and, where relevant, treatment or prophylaxis detail
nonisolated struct HIVStatus: Codable, Hashable {
	var status: Status
	var lastTestDate: Date?
	var arvsPrescribed: Bool
	var compliant: Bool
	var regimen: String
	var onPrEP: Bool
	
	nonisolated enum Status: String, Codable, CaseIterable, Identifiable {
		case positive, negative, unknown
		var id: String { rawValue }
		var label: String {
			switch self {
			case .positive: "Positive"
			case .negative: "Negative"
			case .unknown: "Unknown"
			}
		}
	}
	
	init(
		status: Status = .unknown,
		lastTestDate: Date? = nil,
		arvsPrescribed: Bool = false,
		compliant: Bool = false,
		regimen: String = "",
		onPrEP: Bool = false
	) {
		self.status = status
		self.lastTestDate = lastTestDate
		self.arvsPrescribed = arvsPrescribed
		self.compliant = compliant
		self.regimen = regimen
		self.onPrEP = onPrEP
	}
}
