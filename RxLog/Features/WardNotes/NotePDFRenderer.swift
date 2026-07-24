//
//  NotePDFRenderer.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/07/24.
//
//  Paginated A4 PDF rendering for note exports

import UIKit

/// Renders notes into paginated A4 PDF data
///
/// Prominent title, secondary dated subline, body
enum NotePDFRenderer {
	
	// MARK: - Page Metrics
	
	/// A4 in PDF points (72 per inch)
	private static let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
	private static let margin: CGFloat = 48
	private static var contentRect: CGRect { pageRect.insetBy(dx: margin, dy: margin) }
	
	// MARK: - Rendering
	
	/// One PDF containing `notes` in order, breaking pages wherever text runs out of room
	static func pdfData(for notes: [Note]) -> Data {
		let content = attributedDocument(for: notes)
		let framesetter = CTFramesetterCreateWithAttributedString(content)
		let length = content.length
		let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
		
		return renderer.pdfData { context in
			var location = 0
			repeat {
				context.beginPage()
				let cg = context.cgContext
				
				// Renderer context uses UIKit's top-left origin
				// Core Text draws in Quartz's bottom-left space
				// Flipped for the draw, and express content rect in Quartz coordinates
				cg.saveGState()
				cg.translateBy(x: 0, y: pageRect.height)
				cg.scaleBy(x: 1, y: -1)
				
				let quartzContent = CGRect(
					x: contentRect.minX,
					y: pageRect.height - contentRect.maxY,
					width: contentRect.width,
					height: contentRect.height
				)
				let frame = CTFramesetterCreateFrame(
					framesetter,
					CFRange(location: location, length: 0),
					CGPath(rect: quartzContent, transform: nil),
					nil
				)
				CTFrameDraw(frame, cg)
				cg.restoreGState()
				
				let visible = CTFrameGetVisibleStringRange(frame)
				guard visible.length > 0 else { break }
				location += visible.length
			} while location < length
		}
	}
	
	// MARK: - Attributed Content
	
	// Fixed colours throughout so dark/light mode don't render directly to PDF
	private static func attributedDocument(for notes: [Note]) -> NSAttributedString {
		let document = NSMutableAttributedString()
		for (index, note) in notes.enumerated() {
			if index > 0 { document.append(separator) }
			document.append(block(for: note))
		}
		return document
	}
	
	/// Title, dated subline, and body
	private static func block(for note: Note) -> NSAttributedString {
		let block = NSMutableAttributedString()
		
		let titleStyle = NSMutableParagraphStyle()
		titleStyle.paragraphSpacing = 4
		block.append(NSAttributedString(
			string: note.displayTitle + "\n",
			attributes: [
				.font: boldFont(for: .title2),
				.foregroundColor: UIColor.black,
				.paragraphStyle: titleStyle
			]
		))
		
		let sublineStyle = NSMutableParagraphStyle()
		sublineStyle.paragraphSpacing = 12
		block.append(NSAttributedString(
			string: NoteExporter.datesLine(for: note) + "\n",
			attributes: [
				.font: UIFont.preferredFont(forTextStyle: .subheadline),
				.foregroundColor: UIColor(white: 0.4, alpha: 1),
				.paragraphStyle: sublineStyle
			]
		))
		
		let bodyStyle = NSMutableParagraphStyle()
		bodyStyle.paragraphSpacing = 6
		block.append(NSAttributedString(
			string: note.plainText,
			attributes: [
				.font: UIFont.preferredFont(forTextStyle: .body),
				.foregroundColor: UIColor.black,
				.paragraphStyle: bodyStyle
			]
		))
		
		return block
	}
	
	/// Centred rule standing in for the markdown `---` between stitched notes
	private static var separator: NSAttributedString {
		let style = NSMutableParagraphStyle()
		style.alignment = .center
		style.paragraphSpacingBefore = 18
		style.paragraphSpacing = 18
		return NSAttributedString(
			string: "\n" + String(repeating: "―", count: 12) + "\n",
			attributes: [
				.font: UIFont.preferredFont(forTextStyle: .footnote),
				.foregroundColor: UIColor(white: 0.6, alpha: 1),
				.paragraphStyle: style
			]
		)
	}
	
	private static func boldFont(for style: UIFont.TextStyle) -> UIFont {
		let base = UIFont.preferredFont(forTextStyle: style)
		let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor
		return UIFont(descriptor: descriptor, size: 0)
	}
}
