//
//  WeekStatistics.swift
//  Pomodoro
//
//  Pure aggregation of sessions across a 7-day window. Decoupled from
//  the view so the date math and counting can be unit-tested.
//

import Foundation

struct WeekStatistics {
    let weekDates: [Date]
    private let sessions: [PomodoroSession]
    private let categories: [PomodoroCategory]
    private let calendar: Calendar

    init(sessions: [PomodoroSession],
         categories: [PomodoroCategory],
         weekOffset: Int,
         today: Date,
         calendar: Calendar = .current) {
        self.sessions = sessions
        self.categories = categories
        self.calendar = calendar
        self.weekDates = Self.weekDates(weekOffset: weekOffset, today: today, calendar: calendar)
    }

    static func weekDates(weekOffset: Int, today: Date, calendar: Calendar) -> [Date] {
        let startOfToday = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: startOfToday)
        // Monday = start of week; weekday is 1=Sunday..7=Saturday
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day,
                                         value: -mondayOffset + (weekOffset * 7),
                                         to: startOfToday) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var weekLabel: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    func sessions(on day: Date, category: PomodoroCategory) -> Int {
        sessions.filter { session in
            session.category?.id == category.id
                && calendar.isDate(session.completedAt, inSameDayAs: day)
        }.count
    }

    func total(on day: Date) -> Int {
        sessions.filter { calendar.isDate($0.completedAt, inSameDayAs: day) }.count
    }

    func total(for category: PomodoroCategory) -> Int {
        weekDates.reduce(0) { $0 + sessions(on: $1, category: category) }
    }

    var weekTotal: Int {
        weekDates.reduce(0) { $0 + total(on: $1) }
    }
}
