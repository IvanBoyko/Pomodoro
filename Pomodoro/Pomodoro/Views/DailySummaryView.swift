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

    private var summary: DaySummary {
        DaySummary(sessions: allSessions, categories: categories, on: selectedDate)
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
                            Text("\(summary.totalCount)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Pomodoros")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(summary.totalMinutes)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("Minutes focused")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if !summary.breakdown.isEmpty {
                    Section("By Category") {
                        ForEach(summary.breakdown, id: \.category.id) { item in
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
                        let total = summary.totalCount
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                HStack(spacing: 2) {
                                    ForEach(summary.breakdown, id: \.category.id) { item in
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
