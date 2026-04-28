//
//  ModelTests.swift
//  PomodoroTests
//

import Testing
import Foundation
@testable import Pomodoro

@Suite struct PomodoroCategoryTests {
    @Test func defaultsColorToBlue() {
        let category = PomodoroCategory(name: "Work")
        #expect(category.name == "Work")
        #expect(category.colorHex == "#007AFF")
        #expect(category.sessions.isEmpty)
    }

    @Test func acceptsCustomColor() {
        let category = PomodoroCategory(name: "Personal", colorHex: "#FF3B30")
        #expect(category.colorHex == "#FF3B30")
    }

    @Test func assignsUniqueIdsAcrossInstances() {
        let a = PomodoroCategory(name: "A")
        let b = PomodoroCategory(name: "B")
        #expect(a.id != b.id)
    }

    @Test func createdAtIsRecent() {
        let before = Date()
        let category = PomodoroCategory(name: "X")
        let after = Date()
        #expect(category.createdAt >= before)
        #expect(category.createdAt <= after)
    }
}

@Suite struct PomodoroSessionTests {
    @Test func storesProvidedDates() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(25 * 60)
        let session = PomodoroSession(startedAt: start, completedAt: end)

        #expect(session.startedAt == start)
        #expect(session.completedAt == end)
        #expect(session.category == nil)
    }

    @Test func canBeConstructedWithCategory() {
        let category = PomodoroCategory(name: "Deep Work")
        let session = PomodoroSession(startedAt: Date(),
                                      completedAt: Date(),
                                      category: category)
        #expect(session.category?.id == category.id)
    }

    @Test func assignsUniqueIdsAcrossInstances() {
        let a = PomodoroSession(startedAt: Date(), completedAt: Date())
        let b = PomodoroSession(startedAt: Date(), completedAt: Date())
        #expect(a.id != b.id)
    }
}
