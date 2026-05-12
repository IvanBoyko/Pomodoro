//
//  TimerViewModel.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import ActivityKit
#if canImport(AlarmKit)
import AlarmKit
#endif
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

    private(set) var timer: Timer?
    private var startDate: Date?
    private var endDate: Date?
    private var hapticEngine: CHHapticEngine?
    private var liveActivity: Activity<PomodoroActivityAttributes>?
    var alarmID: UUID?
    private var alarmUpdatesTask: Task<Void, Never>?

    /// Test-friendly mirror of AlarmKit's `Alarm` + `Activity.content.state` —
    /// captures the authoritative `Alarm.state` (paused/running/alert/other) and the
    /// rendering-side remaining-seconds value separately, so the divergence between
    /// the two during pause/resume transitions can be exercised in unit tests.
    struct AlarmInfo: Equatable {
        enum State: Equatable {
            case countdown
            case paused
            case alert
            /// Any state we don't model explicitly (forward-compatibility for future
            /// AlarmKit cases). Treated as non-paused for state transitions; relies
            /// on `activityRemainingSeconds` for timing.
            case other
        }
        let id: UUID
        let state: State
        /// Remaining seconds derived from `Activity.content.state.mode`. `nil` when
        /// no Activity is attached for this alarm yet (transient post-schedule state).
        let activityRemainingSeconds: Int?
    }

    init(now: @escaping () -> Date = Date.init,
         duration: TimeInterval = TimerViewModel.pomodoroDuration) {
        self.now = now
        self.duration = duration
        self.remainingSeconds = Int(duration)

        #if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            alarmUpdatesTask = Task { @MainActor [weak self] in
                for await alarms in AlarmManager.shared.alarmUpdates {
                    self?.syncFromAlarmKit(alarms: alarms)
                }
            }
        }
        #endif
    }

    deinit {
        alarmUpdatesTask?.cancel()
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

    /// On iOS 26.1+, the AlarmKit alarm IS the Live Activity surface — the custom
    /// PomodoroActivityAttributes activity must not be started in parallel.
    private var alarmKitOwnsLiveActivity: Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *) { return true }
        #endif
        return false
    }

    func start() {
        guard !isRunning else { return }
        Self.endAllPomodoroActivities()
        isRunning = true
        isCompleted = false
        startDate = now()
        endDate = nil
        remainingSeconds = Int(duration)

        scheduleNotification()
        if !alarmKitOwnsLiveActivity {
            startLiveActivity(endTime: now().addingTimeInterval(duration))
        }

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
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *), let id = alarmID {
            do {
                try AlarmManager.shared.pause(id: id)
            } catch {
                print("AlarmKit pause failed: \(error)")
            }
            return
        }
        #endif
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

        #if canImport(AlarmKit)
        if #available(iOS 26.1, *), let id = alarmID {
            do {
                try AlarmManager.shared.resume(id: id)
            } catch {
                print("AlarmKit resume failed: \(error)")
            }
            startTickTimer()
            return
        }
        #endif
        scheduleNotification(in: TimeInterval(remainingSeconds))
        updateLiveActivity(endTime: now().addingTimeInterval(TimeInterval(remainingSeconds)),
                           isPaused: false)
        startTickTimer()
    }

    private func startTickTimer() {
        guard timer == nil else { return }
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
        if !alarmKitOwnsLiveActivity {
            endLiveActivity()
        }
    }

    func resetAfterSave() {
        isCompleted = false
        showCategoryPicker = false
        remainingSeconds = Int(duration)
    }

    func makeSession(category: PomodoroCategory) -> PomodoroSession? {
        guard let start = startDate, let end = endDate else { return nil }
        return PomodoroSession(startedAt: start, completedAt: end, category: category)
    }

    /// Stop the per-second UI tick when leaving foreground. AlarmKit (or the
    /// pre-26.1 local notification + custom Live Activity) drives countdown
    /// and completion in the background; the next foreground enter re-establishes
    /// the tick from AlarmKit truth or elapsed time.
    func backgroundTransition() {
        stopTimer()
    }

    func recalculateOnForeground() {
        // Always invalidate first — a dormant Timer left over from foreground
        // could otherwise fire spuriously and race the AlarmKit-based sync below.
        stopTimer()

        guard isRunning || isPaused else { return }

        #if canImport(AlarmKit)
        if #available(iOS 26.1, *), alarmID != nil {
            // AlarmKit owns the timer. `alarmUpdates` (subscribed in init)
            // delivers the current state when the consumer Task resumes after
            // suspension, which calls syncFromAlarmKit. Don't perform a
            // synchronous AlarmKit IPC read here on the main thread, and
            // don't fall through to elapsed-based completion — that would
            // race the asynchronous sync.
            return
        }
        #endif

        guard isRunning, let start = startDate else { return }
        let elapsed = now().timeIntervalSince(start)
        let remaining = duration - elapsed
        if remaining <= 0 {
            complete()
        } else {
            remainingSeconds = Int(remaining)
            startTickTimer()
        }
    }

    /// Pure state-machine entry point. Drives VM state from a list of `AlarmInfo`
    /// values (one per known alarm). The framework-coupled `syncFromAlarmKit(alarms:)`
    /// adapter below converts AlarmKit's `Alarm` + Activity content into `AlarmInfo`
    /// and delegates here. Keeping this method free of framework types makes the
    /// state transitions exhaustively testable — see `TimerViewModelTests`.
    func syncFrom(alarmInfos: [AlarmInfo]) {
        guard let id = alarmID else { return }
        guard let info = alarmInfos.first(where: { $0.id == id }) else {
            if isRunning || isPaused {
                // Alarm removed from AlarmManager — user dismissed the alert UI
                // from the lock screen. Drive completion in the app.
                complete()
            }
            return
        }
        if info.state == .alert {
            // Terminal — the alarm has fired. Ignore any stale activity remaining.
            complete()
            return
        }
        guard let remaining = info.activityRemainingSeconds else {
            // Activity hasn't attached for this alarm yet (transient post-schedule
            // state). Leave the VM alone and wait for the next update.
            return
        }
        if remaining <= 0 {
            complete()
            return
        }
        applySnapshot(isPaused: info.state == .paused, remainingSeconds: remaining)
    }

    private func applySnapshot(isPaused: Bool, remainingSeconds: Int) {
        self.remainingSeconds = remainingSeconds
        if isPaused {
            stopTimer()
            isRunning = false
            self.isPaused = true
        } else {
            self.isPaused = false
            isRunning = true
            // Re-anchor startDate so subsequent tick() computes against AlarmKit's truth.
            startDate = now().addingTimeInterval(-(duration - Double(remainingSeconds)))
            startTickTimer()
        }
    }

    #if canImport(AlarmKit)
    @available(iOS 26.1, *)
    private func syncFromAlarmKit(alarms: [Alarm]) {
        let infos = alarms.map { alarm -> AlarmInfo in
            let state: AlarmInfo.State
            switch alarm.state {
            case .countdown: state = .countdown
            case .paused: state = .paused
            case .alerting: state = .alert
            case .scheduled: state = .other
            @unknown default: state = .other
            }
            return AlarmInfo(id: alarm.id,
                             state: state,
                             activityRemainingSeconds: activityRemainingSeconds(for: alarm.id))
        }
        syncFrom(alarmInfos: infos)
    }

    /// Reads remaining-seconds from the rendering surface (Live Activity content
    /// state). Authoritative paused/running comes from `Alarm.state` instead —
    /// the Activity content lags during pause/resume transitions.
    @available(iOS 26.1, *)
    private func activityRemainingSeconds(for id: UUID) -> Int? {
        for activity in Activity<AlarmAttributes<PomodoroAlarmMetadata>>.activities {
            let state = activity.content.state
            guard state.alarmID == id else { continue }
            switch state.mode {
            case .countdown(let countdown):
                return max(0, Int(countdown.fireDate.timeIntervalSince(now())))
            case .paused(let paused):
                return max(0, Int(paused.totalCountdownDuration - paused.previouslyElapsedDuration))
            case .alert:
                return 0
            @unknown default:
                return nil
            }
        }
        return nil
    }
    #endif

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
        isPaused = false
        isCompleted = true
        remainingSeconds = 0
        endDate = now()
        showCategoryPicker = true
        triggerCompletionHaptic()
        if !alarmKitOwnsLiveActivity {
            cancelNotification()
            endLiveActivity()
            return
        }
        // AlarmKit path: only suppress the alarm if the user is currently watching
        // the in-app countdown (foreground/active). If we're backgrounded or in the
        // middle of foregrounding (e.g. unlock after the alarm rang), leave AlarmKit
        // alone so its alerting state can run/finish naturally.
        if UIApplication.shared.applicationState == .active {
            cancelNotification()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNotification(in interval: TimeInterval? = nil) {
        let interval = interval ?? duration
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            scheduleAlarmKitTimer(in: interval)
            return
        }
        #endif
        scheduleLocalNotification(in: interval)
    }

    private func scheduleLocalNotification(in interval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = "Time to assign a category to your session."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

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

    #if canImport(AlarmKit)
    @available(iOS 26.1, *)
    private func scheduleAlarmKitTimer(in interval: TimeInterval) {
        let id = UUID()
        alarmID = id
        let pauseButton = AlarmButton(
            text: "Pause",
            textColor: .white,
            systemImageName: "pause.fill"
        )
        let resumeButton = AlarmButton(
            text: "Resume",
            textColor: .white,
            systemImageName: "play.fill"
        )
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(title: "Pomodoro Complete!"),
            countdown: AlarmPresentation.Countdown(title: "Pomodoro", pauseButton: pauseButton),
            paused: AlarmPresentation.Paused(title: "Pomodoro", resumeButton: resumeButton)
        )
        let attributes = AlarmAttributes<PomodoroAlarmMetadata>(
            presentation: presentation,
            tintColor: .accentColor
        )
        let config = AlarmManager.AlarmConfiguration.timer(
            duration: interval,
            attributes: attributes,
            stopIntent: PomodoroAlarmStopIntent(alarmID: id),
            secondaryIntent: PomodoroAlarmSecondaryIntent(alarmID: id)
        )
        Task { @MainActor [weak self] in
            do {
                _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            } catch {
                print("AlarmKit schedule failed (auth=\(AlarmManager.shared.authorizationState)): \(error)")
                if self?.alarmID == id { self?.alarmID = nil }
                return
            }
            // If the VM cleared/replaced our id while scheduling was in flight, cancel the orphan.
            if self?.alarmID != id {
                do {
                    try AlarmManager.shared.cancel(id: id)
                } catch {
                    print("AlarmKit cancel failed (orphan): \(error)")
                }
            }
        }
    }
    #endif

    private func triggerCompletionHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return
        }
        do {
            let engine = try ensureHapticEngine()
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
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptic pattern failed: \(error)")
        }
    }

    private func ensureHapticEngine() throws -> CHHapticEngine {
        if let engine = hapticEngine { return engine }
        let engine = try CHHapticEngine()
        engine.resetHandler = { [weak engine] in
            try? engine?.start()
        }
        engine.stoppedHandler = { [weak engine] _ in
            try? engine?.start()
        }
        try engine.start()
        hapticEngine = engine
        return engine
    }

    private func cancelNotification() {
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *), let id = alarmID {
            alarmID = nil
            do {
                try AlarmManager.shared.cancel(id: id)
            } catch {
                print("AlarmKit cancel failed: \(error)")
            }
            return
        }
        #endif
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomodoro-complete"])
    }

    static func endAllPomodoroActivities() {
        for activity in Activity<PomodoroActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            do {
                let alarms = try AlarmManager.shared.alarms
                for alarm in alarms {
                    do {
                        try AlarmManager.shared.cancel(id: alarm.id)
                    } catch {
                        print("AlarmKit cancel failed (cleanup): \(error)")
                    }
                }
            } catch {
                print("Failed to fetch alarms during cleanup: \(error)")
            }
        }
        #endif
    }

    private func startLiveActivity(endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
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
        } catch {
            print("Live Activity start failed: \(error)")
        }
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
