//
//  Note.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftData
import SwiftUI

/// <summary>Representation of one single ward note</summary>
@Model
final class Note {
	var title: String
    
	/// Rich-text content, JSON-encoded
	private var contentData: Data
    
	/// Plain-text mirror of 'content'
	var plainText: String
    
	var dateCreated: Date
	var dateModified: Date
	var lastViewed: Date
	var isFavourite: Bool
    
	/// <summary>Typed façade over 'contentData'</summary>
	/// Getter decodes JSON -> 'AttributedString'
	/// Setter re-encodes and refreshes 'plainText'
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
    
	/// <summary>Single definition of how rich text is encoded for storage, shared by 'content' setter and 'init'</summary>
	private static func encode(_ value: AttributedString) -> Data {
		(try? JSONEncoder().encode(value)) ?? Data()
	}
}
