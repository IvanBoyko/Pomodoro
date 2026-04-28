//
//  PomodoroActivityAttributesTests.swift
//  PomodoroTests
//

import Testing
import Foundation
@testable import Pomodoro

@Suite struct PomodoroActivityAttributesTests {
    @Test func contentStateRoundTripsThroughJSON() throws {
        let original = PomodoroActivityAttributes.ContentState(
            endTime: Date(timeIntervalSince1970: 1_700_000_000),
            isPaused: true,
            pausedRemaining: 837
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            PomodoroActivityAttributes.ContentState.self,
            from: data
        )

        #expect(decoded == original)
    }

    @Test func contentStatesWithSameFieldsAreEqual() {
        let endTime = Date(timeIntervalSince1970: 0)
        let a = PomodoroActivityAttributes.ContentState(
            endTime: endTime, isPaused: false, pausedRemaining: 1500)
        let b = PomodoroActivityAttributes.ContentState(
            endTime: endTime, isPaused: false, pausedRemaining: 1500)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func contentStatesDifferOnAnyField() {
        let endTime = Date(timeIntervalSince1970: 0)
        let base = PomodoroActivityAttributes.ContentState(
            endTime: endTime, isPaused: false, pausedRemaining: 1500)
        let differentTime = PomodoroActivityAttributes.ContentState(
            endTime: endTime.addingTimeInterval(1), isPaused: false, pausedRemaining: 1500)
        let differentPaused = PomodoroActivityAttributes.ContentState(
            endTime: endTime, isPaused: true, pausedRemaining: 1500)
        let differentRemaining = PomodoroActivityAttributes.ContentState(
            endTime: endTime, isPaused: false, pausedRemaining: 0)

        #expect(base != differentTime)
        #expect(base != differentPaused)
        #expect(base != differentRemaining)
    }
}
