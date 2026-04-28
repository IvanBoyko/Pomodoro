//
//  DaySummaryTests.swift
//  PomodoroTests
//

import Testing
import Foundation
@testable import Pomodoro

@Suite struct DaySummaryTests {
    private static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour
        return utcCalendar.date(from: c)!
    }

    private static func session(date: Date, category: PomodoroCategory? = nil) -> PomodoroSession {
        PomodoroSession(startedAt: date.addingTimeInterval(-25 * 60),
                        completedAt: date,
                        category: category)
    }

    @Test func emptyInputProducesZeroes() {
        let summary = DaySummary(sessions: [], categories: [],
                                 on: Self.date(2026, 4, 28),
                                 calendar: Self.utcCalendar)
        #expect(summary.totalCount == 0)
        #expect(summary.totalMinutes == 0)
        #expect(summary.breakdown.isEmpty)
    }

    @Test func totalCountFiltersBySelectedDate() {
        let cat = PomodoroCategory(name: "X")
        let target = Self.date(2026, 4, 28)
        let sessions = [
            Self.session(date: target, category: cat),
            Self.session(date: target, category: cat),
            Self.session(date: Self.date(2026, 4, 27), category: cat),
        ]
        let summary = DaySummary(sessions: sessions, categories: [cat],
                                 on: target, calendar: Self.utcCalendar)
        #expect(summary.totalCount == 2)
    }

    @Test func totalMinutesUsesDefault25Multiplier() {
        let target = Self.date(2026, 4, 28)
        let sessions = [
            Self.session(date: target),
            Self.session(date: target),
            Self.session(date: target),
        ]
        let summary = DaySummary(sessions: sessions, categories: [],
                                 on: target, calendar: Self.utcCalendar)
        #expect(summary.totalMinutes == 75)
    }

    @Test func customMinutesPerSessionScalesTotal() {
        let target = Self.date(2026, 4, 28)
        let sessions = [Self.session(date: target), Self.session(date: target)]
        let summary = DaySummary(sessions: sessions, categories: [],
                                 on: target, calendar: Self.utcCalendar,
                                 minutesPerSession: 10)
        #expect(summary.totalMinutes == 20)
    }

    @Test func breakdownExcludesCategoriesWithoutSessionsOnDate() {
        let used = PomodoroCategory(name: "Used")
        let unused = PomodoroCategory(name: "Unused")
        let target = Self.date(2026, 4, 28)

        let summary = DaySummary(sessions: [Self.session(date: target, category: used)],
                                 categories: [used, unused],
                                 on: target, calendar: Self.utcCalendar)
        #expect(summary.breakdown.count == 1)
        #expect(summary.breakdown.first?.category.id == used.id)
        #expect(summary.breakdown.first?.count == 1)
    }

    @Test func breakdownSortedByCountDescending() {
        let a = PomodoroCategory(name: "A")
        let b = PomodoroCategory(name: "B")
        let c = PomodoroCategory(name: "C")
        let target = Self.date(2026, 4, 28)

        let sessions = [
            Self.session(date: target, category: a),
            Self.session(date: target, category: b),
            Self.session(date: target, category: b),
            Self.session(date: target, category: b),
            Self.session(date: target, category: c),
            Self.session(date: target, category: c),
        ]
        let summary = DaySummary(sessions: sessions, categories: [a, b, c],
                                 on: target, calendar: Self.utcCalendar)

        #expect(summary.breakdown.map(\.count) == [3, 2, 1])
        #expect(summary.breakdown.map(\.category.id) == [b.id, c.id, a.id])
    }

    @Test func uncategorizedSessionsCountInTotalButNotInBreakdown() {
        let cat = PomodoroCategory(name: "X")
        let target = Self.date(2026, 4, 28)
        let sessions = [
            Self.session(date: target, category: cat),
            Self.session(date: target, category: nil),
            Self.session(date: target, category: nil),
        ]
        let summary = DaySummary(sessions: sessions, categories: [cat],
                                 on: target, calendar: Self.utcCalendar)
        #expect(summary.totalCount == 3)
        #expect(summary.breakdown.count == 1)
        #expect(summary.breakdown.first?.count == 1)
    }
}
