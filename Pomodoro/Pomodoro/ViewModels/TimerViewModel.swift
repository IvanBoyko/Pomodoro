//
//  TimerViewModel.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import Foundation
import SwiftUI
import UserNotifications

@Observable
final class TimerViewModel {
    static let pomodoroDuration: TimeInterval = 25 * 60

    var remainingSeconds: Int = Int(TimerViewModel.pomodoroDuration)
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isCompleted: Bool = false
    var showCategoryPicker: Bool = false

    private var timer: Timer?
    private var startDate: Date?
    private var endDate: Date?

    var completedStartDate: Date? { startDate }
    var completedEndDate: Date? { endDate }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        1.0 - Double(remainingSeconds) / TimerViewModel.pomodoroDuration
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isCompleted = false
        startDate = Date()
        endDate = nil
        remainingSeconds = Int(TimerViewModel.pomodoroDuration)

        scheduleNotification()

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
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        isRunning = true
        // Shift startDate so elapsed-based tick gives the correct remaining time
        startDate = Date().addingTimeInterval(-(TimerViewModel.pomodoroDuration - Double(remainingSeconds)))
        scheduleNotification(in: TimeInterval(remainingSeconds))

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
        remainingSeconds = Int(TimerViewModel.pomodoroDuration)
        startDate = nil
        cancelNotification()
    }

    func resetAfterSave() {
        isCompleted = false
        showCategoryPicker = false
        remainingSeconds = Int(TimerViewModel.pomodoroDuration)
    }

    func recalculateOnForeground() {
        guard isRunning, let start = startDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        let remaining = TimerViewModel.pomodoroDuration - elapsed
        if remaining <= 0 {
            complete()
        } else {
            remainingSeconds = Int(remaining)
        }
    }

    private func tick() {
        guard isRunning else { return }
        guard let start = startDate else { return }

        let elapsed = Date().timeIntervalSince(start)
        let remaining = TimerViewModel.pomodoroDuration - elapsed

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
        endDate = Date()
        showCategoryPicker = true
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNotification(in interval: TimeInterval = TimerViewModel.pomodoroDuration) {
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

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomodoro-complete"])
    }
}
