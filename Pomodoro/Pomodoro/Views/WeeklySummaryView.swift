//
//  WeeklySummaryView.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Query(sort: \PomodoroSession.completedAt) private var allSessions: [PomodoroSession]
    @Query(sort: \PomodoroCategory.createdAt) private var categories: [PomodoroCategory]

    @State private var weekOffset: Int = 0

    private var calendar: Calendar { Calendar.current }

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Monday = start of week
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset + (weekOffset * 7), to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private var weekLabel: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    private func sessionsFor(date: Date, category: PomodoroCategory) -> Int {
        allSessions.filter { session in
            session.category?.persistentModelID == category.persistentModelID
                && calendar.isDate(session.completedAt, inSameDayAs: date)
        }.count
    }

    private func totalFor(date: Date) -> Int {
        allSessions.filter { calendar.isDate($0.completedAt, inSameDayAs: date) }.count
    }

    private func totalFor(category: PomodoroCategory) -> Int {
        weekDates.reduce(0) { $0 + sessionsFor(date: $1, category: category) }
    }

    private var weekTotal: Int {
        weekDates.reduce(0) { $0 + totalFor(date: $1) }
    }

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week navigator
                HStack {
                    Button {
                        weekOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()
                    Text(weekLabel)
                        .font(.headline)
                    Spacer()

                    Button {
                        if weekOffset < 0 {
                            weekOffset += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(weekOffset >= 0)
                }
                .padding()

                // Week total
                VStack(spacing: 4) {
                    Text("\(weekTotal)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Pomodoros this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 16)

                // Table
                ScrollView {
                    Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
                        // Header row
                        GridRow {
                            Text("")
                                .gridCellColumns(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)

                            ForEach(0..<7, id: \.self) { i in
                                Text(dayLabels[i])
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                            }

                            Text("Σ")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))

                        Divider()

                        // Category rows
                        ForEach(categories) { category in
                            GridRow {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: category.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(category.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .gridCellColumns(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)

                                ForEach(0..<7, id: \.self) { dayIndex in
                                    let count = dayIndex < weekDates.count
                                        ? sessionsFor(date: weekDates[dayIndex], category: category)
                                        : 0
                                    Text(count > 0 ? "\(count)" : "–")
                                        .font(.callout.monospacedDigit())
                                        .foregroundStyle(count > 0 ? .primary : .tertiary)
                                        .frame(maxWidth: .infinity)
                                }

                                Text("\(totalFor(category: category))")
                                    .font(.callout.bold().monospacedDigit())
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 6)

                            Divider()
                        }

                        // Totals row
                        GridRow {
                            Text("Total")
                                .font(.caption.bold())
                                .gridCellColumns(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)

                            ForEach(0..<7, id: \.self) { dayIndex in
                                let count = dayIndex < weekDates.count
                                    ? totalFor(date: weekDates[dayIndex])
                                    : 0
                                Text(count > 0 ? "\(count)" : "–")
                                    .font(.callout.bold().monospacedDigit())
                                    .foregroundStyle(count > 0 ? .primary : .tertiary)
                                    .frame(maxWidth: .infinity)
                            }

                            Text("\(weekTotal)")
                                .font(.callout.bold().monospacedDigit())
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }
                }
            }
            .navigationTitle("Weekly Summary")
        }
    }
}

#Preview {
    WeeklySummaryView()
        .modelContainer(for: [PomodoroCategory.self, PomodoroSession.self], inMemory: true)
}
