//
//  DaySummary.swift
//  Pomodoro
//
//  Pure aggregation of sessions for a single day, with per-category counts
//  ordered by descending count. Decoupled so the math is unit-testable.
//

import Foundation

struct DaySummary {
    struct Entry {
        let category: PomodoroCategory
        let count: Int
    }

    let totalCount: Int
    let totalMinutes: Int
    let breakdown: [Entry]

    init(sessions: [PomodoroSession],
         categories: [PomodoroCategory],
         on date: Date,
         calendar: Calendar = .current,
         minutesPerSession: Int = 25) {
        let sessionsForDate = sessions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: date)
        }

        self.totalCount = sessionsForDate.count
        self.totalMinutes = sessionsForDate.count * minutesPerSession

        var counts: [UUID: Int] = [:]
        for session in sessionsForDate {
            if let cat = session.category {
                counts[cat.id, default: 0] += 1
            }
        }
        self.breakdown = categories
            .compactMap { cat in
                let count = counts[cat.id] ?? 0
                return count > 0 ? Entry(category: cat, count: count) : nil
            }
            .sorted { $0.count > $1.count }
    }
}
