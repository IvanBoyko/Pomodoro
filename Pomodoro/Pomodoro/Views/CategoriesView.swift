//
//  CategoriesView.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PomodoroCategory.createdAt) private var categories: [PomodoroCategory]

    @State private var showAddSheet = false
    @State private var editingCategory: PomodoroCategory?

    var body: some View {
        NavigationStack {
            List {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories",
                        systemImage: "tag",
                        description: Text("Add categories to organize your Pomodoros.")
                    )
                }

                ForEach(categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(category.sessions.count) sessions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                CategoryFormView()
            }
            .sheet(item: $editingCategory) { category in
                CategoryFormView(category: category)
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var category: PomodoroCategory?

    @State private var name: String = ""
    @State private var selectedColorHex: String = Color.categoryColors[0].hex

    var isEditing: Bool { category != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(Color.categoryColors, id: \.hex) { item in
                            Circle()
                                .fill(Color(hex: item.hex))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if selectedColorHex == item.hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.headline)
                                    }
                                }
                                .onTapGesture {
                                    selectedColorHex = item.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let category {
                    name = category.name
                    selectedColorHex = category.colorHex
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = trimmed
            category.colorHex = selectedColorHex
        } else {
            let newCategory = PomodoroCategory(name: trimmed, colorHex: selectedColorHex)
            modelContext.insert(newCategory)
        }
    }
}

#Preview {
    CategoriesView()
        .modelContainer(for: [PomodoroCategory.self, PomodoroSession.self], inMemory: true)
}
