//
//  NoteFilterSheet.swift
//  RxLog
//
//  Created by Tristan Kriel on 2026/06/25.
//

import SwiftUI

/// Half-sheet for filtering the Ward Notes list
struct NoteFilterSheet: View {
	@Binding var filter: NoteFilter
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			Form {
				Section("Date Range") {
					Picker("Date Range", selection: $filter.dateRange) {
						ForEach(DateRangeOption.allCases) { option in
							Text(option.label).tag(option)
						}
					}
					.pickerStyle(.inline)
					.labelsHidden()
				}

				Section {
					Toggle("Favourites Only", isOn: $filter.favouritesOnly)
				}
			}
			.navigationTitle("Filter")
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Reset") { filter = NoteFilter() }
						.disabled(!filter.isActive)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }
						.fontWeight(.semibold)
				}
			}
		}
		.presentationDetents([.medium])
		.presentationDragIndicator(.visible)
		.background(Material.ultraThin)
	}
}

#Preview {
	@Previewable @State var filter = NoteFilter()
	NoteFilterSheet(filter: $filter)
}
