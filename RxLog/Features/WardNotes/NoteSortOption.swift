//
//  NoteSortOption.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import Foundation

// How the Ward Notes list is ordered
enum NoteSortOption: String, CaseIterable, Identifiable {
    case dateModified
    case dateCreated
    case lastViewed
    case title
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .dateModified: "Date Modified"
        case .dateCreated: "Date Created"
        case .lastViewed: "Last Viewed"
        case .title: "Title"
        }
    }
    
    // The date this option sorts and sections by
    var dateKeyPath: KeyPath<Note, Date>? {
        switch self {
        case .dateModified: \.dateModified
        case .dateCreated: \.dateCreated
        case .lastViewed: \.lastViewed
        case .title: nil
        }
    }
}
