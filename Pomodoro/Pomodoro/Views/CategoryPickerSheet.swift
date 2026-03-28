//
//  CategoryPickerSheet.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PomodoroCategory.createdAt) private var categories: [PomodoroCategory]

    var timerVM: TimerViewModel

    @State private var newCategoryName: String = ""
    @State private var showNewCategoryField = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Pomodoro Complete!")
                        .font(.title2.bold())
                    Text("Assign a category to this session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                List {
                    if categories.isEmpty && !showNewCategoryField {
                        Text("No categories yet. Create one below.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(categories) { category in
                        Button {
                            saveSession(category: category)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    if showNewCategoryField {
                        HStack {
                            TextField("New category name", text: $newCategoryName)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                let cat = PomodoroCategory(name: newCategoryName.trimmingCharacters(in: .whitespaces))
                                modelContext.insert(cat)
                                saveSession(category: cat)
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    Button {
                        showNewCategoryField = true
                    } label: {
                        Label("New Category", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Assign Category")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }

    private func saveSession(category: PomodoroCategory) {
        guard let start = timerVM.completedStartDate,
              let end = timerVM.completedEndDate else { return }

        let session = PomodoroSession(startedAt: start, completedAt: end, category: category)
        modelContext.insert(session)
        timerVM.resetAfterSave()
        dismiss()
    }
}
