//
//  TimerViewModelTests.swift
//  PomodoroTests
//

import Testing
import Foundation
@testable import Pomodoro

@MainActor
@Suite struct TimerViewModelTests {
    private final class Clock {
        var now: Date
        init(_ start: Date) { self.now = start }
        func provider() -> () -> Date { { [weak self] in self?.now ?? Date() } }
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    private static func makeVM(duration: TimeInterval = 60) -> (TimerViewModel, Clock) {
        let clock = Clock(Date(timeIntervalSince1970: 1_700_000_000))
        let vm = TimerViewModel(now: clock.provider(), duration: duration)
        return (vm, clock)
    }

    // MARK: - Initial state

    @Test func initialStateIsIdle() {
        let (vm, _) = Self.makeVM()
        #expect(vm.isRunning == false)
        #expect(vm.isPaused == false)
        #expect(vm.isCompleted == false)
        #expect(vm.showCategoryPicker == false)
        #expect(vm.remainingSeconds == 60)
        #expect(vm.completedStartDate == nil)
        #expect(vm.completedEndDate == nil)
    }

    // MARK: - displayTime

    @Test func displayTimeFormatsRemainingMinutesAndSeconds() {
        let (vm, _) = Self.makeVM(duration: 25 * 60)
        vm.remainingSeconds = 25 * 60
        #expect(vm.displayTime == "25:00")
        vm.remainingSeconds = 65
        #expect(vm.displayTime == "01:05")
        vm.remainingSeconds = 9
        #expect(vm.displayTime == "00:09")
        vm.remainingSeconds = 0
        #expect(vm.displayTime == "00:00")
    }

    // MARK: - progress

    @Test func progressIsZeroAtStartAndOneAtEnd() {
        let (vm, _) = Self.makeVM(duration: 100)
        vm.remainingSeconds = 100
        #expect(vm.progress == 0.0)
        vm.remainingSeconds = 50
        #expect(vm.progress == 0.5)
        vm.remainingSeconds = 0
        #expect(vm.progress == 1.0)
    }

    // MARK: - start / cancel

    @Test func startTransitionsToRunningAndRecordsStartDate() {
        let (vm, clock) = Self.makeVM()
        vm.start()
        #expect(vm.isRunning == true)
        #expect(vm.isCompleted == false)
        #expect(vm.completedStartDate == clock.now)
        vm.cancel()
    }

    @Test func startIsNoOpWhenAlreadyRunning() {
        let (vm, clock) = Self.makeVM()
        vm.start()
        let firstStart = vm.completedStartDate
        clock.advance(5)
        vm.start()
        #expect(vm.completedStartDate == firstStart)
        vm.cancel()
    }

    @Test func cancelResetsAllState() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        vm.remainingSeconds = 30
        vm.cancel()
        #expect(vm.isRunning == false)
        #expect(vm.isPaused == false)
        #expect(vm.isCompleted == false)
        #expect(vm.remainingSeconds == 60)
        #expect(vm.completedStartDate == nil)
    }

    // MARK: - pause / resume

    @Test func pauseGuardsAgainstNonRunningState() {
        let (vm, _) = Self.makeVM()
        vm.pause()
        #expect(vm.isPaused == false)
        #expect(vm.isRunning == false)
    }

    @Test func pauseTransitionsRunningToPaused() {
        let (vm, _) = Self.makeVM()
        vm.start()
        vm.pause()
        #expect(vm.isRunning == false)
        #expect(vm.isPaused == true)
        vm.cancel()
    }

    @Test func resumeGuardsAgainstNonPausedState() {
        let (vm, _) = Self.makeVM()
        vm.resume()
        #expect(vm.isRunning == false)
    }

    @Test func resumeRestoresRunningState() {
        let (vm, _) = Self.makeVM()
        vm.start()
        vm.pause()
        vm.resume()
        #expect(vm.isRunning == true)
        #expect(vm.isPaused == false)
        vm.cancel()
    }

    @Test func resumeAdjustsStartDateSoTickPreservesRemaining() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        clock.advance(20)
        vm.tick()
        #expect(vm.remainingSeconds == 40)
        vm.pause()

        clock.advance(120) // long pause
        vm.resume()
        // First tick after resume must still see ~40 seconds remaining
        vm.tick()
        #expect(vm.remainingSeconds == 40)
        vm.cancel()
    }

    // MARK: - resetAfterSave

    @Test func resetAfterSaveClearsCompletionFlags() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.isCompleted = true
        vm.showCategoryPicker = true
        vm.remainingSeconds = 0
        vm.resetAfterSave()
        #expect(vm.isCompleted == false)
        #expect(vm.showCategoryPicker == false)
        #expect(vm.remainingSeconds == 60)
    }

    // MARK: - tick / completion

    @Test func tickUpdatesRemainingFromInjectedClock() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        clock.advance(15)
        vm.tick()
        #expect(vm.remainingSeconds == 45)
        vm.cancel()
    }

    @Test func tickIsNoOpWhenNotRunning() {
        let (vm, clock) = Self.makeVM(duration: 60)
        clock.advance(10)
        vm.tick()
        #expect(vm.remainingSeconds == 60)
    }

    @Test func tickCompletesWhenElapsedReachesDuration() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        clock.advance(60)
        vm.tick()
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
        #expect(vm.remainingSeconds == 0)
        #expect(vm.showCategoryPicker == true)
        #expect(vm.completedEndDate != nil)
    }

    @Test func tickCompletesWhenElapsedExceedsDuration() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        clock.advance(120)
        vm.tick()
        #expect(vm.isCompleted == true)
    }

    // MARK: - recalculateOnForeground

    @Test func recalculateOnForegroundUpdatesRemaining() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        vm.alarmID = nil // exercise the pre-26.1 / no-AlarmKit fallback
        clock.advance(25)
        vm.recalculateOnForeground()
        #expect(vm.remainingSeconds == 35)
        vm.cancel()
    }

    @Test func recalculateOnForegroundCompletesPastDuration() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        vm.alarmID = nil // exercise the pre-26.1 / no-AlarmKit fallback
        clock.advance(75)
        vm.recalculateOnForeground()
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
        #expect(vm.remainingSeconds == 0)
    }

    @Test func recalculateOnForegroundIsNoOpWhenNotRunning() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.recalculateOnForeground()
        #expect(vm.isCompleted == false)
        #expect(vm.remainingSeconds == 60)
    }

    // Regression: paused via lock-screen Live Activity → app suspended past
    // the original deadline → unlock. The dormant local Timer used to fire
    // on resume and call complete() while AlarmKit was still paused, leaving
    // a stale paused alarm on the lock screen. With AlarmKit owning, the
    // elapsed-math fallback in recalculateOnForeground must NOT run.
    @Test func recalculateOnForegroundDefersToAlarmKitWhenAlarmIDSet() {
        guard #available(iOS 26.1, *) else { return }
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        // alarmID is set synchronously by start() on iOS 26.1+; force it
        // here to keep the test deterministic across simulator versions.
        if vm.alarmID == nil { vm.alarmID = UUID() }
        clock.advance(75)
        vm.recalculateOnForeground()
        #expect(vm.isCompleted == false)
        #expect(vm.remainingSeconds == 60)
        vm.cancel()
    }

    @Test func backgroundTransitionPreservesRunState() {
        let (vm, _) = Self.makeVM()
        vm.start()
        vm.backgroundTransition()
        #expect(vm.isRunning == true)
        #expect(vm.isPaused == false)
        vm.cancel()
    }

    // MARK: - syncFrom(alarmInfos:) — AlarmKit state-machine seam

    private static func alarmInfo(_ id: UUID,
                                  _ state: TimerViewModel.AlarmInfo.State,
                                  remaining: Int?) -> TimerViewModel.AlarmInfo {
        TimerViewModel.AlarmInfo(id: id, state: state, activityRemainingSeconds: remaining)
    }

    // Regression for the PR #14 bug: the Live Activity content state lagged at
    // `.countdown` while AlarmKit.Alarm.state had already transitioned to `.paused`.
    // The VM must trust AlarmInfo.state (authoritative) and pause locally even
    // when the rendering-side remaining value still looks like a running countdown.
    @Test func syncFromPausedStateStopsTimerEvenWhenRemainingLooksLikeRunning() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .paused, remaining: 42)])
        #expect(vm.isPaused == true)
        #expect(vm.isRunning == false)
        #expect(vm.remainingSeconds == 42)
        #expect(vm.timer == nil)
        #expect(vm.isCompleted == false)
        vm.cancel()
    }

    @Test func syncFromCountdownStateStartsTickWhenIdle() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        vm.backgroundTransition() // kill the tick timer
        let id = UUID()
        vm.alarmID = id
        #expect(vm.timer == nil)
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .countdown, remaining: 30)])
        #expect(vm.isRunning == true)
        #expect(vm.isPaused == false)
        #expect(vm.remainingSeconds == 30)
        #expect(vm.timer != nil)
        vm.cancel()
    }

    @Test func syncFromCountdownAfterPausedResumesTick() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .paused, remaining: 20)])
        #expect(vm.isPaused == true)
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .countdown, remaining: 20)])
        #expect(vm.isPaused == false)
        #expect(vm.isRunning == true)
        #expect(vm.timer != nil)
        vm.cancel()
    }

    @Test func syncFromAlertStateCompletesRegardlessOfRemaining() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        // Even if the activity hasn't caught up and still reports remaining > 0,
        // the alarm state alone is terminal.
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .alert, remaining: 5)])
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
    }

    @Test func syncFromRemainingZeroCompletes() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .countdown, remaining: 0)])
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
    }

    @Test func syncFromMissingActivityRemainingLeavesVMAlone() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        let runningBefore = vm.isRunning
        let remainingBefore = vm.remainingSeconds
        // Alarm exists but Live Activity hasn't attached yet (transient post-schedule).
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .paused, remaining: nil)])
        #expect(vm.isRunning == runningBefore)
        #expect(vm.remainingSeconds == remainingBefore)
        #expect(vm.isCompleted == false)
        vm.cancel()
    }

    @Test func syncFromAlarmGoneWhileRunningCompletes() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        // Empty alarms list — alarm removed from AlarmManager (user dismissed alert
        // UI from the lock screen, or external cancel). Drive completion in-app.
        vm.syncFrom(alarmInfos: [])
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
    }

    @Test func syncFromAlarmGoneWhilePausedCompletes() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        let id = UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .paused, remaining: 30)])
        vm.syncFrom(alarmInfos: [])
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
        #expect(vm.isPaused == false)
    }

    @Test func completeClearsPausedFlag() {
        // Regression: complete() previously left isPaused stuck at true if the
        // VM completed from the paused state (e.g. alarm dismissed externally
        // while paused). UI then showed a Resume button alongside the
        // "Pomodoro Complete" sheet — semantically contradictory.
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        vm.pause()
        #expect(vm.isPaused == true)
        let id = vm.alarmID ?? UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: []) // alarm gone → complete from paused
        #expect(vm.isPaused == false)
        #expect(vm.isCompleted == true)
    }

    @Test func syncFromAlarmGoneWhileIdleIsNoOp() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.alarmID = UUID() // pretend we still hold an ID but VM is idle
        vm.syncFrom(alarmInfos: [])
        #expect(vm.isCompleted == false)
        #expect(vm.isRunning == false)
        #expect(vm.isPaused == false)
    }

    @Test func syncFromWithoutAlarmIDIsNoOp() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.alarmID = nil
        let beforeRunning = vm.isRunning
        vm.syncFrom(alarmInfos: [Self.alarmInfo(UUID(), .paused, remaining: 10)])
        #expect(vm.isRunning == beforeRunning)
        #expect(vm.isCompleted == false)
    }

    @Test func syncFromOtherStateBehavesLikeCountdown() {
        // Forward-compat: any non-paused, non-alert state (e.g. `.scheduled`, or
        // a future AlarmKit case) is treated as running. The remaining-seconds
        // value still drives completion via `remaining <= 0`.
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        vm.backgroundTransition()
        let id = UUID()
        vm.alarmID = id
        vm.syncFrom(alarmInfos: [Self.alarmInfo(id, .other, remaining: 15)])
        #expect(vm.isRunning == true)
        #expect(vm.isPaused == false)
        #expect(vm.remainingSeconds == 15)
        vm.cancel()
    }

    @Test func syncFromListWithoutOurAlarmTreatsItAsGone() {
        let (vm, _) = Self.makeVM(duration: 60)
        vm.start()
        vm.alarmID = UUID()
        // If the alarms list contains other entries but not ours, our alarm is
        // effectively gone (same as an empty list).
        vm.syncFrom(alarmInfos: [Self.alarmInfo(UUID(), .paused, remaining: 5)])
        #expect(vm.isCompleted == true)
        #expect(vm.isRunning == false)
    }

    // MARK: - CategoryPickerSheet save contract (audit finding #5)

    @Test func resetAfterSaveDismissesPickerEvenWhenNeverStarted() {
        let (vm, _) = Self.makeVM()
        vm.showCategoryPicker = true
        vm.resetAfterSave()
        #expect(vm.showCategoryPicker == false)
        #expect(vm.completedStartDate == nil)
    }

    @Test func makeSessionReturnsNilBeforeAnyRun() {
        let (vm, _) = Self.makeVM()
        let cat = PomodoroCategory(name: "Work")
        #expect(vm.makeSession(category: cat) == nil)
    }

    @Test func makeSessionReturnsValidSessionAfterCompletion() {
        let (vm, clock) = Self.makeVM(duration: 60)
        let started = clock.now
        vm.start()
        clock.advance(60)
        vm.tick()
        let cat = PomodoroCategory(name: "Work")
        let session = vm.makeSession(category: cat)
        #expect(session?.startedAt == started)
        #expect(session?.completedAt == vm.completedEndDate)
        #expect(session?.category?.name == "Work")
    }

    @Test func makeSessionReturnsNilAfterCancel() {
        let (vm, clock) = Self.makeVM(duration: 60)
        vm.start()
        clock.advance(60)
        vm.tick()
        vm.cancel()
        let cat = PomodoroCategory(name: "Work")
        #expect(vm.makeSession(category: cat) == nil)
    }
}
