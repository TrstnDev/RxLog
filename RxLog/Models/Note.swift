//
//  Note.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI
import SwiftData

/// A single ward note
@Model
final class Note {
    
    var title: String
    
    // Rich-text content
    private var contentData: Data
    
    var dateCreated: Date
    var dateModified: Date
    var lastViewed: Date
    var isFavourite: Bool
    
    var content: AttributedString {
        get {
            (try? JSONDecoder().decode(AttributedString.self, from: contentData))
                ?? AttributedString()
        }
        set {
            contentData = (try? JSONEncoder().encode(newValue)) ?? Data()
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
        self.contentData = (try? JSONEncoder().encode(content)) ?? Data()
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.lastViewed = lastViewed
        self.isFavourite = isFavourite
    }
}
