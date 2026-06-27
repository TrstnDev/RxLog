//
//  RxLogApp.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/12.
//

import SwiftData
import SwiftUI

/// Application entry point
@main
struct RxLogApp: App {
	var body: some Scene {
		WindowGroup {
			RootView()
		}
		.modelContainer(for: Note.self)
	}
}
