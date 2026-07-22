	//
	//  Patient.swift
	//  RxLog
	//
	//  Created by Tristan Kriel on 2026/07/01.
	//

import SwiftData
import SwiftUI

	// MARK: - Patient

	/// A de-identified patient profile: an alias, an avatar (glyph + gradient), and a retention window
@Model
final class Patient {
	
		/// Stable external identity for features that persist references to this model
		/// (e.g. search recents). Deliberately not marked `.unique`: a uniqueness
		/// constraint would fail lightweight migration, because every pre-existing row
		/// receives the same evaluated default.
	var uuid: UUID = UUID()
	
		/// JSON-encoded `Data`; backing store for values
	private var aliasData: Data
	private var demographicsData: Data?
	
	
	var glyph: AvatarGlyph
	var gradient: AppGradient
	var createdAt: Date
	var expiresAt: Date
	
		/// Typed façade over ``aliasData``
	var alias: PatientAlias {
		get { (try? JSONDecoder().decode(PatientAlias.self, from: aliasData)) ?? .placeholder }
		set { aliasData = Patient.encode(newValue) }
	}
	
		/// Typed façade over ``demographicsData``
	var demographics: PatientDemographics {
		get {
			guard let demographicsData,
				  let value = try? JSONDecoder().decode(PatientDemographics.self, from: demographicsData)
					else { return PatientDemographics() }
			return value
		}
		set { demographicsData = try? JSONEncoder().encode(newValue) }
	}
	
	init(
		alias: PatientAlias,
		glyph: AvatarGlyph,
		gradient: AppGradient,
		demographics: PatientDemographics = PatientDemographics(),
		createdAt: Date = .now,
		expiresAt: Date? = nil
	) {
		self.aliasData = Patient.encode(alias)
		self.demographicsData = try? JSONEncoder().encode(demographics)
		self.glyph = glyph
		self.gradient = gradient
		self.createdAt = createdAt
		self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .day, value: 7, to: createdAt) ?? createdAt
	}
	
		/// The label shown on cards and the profile header
	var displayName: String { alias.displayName }
	
		/// Whether the retention window has elapsed
	var isExpired: Bool { expiresAt < .now }
	
	private static func encode(_ value: PatientAlias) -> Data {
		(try? JSONEncoder().encode(value)) ?? Data()
	}
}

	// MARK: - Alias

	/// A patient's alias, captured by one of three prescribed de-identification methods
nonisolated enum PatientAlias: Codable, Hashable {
		/// Capitalised Latin or lowercase Greek character, e.g., "Patient X" or "Patient β"
	case character(String, script: Script)
	
		/// A ward and bed number, e.g., "Ward 5 · Bed 10"
	case wardBed(ward: Int, bed: Int)
	
	nonisolated enum Script: String, Codable, Hashable, CaseIterable {
		case latin, greek
	}
	
		/// The rendered label for cards and headers
	var displayName: String {
		switch self {
		case .character(let value, _): "Patient \(value)"
		case .wardBed(let ward, let bed): "Ward \(ward) · Bed \(bed)"
		}
	}
	
		/// Fallback used only if stored data fails to decode
	static let placeholder = PatientAlias.character("?", script: .latin)
}

	// MARK: - Avatar Glyph

	/// The SF Symbol shapes offered for a patient avatar
nonisolated enum AvatarGlyph: String, CaseIterable, Identifiable, Codable {
	case circle                 	= "circle.fill"
	case square                 	= "square.fill"
	case app                    	= "app.fill"
	case rectangle              	= "rectangle.fill"
	case rectanglePortrait      	= "rectangle.portrait.fill"
	case capsule                	= "capsule.fill"
	case capsulePortrait        	= "capsule.portrait.fill"
	case oval                   	= "oval.fill"
	case ovalPortrait           	= "oval.portrait.fill"
	case triangle               	= "triangle.fill"
	case diamond                	= "diamond.fill"
	case octagon                	= "octagon.fill"
	case hexagon                	= "hexagon.fill"
	case pentagon               	= "pentagon.fill"
	case seal                   	= "seal.fill"
	case rhombus                	= "rhombus.fill"
	case shield                 	= "shield.fill"
	case buttonHorizontal       	= "button.horizontal.fill"
	case buttonRoundedTop       	= "button.roundedtop.horizontal.fill"
	case buttonRoundedBottom    	= "button.roundedbottom.horizontal.fill"
	case buttonAngledTopLeft    	= "button.angledtop.vertical.left.fill"
	case buttonAngledTopRight   	= "button.angledtop.vertical.right.fill"
	case buttonAngledBottomLeft 	= "button.angledbottom.horizontal.left.fill"
	case buttonAngledBottomRight 	= "button.angledbottom.horizontal.right.fill"
	
	var id: String { rawValue }
	
		/// The SF Symbol name
	var symbolName: String { rawValue }
}

	// MARK: - Sample Data

#if DEBUG
extension Patient {
		/// Preview fixtures covering the demographic state space: both alias modes and
		/// scripts, all four age units (including singular forms), every HIV pathway
		/// (positive ± ARVs, negative ± PrEP, unknown, not recorded), partial and empty
		/// profiles, pale and dark gradients, and a near-expiry profile.
	static var samples: [Patient] {
		let day: TimeInterval = 86_400
		return [
			// Fully recorded adult — HIV positive, on ARVs, adherent
			Patient(
				alias: .character("A", script: .latin),
				glyph: .seal,
				gradient: .berry,
				demographics: PatientDemographics(
					age: PatientAge(value: 34, unit: .years),
					biologicalSex: .female,
					gender: .cisgenderFemale,
					pronouns: .sheHer,
					hiv: HIVStatus(
						status: .positive,
						lastTestDate: .now.addingTimeInterval(-90 * day),
						arvsPrescribed: true,
						arvRegimen: "TDF/3TC/DTG",
						arvCompliant: true
					)
				)
			),
			// HIV negative, on PrEP, adherent
			Patient(
				alias: .wardBed(ward: 3, bed: 12),
				glyph: .hexagon,
				gradient: .jade,
				demographics: PatientDemographics(
					age: PatientAge(value: 27, unit: .years),
					biologicalSex: .male,
					gender: .cisgenderMale,
					pronouns: .heHim,
					hiv: HIVStatus(
						status: .negative,
						lastTestDate: .now.addingTimeInterval(-30 * day),
						onPrEP: true,
						prepRegimen: "TDF/FTC",
						prepCompliant: true
					)
				)
			),
			// Infant — age in months, HIV status not yet resolved
			Patient(
				alias: .character("β", script: .greek),
				glyph: .circle,
				gradient: .bubblegum,
				demographics: PatientDemographics(
					age: PatientAge(value: 8, unit: .months),
					biologicalSex: .female,
					hiv: HIVStatus(status: .unknown)
				)
			),
			// Neonate — singular age unit, intersex, minimal record
			Patient(
				alias: .wardBed(ward: 1, bed: 4),
				glyph: .capsulePortrait,
				gradient: .winter,
				demographics: PatientDemographics(
					age: PatientAge(value: 1, unit: .weeks),
					biologicalSex: .intersex
				)
			),
			// Days-old neonate
			Patient(
				alias: .wardBed(ward: 1, bed: 7),
				glyph: .ovalPortrait,
				gradient: .petal,
				demographics: PatientDemographics(
					age: PatientAge(value: 4, unit: .days),
					biologicalSex: .female
				)
			),
			// Empty profile — every demographic renders "Not recorded"
			Patient(
				alias: .character("ω", script: .greek),
				glyph: .shield,
				gradient: .abyss
			),
			// Transgender man — HIV negative, not on PrEP, tested a year ago
			Patient(
				alias: .character("K", script: .latin),
				glyph: .diamond,
				gradient: .violet,
				demographics: PatientDemographics(
					age: PatientAge(value: 41, unit: .years),
					biologicalSex: .female,
					gender: .transgenderMan,
					pronouns: .heHim,
					hiv: HIVStatus(
						status: .negative,
						lastTestDate: .now.addingTimeInterval(-365 * day)
					)
				)
			),
			// Non-binary adult — HIV positive, ARVs prescribed, non-adherent
			Patient(
				alias: .wardBed(ward: 7, bed: 21),
				glyph: .triangle,
				gradient: .sunburn,
				demographics: PatientDemographics(
					age: PatientAge(value: 19, unit: .years),
					biologicalSex: .other,
					gender: .nonBinary,
					pronouns: .theyThem,
					hiv: HIVStatus(
						status: .positive,
						arvsPrescribed: true,
						arvRegimen: "TDF/3TC/DTG",
						arvCompliant: false
					)
				)
			),
			// Elderly — created six days ago, expires tomorrow
			Patient(
				alias: .character("Z", script: .latin),
				glyph: .pentagon,
				gradient: .cacao,
				demographics: PatientDemographics(
					age: PatientAge(value: 78, unit: .years),
					biologicalSex: .male,
					gender: .cisgenderMale,
					pronouns: .heHim
				),
				createdAt: .now.addingTimeInterval(-6 * day)
			)
		]
	}
}
#endif
