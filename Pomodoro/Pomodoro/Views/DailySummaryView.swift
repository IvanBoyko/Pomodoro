//
//  DailySummaryView.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Query(sort: \PomodoroSession.completedAt) private var allSessions: [PomodoroSession]
    @Query(sort: \PomodoroCategory.createdAt) private var categories: [PomodoroCategory]

    @State private var selectedDate: Date = Date()

    private var sessionsForDate: [PomodoroSession] {
        let calendar = Calendar.current
        return allSessions.filter { calendar.isDate($0.completedAt, inSameDayAs: selectedDate) }
    }

    private var categoryBreakdown: [(category: PomodoroCategory, count: Int)] {
        var counts: [PersistentIdentifier: Int] = [:]
        for session in sessionsForDate {
            if let cat = session.category {
                counts[cat.persistentModelID, default: 0] += 1
            }
        }
        return categories
            .compactMap { cat in
                let count = counts[cat.persistentModelID] ?? 0
                return count > 0 ? (category: cat, count: count) : nil
            }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(sessionsForDate.count)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Pomodoros")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            let totalMinutes = sessionsForDate.count * 25
                            Text("\(totalMinutes)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("Minutes focused")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if !categoryBreakdown.isEmpty {
                    Section("By Category") {
                        ForEach(categoryBreakdown, id: \.category.id) { item in
                            HStack {
                                Circle()
                                    .fill(Color(hex: item.category.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(item.category.name)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Distribution") {
                        let total = sessionsForDate.count
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                HStack(spacing: 2) {
                                    ForEach(categoryBreakdown, id: \.category.id) { item in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(hex: item.category.colorHex))
                                            .frame(
                                                width: max(4, geometry.size.width * CGFloat(item.count) / CGFloat(total))
                                            )
                                    }
                                }
                            }
                            .frame(height: 24)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "clock",
                        description: Text("No Pomodoros completed on this day.")
                    )
                }
            }
            .navigationTitle("Daily Summary")
        }
    }
}

#Preview {
    DailySummaryView()
        .modelContainer(for: [PomodoroCategory.self, PomodoroSession.self], inMemory: true)
}
