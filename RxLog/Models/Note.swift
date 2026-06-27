//
//  Note.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// A ward note: title, rich-text body, favourite flag, and timestamps. Persisted via SwiftData.
@Model
final class Note {
	var title: String
    
	/// Rich-text as JSON-encoded `Data`; backing store for `content`
	private var contentData: Data
    
	/// Plain-text mirror of `content` for search and previews; kept in sync by the `content` setter
	var plainText: String
    
	var dateCreated: Date
	var dateModified: Date
	var lastViewed: Date
	var isFavourite: Bool
    
	/// `AttributedString` façade over `contentData`; the setter also refreshes `plainText`
	var content: AttributedString {
		get {
			(try? JSONDecoder().decode(AttributedString.self, from: contentData))
				?? AttributedString()
		}
		set {
			contentData = Note.encode(newValue)
			plainText = String(newValue.characters)
		}
	}
    
	init(
		title: String = "",
		content: AttributedString = AttributedString(),
		dateCreated: Date = .now,
		dateModified: Date = .now,
		lastViewed: Date = .now,
		isFavourite: Bool = false
	) {
		self.title = title
		self.contentData = Note.encode(content)
		self.plainText = String(content.characters)
		self.dateCreated = dateCreated
		self.dateModified = dateModified
		self.lastViewed = lastViewed
		self.isFavourite = isFavourite
	}
    
	/// Encodes rich text to JSON for storage; shared by the `content` setter and `init`
	private static func encode(_ value: AttributedString) -> Data {
		(try? JSONEncoder().encode(value)) ?? Data()
	}
}
