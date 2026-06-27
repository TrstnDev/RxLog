//
//  FormattingTestView.swift
//  RxLog
//
//  TEMPORARY diagnostic — proves the real bug: a PLAIN JSON round-trip (what
//  Note.content does today) drops SwiftUI attributes, while a SCOPED round-trip
//  preserves them. Delete once confirmed.
//
import SwiftUI

// A scope that bundles the full set of SwiftUI text attributes. Encoding an
// AttributedString *through this scope* is what keeps font/underline/etc. alive.
extension AttributeScopes {
    struct NoteScope: AttributeScope {
        let swiftUI: SwiftUIAttributes
    }
    var note: NoteScope.Type { NoteScope.self }
}

// Wrapper that ties an AttributedString's Codable conformance to the scope above.
// `@CodableConfiguration` is the documented way to do this.
private struct ScopedContent: Codable {
    @CodableConfiguration(from: \.note) var text = AttributedString()
    init(_ text: AttributedString) { self.text = text }
}

struct FormattingTestView: View {
    @Environment(\.fontResolutionContext) private var ctx

    @State private var text = AttributedString("Select me, make me bold, then round-trip.")
    @State private var selection = AttributedTextSelection()
    @State private var status = "Bold a word, then tap a round-trip button."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextEditor(text: $text, selection: $selection)
                .font(.system(.body, design: .monospaced))   // monospaced base font
                .frame(height: 150)
                .border(.secondary)

            HStack(spacing: 12) {
                Button("Bold", systemImage: "bold") { toggleBold() }
                Button("Italic", systemImage: "italic") { toggleItalic() }
                Button("Underline", systemImage: "underline") { toggleUnderline() }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)

            // What Note.content does today — expect formatting to vanish.
            Button("Round-trip: PLAIN JSON (current Note behaviour)") { roundTripPlain() }
            // The fix — expect formatting to survive.
            Button("Round-trip: SCOPED JSON (the fix)") { roundTripScoped() }
                .buttonStyle(.borderedProminent)

            Text(status).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
    }

    private func roundTripPlain() {
        let data = (try? JSONEncoder().encode(text)) ?? Data()
        let restored = (try? JSONDecoder().decode(AttributedString.self, from: data)) ?? AttributedString()
        text = restored
        report("PLAIN", data: data, restored: restored)
    }

    private func roundTripScoped() {
        let data = (try? JSONEncoder().encode(ScopedContent(text))) ?? Data()
        let restored = (try? JSONDecoder().decode(ScopedContent.self, from: data))?.text ?? AttributedString()
        text = restored
        report("SCOPED", data: data, restored: restored)
    }

    private func report(_ label: String, data: Data, restored: AttributedString) {
        let styled = restored.runs.filter { $0.font != nil || $0.underlineStyle != nil }.count
        status = "\(label): \(data.count) bytes, \(restored.runs.count) runs, \(styled) styled "
            + (styled == 0 ? "→ formatting DROPPED." : "→ formatting SURVIVED.")
    }

    private func toggleBold() {
        text.transformAttributes(in: &selection) { c in
            let f = c.font ?? .system(.body, design: .monospaced)
            c.font = f.bold(!f.resolve(in: ctx).isBold)
        }
    }
    private func toggleItalic() {
        text.transformAttributes(in: &selection) { c in
            let f = c.font ?? .system(.body, design: .monospaced)
            c.font = f.italic(!f.resolve(in: ctx).isItalic)
        }
    }
    private func toggleUnderline() {
        text.transformAttributes(in: &selection) { c in
            c.underlineStyle = (c.underlineStyle == nil) ? .single : nil
        }
    }
}

#Preview {
    FormattingTestView()
}
