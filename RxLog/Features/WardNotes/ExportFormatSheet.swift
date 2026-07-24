//
//  ExportFormatSheet.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/23.
//

import SwiftUI

/// Format picker for a committed export: each available format row is a `ShareLink` over files generated eagerly when the sheet appears, so the format tap itself presents the share interface
struct ExportFormatSheet: View {
	let request: ExportRequest
	
	@State private var session: URL?
	@State private var generated: [ExportFormat: [URL]] = [:]
	@State private var generationFailed = false
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					formatRow(.plainText)
					formatRow(.markdown)
					formatRow(.pdf)
				} footer: {
					if generationFailed {
						Label("Couldn't prepare the export files.", systemImage: "exclamationmark.triangle")
					} else {
						Text("Exporting ^[\(request.notes.count) note](inflect: true) \(packagingDescription).")
					}
				}
			}
			.navigationTitle("Export")
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }
						.fontWeight(.semibold)
				}
			}
			.task { generate() }
			.onDisappear(perform: cleanUp)
		}
		.presentationDetents([.medium])
		.background(Material.ultraThin)
	}
	
	// MARK: - Rows
	
	@ViewBuilder
	private func formatRow(_ format: ExportFormat) -> some View {
		if let urls = generated[format] {
			ShareLink(items: urls) {
				Label(format.label, systemImage: format.systemImage)
			}
			.foregroundStyle(.primary)
			.fontWeight(.semibold)
		} else {
			Label(format.label, systemImage: format.systemImage)
				.foregroundStyle(.secondary)
		}
	}
	
	private var packagingDescription: String {
		switch request.packaging {
		case .separateFiles: "as separate files"
		case .oneFile: "stitched into one file"
		}
	}
	
	// MARK: - Generation
	
	/// Writes every format up front; rows activate as their files land
	private func generate() {
		do {
			let dir = try NoteExporter.makeSessionDirectory()
			session = dir
			generated[.plainText] = try NoteExporter.writeFiles(for: request, format: .plainText, into: dir)
			generated[.markdown] = try NoteExporter.writeFiles(for: request, format: .markdown, into: dir)
			generated[.pdf] = try NoteExporter.writeFiles(for: request, format: .pdf, into: dir)
		} catch {
			generationFailed = true
		}
	}
	
	/// Removes the session directory; share receivers copy items during the share flow itself
	private func cleanUp() {
		guard let session else { return }
		try? FileManager.default.removeItem(at: session)
	}
}

#Preview {
	ExportFormatSheet(request: ExportRequest(
		packaging: .oneFile,
		notes: SampleData.sampleNotes
	))
}
