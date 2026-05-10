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
