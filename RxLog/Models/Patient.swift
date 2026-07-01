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
	/// Alias as JSON-encoded `Data`; backing store for ``alias``
	private var aliasData: Data
	
	var glyph: AvatarGlyph
	var gradient: AppGradient
	var createdAt: Date
	var expiresAt: Date
	
	/// Typed façade over ``aliasData``
	var alias: PatientAlias {
		get { (try? JSONDecoder().decode(PatientAlias.self, from: aliasData)) ?? .placeholder }
		set { aliasData = Patient.encode(newValue) }
	}
	
	init(
		alias: PatientAlias,
		glyph: AvatarGlyph,
		gradient: AppGradient,
		createdAt: Date = .now,
		expiresAt: Date? = nil
	) {
		self.aliasData = Patient.encode(alias)
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
enum PatientAlias: Codable, Hashable {
	/// Capitalised Latin or lowercase Greek character, e.g., "Patient X" or "Patient β"
	case character(String, script: Script)
	
	/// A ward and bed number, e.g., "Ward 5 · Bed 10"
	case wardBed(ward: Int, bed: Int)
	
	/// A pre-populated pseudonym, e.g., "John Doe"
	case pseudonym(first: String, last: String)
	
	enum Script: String, Codable, Hashable, CaseIterable {
		case latin, greek
	}
	
	/// The rendered label for cards and headers
	var displayName: String {
		switch self {
		case .character(let value, _): "Patient \(value)"
		case .wardBed(let ward, let bed): "Ward \(ward) · Bed \(bed)"
		case .pseudonym(let first, let last): "\(first) \(last)"
		}
	}
	
	/// Fallback used only if stored data fails to decode
	static let placeholder = PatientAlias.character("?", script: .latin)
}

// MARK: - Avatar Glyph

/// The SF Symbol shapes offered for a patient avatar
enum AvatarGlyph: String, CaseIterable, Identifiable, Codable {
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
	static var samples: [Patient] {
		[
			Patient(alias: .pseudonym(first: "John", last: "Apple"), glyph: .seal, gradient: .berry),
			Patient(alias: .pseudonym(first: "Jane", last: "Doe"), glyph: .buttonRoundedBottom, gradient: .dusk),
			Patient(alias: .wardBed(ward: 5, bed: 10), glyph: .hexagon, gradient: .mandarin),
			Patient(alias: .character("Y", script: .latin), glyph: .buttonAngledTopRight, gradient: .jade)
		]
	}
}
#endif
