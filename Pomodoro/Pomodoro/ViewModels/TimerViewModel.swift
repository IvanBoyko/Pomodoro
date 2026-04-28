//
//  TimerViewModel.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import ActivityKit
import CoreHaptics
import Foundation
import SwiftUI
import UIKit
import UserNotifications

@Observable
final class TimerViewModel {
    static let pomodoroDuration: TimeInterval = {
        #if DEBUG
        if let val = ProcessInfo.processInfo.environment["POMODORO_DURATION"],
           let seconds = TimeInterval(val) { return seconds }
        #endif
        return 25 * 60
    }()

    let duration: TimeInterval
    private let now: () -> Date

    var remainingSeconds: Int
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isCompleted: Bool = false
    var showCategoryPicker: Bool = false

    private var timer: Timer?
    private var startDate: Date?
    private var endDate: Date?
    private var hapticEngine: CHHapticEngine?
    private var hapticPlayer: CHHapticPatternPlayer?
    private var liveActivity: Activity<PomodoroActivityAttributes>?

    init(now: @escaping () -> Date = Date.init,
         duration: TimeInterval = TimerViewModel.pomodoroDuration) {
        self.now = now
        self.duration = duration
        self.remainingSeconds = Int(duration)
    }

    var completedStartDate: Date? { startDate }
    var completedEndDate: Date? { endDate }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        1.0 - Double(remainingSeconds) / duration
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isCompleted = false
        startDate = now()
        endDate = nil
        remainingSeconds = Int(duration)

        scheduleNotification()
        startLiveActivity(endTime: now().addingTimeInterval(duration))

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    func pause() {
        guard isRunning else { return }
        stopTimer()
        isRunning = false
        isPaused = true
        cancelNotification()
        updateLiveActivity(endTime: now().addingTimeInterval(TimeInterval(remainingSeconds)),
                           isPaused: true)
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        isRunning = true
        // Shift startDate so elapsed-based tick gives the correct remaining time
        startDate = now().addingTimeInterval(-(duration - Double(remainingSeconds)))
        scheduleNotification(in: TimeInterval(remainingSeconds))
        updateLiveActivity(endTime: now().addingTimeInterval(TimeInterval(remainingSeconds)),
                           isPaused: false)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }

    func cancel() {
        stopTimer()
        isRunning = false
        isPaused = false
        isCompleted = false
        remainingSeconds = Int(duration)
        startDate = nil
        cancelNotification()
        endLiveActivity()
    }

    func resetAfterSave() {
        isCompleted = false
        showCategoryPicker = false
        remainingSeconds = Int(duration)
    }

    func recalculateOnForeground() {
        guard isRunning, let start = startDate else { return }
        let elapsed = now().timeIntervalSince(start)
        let remaining = duration - elapsed
        if remaining <= 0 {
            complete()
        } else {
            remainingSeconds = Int(remaining)
        }
    }

    func tick() {
        guard isRunning else { return }
        guard let start = startDate else { return }

        let elapsed = now().timeIntervalSince(start)
        let remaining = duration - elapsed

        if remaining <= 0 {
            complete()
        } else {
            remainingSeconds = Int(remaining)
        }
    }

    private func complete() {
        stopTimer()
        isRunning = false
        isCompleted = true
        remainingSeconds = 0
        endDate = now()
        showCategoryPicker = true
        triggerCompletionHaptic()
        endLiveActivity()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNotification(in interval: TimeInterval? = nil) {
        let interval = interval ?? duration
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = "Time to assign a category to your session."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "pomodoro-complete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func triggerCompletionHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        do {
            let engine = try CHHapticEngine()
            hapticEngine = engine
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0, duration: 1.0
                ),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.3),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0.6),
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            hapticPlayer = player
            engine.start { [weak self] error in
                guard error == nil else { return }
                try? self?.hapticPlayer?.start(atTime: CHHapticTimeImmediate)
            }
        } catch {}
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomodoro-complete"])
    }

    static func endAllPomodoroActivities() {
        for activity in Activity<PomodoroActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private func startLiveActivity(endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        Self.endAllPomodoroActivities()
        let state = PomodoroActivityAttributes.ContentState(
            endTime: endTime,
            isPaused: false,
            pausedRemaining: Int(duration)
        )
        do {
            liveActivity = try Activity.request(
                attributes: PomodoroActivityAttributes(),
                content: .init(state: state, staleDate: nil)
            )
        } catch {}
    }

    private func updateLiveActivity(endTime: Date, isPaused: Bool) {
        guard let activity = liveActivity else { return }
        let state = PomodoroActivityAttributes.ContentState(
            endTime: endTime,
            isPaused: isPaused,
            pausedRemaining: remainingSeconds
        )
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        liveActivity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
