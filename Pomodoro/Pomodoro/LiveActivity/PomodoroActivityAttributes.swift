//
//  PomodoroActivityAttributes.swift
//  Pomodoro
//
//  Shared between the main app and PomodoroWidgetExtension target.
//  In Xcode, this file's Target Membership must include both targets.
//

import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // Absolute moment the timer will fire. Used for the live-updating
        // countdown via Text(timerInterval:) so the system ticks every
        // second without the app needing to push updates.
        var endTime: Date
        var isPaused: Bool
        // Snapshot of remaining seconds at the moment of pausing,
        // used to render a static "MM:SS" while paused.
        var pausedRemaining: Int
    }
}
