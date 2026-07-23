//
//  NoteExporter.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/23.
//
//  Value-layer for Ward Notes export: markdown/plain-text rendering and filename construction

import Foundation

// MARK: - Format

/// The file formats offered by the export flow
enum ExportFormat: String, CaseIterable, Identifiable {
	case plainText
	case markdown
	case pdf
	
	var id: Self { self }
	
	var label: String {
		switch self {
		case .plainText: "Plain Text"
		case .markdown: "Markdown"
		case .pdf: "PDF"
		}
	}
	
	var fileExtension: String {
		switch self {
		case .plainText: "txt"
		case .markdown: "md"
		case .pdf: "pdf"
		}
	}
}

// MARK: - Exporter

/// Renders notes into shareable documents and builds their filenames
enum NoteExporter {
	
	// MARK: Markdown
	
	/// One note as Markdown: `#` title, `##` dated subtitle, body
	static func markdown(for note: Note) -> String {
		"""
  # \(note.displayTitle)
  ## \(datesLine(for: note))
  
  \(note.plainText)
"""
	}
	
	/// All `notes` stitched into one document, separated by horizontal rules
	static func stitchedMarkdown(for notes: [Note]) -> String {
		notes.map(markdown(for:)).joined(separator: "\n\n---\n\n")
	}
	
	// MARK: Plain Text
	
	/// One note as plain text: title over a `=` rule, dates line, body
	static func plainText(for note: Note) -> String {
		let title = note.displayTitle
		let rule = String(repeating: "=", count: min(title.count, ruleWidth))
		return """
	  \(title)
	  \(rule)
	  \(datesLine(for: note))

	  \(note.plainText)
"""
	}
	
	/// All `notes` stitched into one document, separated by dashed rules
	static func stitchedPlainText(for notes: [Note]) -> String {
		let separator = "\n\n" + String(repeating: "-", count: ruleWidth) + "\n\n"
		return notes.map(plainText(for:)).joined(separator: separator)
	}
	
	// MARK: Filenames
	
	/// Single-note filename; ISO 8601 for the date
	static func filename(for note: Note, format: ExportFormat) -> String {
		let date = note.dateCreated.formatted(.iso8601.year().month().day())
		return "\(sanitized(note.displayTitle)) (\(date)).\(format.fileExtension)"
	}
	
	/// Stiched-export filename
	static func stitchedFilename(format: ExportFormat, date: Date = .now) -> String {
		"Ward Notes Export \(date.formatted(.iso8601.year().month().day())).\(format.fileExtension)"
	}
	
	/// Makes a title safe for use as a filename: strips path-hostile characters, collapses whitespace, caps length
	static func sanitized(_ title: String) -> String {
		var name = title
			.replacingOccurrences(of: "/", with: "-")
			.replacingOccurrences(of: ":", with: "-")
		name = name
			.components(separatedBy: .whitespacesAndNewlines)
			.filter { !$0.isEmpty }
			.joined(separator: " ")
		name = String(name.prefix(maxFilenameLength)).trimmingCharacters(in: .whitespaces)
		return name.isEmpty ? "Note" : name
	}
	
	// MARK: Helpers
	
	private static let ruleWidth = 40
	private static let maxFilenameLength = 80
	
	/// `Created ...`, plus `Modified ...` only when note has been edited
	private static func datesLine(for note: Note) -> String {
		let created = "Created \(note.dateCreated.formatted(date: .abbreviated, time: .shortened))"
		guard note.dateModified.timeIntervalSince(note.dateCreated) >= 1 else { return created }
		return "\(created) · Modified \(note.dateModified.formatted(date: .abbreviated, time: .shortened))"
	}
}
