//
//  NoteDisplayStyle.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/24.
//

import SwiftUI

enum NoteDisplayStyle: String, CaseIterable, Identifiable {
    case waterfall
    case grid
    case list
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .waterfall:
            "Waterfall"
        case .grid:
            "Grid"
        case .list:
            "List"
        }
    }
    
    var systemImage: String {
        switch self {
        case .waterfall:
            "rectangle.3.offgrid"
        case .grid:
            "square.grid.2x2"
        case .list:
            "list.bullet"
        }
    }
}
