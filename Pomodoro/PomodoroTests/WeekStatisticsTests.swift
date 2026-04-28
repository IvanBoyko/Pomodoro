//
//  WeekStatisticsTests.swift
//  PomodoroTests
//

import Testing
import Foundation
@testable import Pomodoro

@Suite struct WeekStatisticsTests {
    private static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Build a UTC Date from year/month/day at noon (avoids DST corner cases for `isDate(_:inSameDayAs:)`).
    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour
        return utcCalendar.date(from: c)!
    }

    private static func makeSession(date: Date, category: PomodoroCategory? = nil) -> PomodoroSession {
        PomodoroSession(startedAt: date.addingTimeInterval(-25 * 60),
                        completedAt: date,
                        category: category)
    }

    // MARK: - weekDates

    @Test func weekDatesReturnsSevenDaysStartingMonday() {
        // 2026-04-28 is a Tuesday
        let today = Self.date(2026, 4, 28)
        let dates = WeekStatistics.weekDates(weekOffset: 0, today: today, calendar: Self.utcCalendar)
        #expect(dates.count == 7)
        let comps = Self.utcCalendar.dateComponents([.year, .month, .day], from: dates[0])
        #expect(comps.year == 2026 && comps.month == 4 && comps.day == 27)
        let last = Self.utcCalendar.dateComponents([.year, .month, .day], from: dates[6])
        #expect(last.year == 2026 && last.month == 5 && last.day == 3)
    }

    @Test func weekDatesAnchorsOnMondayWhenTodayIsSunday() {
        // 2026-04-26 is a Sunday — the "current" week's Monday is six days earlier
        let today = Self.date(2026, 4, 26)
        let dates = WeekStatistics.weekDates(weekOffset: 0, today: today, calendar: Self.utcCalendar)
        let monday = Self.utcCalendar.dateComponents([.year, .month, .day], from: dates[0])
        #expect(monday.month == 4 && monday.day == 20)
    }

    @Test func weekDatesShiftsByWeekOffset() {
        let today = Self.date(2026, 4, 28)
        let prev = WeekStatistics.weekDates(weekOffset: -1, today: today, calendar: Self.utcCalendar)
        let next = WeekStatistics.weekDates(weekOffset: 1, today: today, calendar: Self.utcCalendar)

        let prevMonday = Self.utcCalendar.dateComponents([.year, .month, .day], from: prev[0])
        #expect(prevMonday.month == 4 && prevMonday.day == 20)

        let nextMonday = Self.utcCalendar.dateComponents([.year, .month, .day], from: next[0])
        #expect(nextMonday.month == 5 && nextMonday.day == 4)
    }

    // MARK: - weekLabel

    @Test func weekLabelFormatsRange() {
        let stats = WeekStatistics(sessions: [], categories: [],
                                   weekOffset: 0,
                                   today: Self.date(2026, 4, 28),
                                   calendar: Self.utcCalendar)
        #expect(stats.weekLabel == "Apr 27 – May 3")
    }

    // MARK: - counting

    @Test func sessionsOnDayMatchCategoryAndDateOnly() {
        let work = PomodoroCategory(name: "Work")
        let life = PomodoroCategory(name: "Life")
        let monday = Self.date(2026, 4, 27)
        let tuesday = Self.date(2026, 4, 28)

        let sessions = [
            Self.makeSession(date: monday, category: work),
            Self.makeSession(date: monday, category: work),
            Self.makeSession(date: monday, category: life),
            Self.makeSession(date: tuesday, category: work),
        ]
        let stats = WeekStatistics(sessions: sessions, categories: [work, life],
                                   weekOffset: 0,
                                   today: tuesday,
                                   calendar: Self.utcCalendar)

        #expect(stats.sessions(on: monday, category: work) == 2)
        #expect(stats.sessions(on: monday, category: life) == 1)
        #expect(stats.sessions(on: tuesday, category: work) == 1)
        #expect(stats.sessions(on: tuesday, category: life) == 0)
    }

    @Test func totalOnDayIgnoresCategoryAndCountsAll() {
        let cat = PomodoroCategory(name: "X")
        let monday = Self.date(2026, 4, 27)
        let sessions = [
            Self.makeSession(date: monday, category: cat),
            Self.makeSession(date: monday, category: nil),
            Self.makeSession(date: monday, category: cat),
        ]
        let stats = WeekStatistics(sessions: sessions, categories: [cat],
                                   weekOffset: 0,
                                   today: monday,
                                   calendar: Self.utcCalendar)
        #expect(stats.total(on: monday) == 3)
    }

    @Test func totalForCategorySumsAcrossWeek() {
        let work = PomodoroCategory(name: "Work")
        let monday = Self.date(2026, 4, 27)
        let wednesday = Self.date(2026, 4, 29)
        let sessions = [
            Self.makeSession(date: monday, category: work),
            Self.makeSession(date: monday, category: work),
            Self.makeSession(date: wednesday, category: work),
        ]
        let stats = WeekStatistics(sessions: sessions, categories: [work],
                                   weekOffset: 0,
                                   today: monday,
                                   calendar: Self.utcCalendar)
        #expect(stats.total(for: work) == 3)
    }

    @Test func weekTotalSumsAcrossDays() {
        let work = PomodoroCategory(name: "Work")
        let monday = Self.date(2026, 4, 27)
        let friday = Self.date(2026, 5, 1)
        let sessions = [
            Self.makeSession(date: monday, category: work),
            Self.makeSession(date: friday, category: nil),
        ]
        let stats = WeekStatistics(sessions: sessions, categories: [work],
                                   weekOffset: 0,
                                   today: monday,
                                   calendar: Self.utcCalendar)
        #expect(stats.weekTotal == 2)
    }

    @Test func sessionsOutsideWeekAreNotInDayCounts() {
        // Sessions are matched by exact date; ones outside the week's 7 days are simply never queried by the view.
        let cat = PomodoroCategory(name: "X")
        let inside = Self.date(2026, 4, 27) // Monday
        let outside = Self.date(2026, 4, 20) // Previous Monday
        let sessions = [
            Self.makeSession(date: inside, category: cat),
            Self.makeSession(date: outside, category: cat),
        ]
        let stats = WeekStatistics(sessions: sessions, categories: [cat],
                                   weekOffset: 0,
                                   today: inside,
                                   calendar: Self.utcCalendar)
        #expect(stats.weekTotal == 1)
        #expect(stats.total(for: cat) == 1)
    }
}
