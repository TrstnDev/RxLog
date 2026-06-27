//
//  NoteEditorView.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/25.
//

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    
	// MARK: DECLARATIONS
	
    @Environment(\.modelContext) private var modelContext
    @Environment(\.fontResolutionContext) private var fontResolutionContext
	@Environment(\.scenePhase) private var scenePhase
    
    @Bindable var note: Note
    
    @State private var text = AttributedString()
    @State private var selection = AttributedTextSelection()
    
	// MARK: BODY
	
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $note.title, axis: .vertical)
                .font(.title2)
                .fontWeight(.semibold)
                .noteTypography()
                .textFieldStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
            
            TextEditor(text: $text, selection: $selection)
				.font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
		.onAppear {
			text = note.content
			note.lastViewed = .now
		}
		.onChange(of: scenePhase) { _, phase in
			if phase != .active { saveBody() }
		}
		.onDisappear { commitOrDiscard() }
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button { toggleBold() } label: { Image(systemName: "bold") }
                    .foregroundStyle(isBold ? Color.accentColor : .primary)
                Button { toggleItalic() } label: { Image(systemName: "italic") }
                    .foregroundStyle(isItalic ? Color.accentColor : .primary)
                Button { toggleUnderline() } label: { Image(systemName: "underline") }
                    .foregroundStyle(hasUnderline ? Color.accentColor : .primary)
                Button { toggleStrikethrough() } label: { Image(systemName: "strikethrough") }
                    .foregroundStyle(hasStrikethrough ? Color.accentColor : .primary)
                Spacer()
            }
        }
    }
    
    // MARK: FORMATTING ACTIONS
   
    private func toggleBold() {
        text.transformAttributes(in: &selection) { c in
			let f = c.font ?? .system(.body, design: .monospaced)
			c.font = f.bold(!f.resolve(in: fontResolutionContext).isBold)
        }
    }
    
    private func toggleItalic() {
        text.transformAttributes(in: &selection) { c in
			let f = c.font ?? .system(.body, design: .monospaced)
			c.font = f.italic(!f.resolve(in: fontResolutionContext).isItalic)
        }
    }
    
    private func toggleUnderline() {
        text.transformAttributes(in: &selection) { c in
            c.underlineStyle = (c.underlineStyle == nil) ? .single : nil
        }
    }
    
    private func toggleStrikethrough() {
        text.transformAttributes(in: &selection) { c in
            c.strikethroughStyle = (c.strikethroughStyle == nil) ? .single : nil
        }
    }
    
    // MARK: ACTIVE-STATE
    
    private var isBold: Bool {
        guard let font = selection.typingAttributes(in: text).font else { return false }
        return font.resolve(in: fontResolutionContext).isBold
    }
    
    private var isItalic: Bool {
        guard let font = selection.typingAttributes(in: text).font else { return false }
        return font.resolve(in: fontResolutionContext).isItalic
    }
    
    private var hasUnderline: Bool {
        selection.typingAttributes(in: text).underlineStyle != nil
    }
    
    private var hasStrikethrough: Bool {
        selection.typingAttributes(in: text).strikethroughStyle != nil
    }
    
    // MARK: PERSISTENCE
	
	/// <summary>True only when the buffer differs from what's stored</summary>
	private var bodyChanged: Bool {
		text != note.content
	}
	
	/// <summary>Commit the body buffer if it actually changed (save only; no discard)</summary>
	private func saveBody() {
		guard bodyChanged else { return }
		note.content = text
		note.dateModified = .now
	}
    
	private func commitOrDiscard() {
		let titleBlank = note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		let bodyBlank = String(text.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		if titleBlank && bodyBlank {
			modelContext.delete(note)
		} else {
			saveBody()
		}
	}
}

#Preview {
    NavigationStack {
        NoteEditorView(
            note: Note(
                title : "Bed 12 - Mr. Dlamini",
                content: AttributedString(
                    "Day 1 post addendectomy. Obs stable, afebrile. Wound clean and dry."
                )
            )
        )
    }
    .modelContainer(for: Note.self, inMemory: true)
}
