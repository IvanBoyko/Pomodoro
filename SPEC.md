# Pomodoro Tracker - Technical Specification

## Overview
A native iOS app (SwiftUI + SwiftData) for tracking Pomodoro sessions throughout the day, categorizing them, and reviewing daily/weekly summaries. A Live Activity mirrors the running timer on the lock screen and Dynamic Island, like the official iOS Timer app.

## Target
- **Platform:** iOS 17+
- **Framework:** SwiftUI
- **Persistence:** SwiftData
- **Notifications:** UserNotifications (`.timeSensitive`) on iOS < 26.1; AlarmKit timer alarm on iOS 26.1+
- **Live Activity:** ActivityKit, rendered by a Widget Extension target (`PomodoroWidgetExtension`)
- **Architecture:** MVVM

## Data Models

### PomodoroCategory
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| name | String | e.g. "Personal", "Work" |
| colorHex | String | Hex color for UI |
| createdAt | Date | |
| sessions | [PomodoroSession] | Reverse relationship; delete rule = `.nullify` (sessions survive when their category is deleted) |

### PomodoroSession
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| startedAt | Date | When timer started |
| completedAt | Date | When timer finished |
| category | PomodoroCategory? | Assigned after completion |

### PomodoroActivityAttributes (ActivityKit)
Shared between the main app and the widget extension.

| Field | Type | Notes |
|-------|------|-------|
| ContentState.endTime | Date | Absolute time the timer will fire; lets the lock-screen view tick via `Text(timerInterval:)` without per-second app updates |
| ContentState.isPaused | Bool | |
| ContentState.pausedRemaining | Int | Seconds left at the moment of pausing; used to render a static "MM:SS" while paused |

## Screens

### 1. Timer (Main Screen)
- Large circular countdown timer (25:00)
- Start / Pause / Resume / Cancel controls
- Shows current session count for today
- When timer completes: vibration + local notification + presents category assignment sheet

### 2. Category Assignment Sheet
- Presented modally after timer completes
- Non-dismissable by swipe — user must pick a category (or create one)
- List of existing categories to pick from
- Option to create a new category inline
- Tapping a category saves the session and dismisses

### 3. Daily Summary
- Date picker to select any day (defaults to today)
- Total Pomodoros completed and total minutes focused
- Breakdown per category (name + count)
- Distribution bar showing relative category share

### 4. Weekly Summary
- 7-day table (Mon-Sun) for the selected week
- Previous/next week navigation (next disabled when on current week)
- Rows = categories, Columns = days
- Cell = count of Pomodoros
- Bottom row = daily totals
- Right column = category totals
- Category-name column is twice the width of each day column (proportional, scales with orientation) so longer names fit without truncation

### 5. Categories Management
- List of categories with color indicators
- Add / Edit / Delete categories
- Swipe-to-delete with confirmation

### 6. Lock Screen / Dynamic Island (Live Activity)
- Pill on the lock screen shows "Pomodoro" label and live countdown (e.g. `22:32`)
- Dynamic Island compact and expanded variants show the same countdown
- No interactive controls (Pause/Cancel) yet — see TODO.md
- Activity is dismissed immediately on cancel and on completion (so it doesn't visually clash with the "Pomodoro Complete!" notification)

## Navigation
- TabView with 3 tabs: Timer, Today, Week
- Categories accessible from a toolbar button on Timer tab

## Timer Behavior
- 25-minute countdown
- Runs via `Timer.scheduledTimer` with background time tracking (store start time, compute remaining on foreground)
- Local notification scheduled at start so it fires even if app is backgrounded
- Live Activity is started at the same time and ended on cancel/complete
- Pause cancels the pending notification and updates the Live Activity to paused state; resume reschedules the notification for the remaining time and updates the activity back to running
- On completion: haptic feedback + sound + category assignment sheet + Live Activity ends immediately
- Foreground notifications suppress the banner and play sound only (the in-app category picker already conveys completion visually)
- Orphan Live Activity cleanup: at app launch and before starting a new timer, any pre-existing `PomodoroActivityAttributes` activities are ended. Defends against crashes / force-quits / `TimerViewModel` deallocation that would leave a stale countdown on the lock screen.

## Notifications
The app picks one of two completion-alert paths at runtime, gated on iOS version:

**iOS 26.1+ — AlarmKit timer alarm.** Scheduled via `AlarmManager.shared.schedule(id:configuration:)` using `AlarmConfiguration.timer(...)`. Requires `NSAlarmKitUsageDescription` (set via `INFOPLIST_KEY_NSAlarmKitUsageDescription` in `project.pbxproj`) and runtime user authorization, both requested at app launch alongside the `UNUserNotificationCenter` authorization. AlarmKit alarms ring through every Focus mode by design — this is the path that closes the Sleep/Personal-Focus gap that plain notifications can't.

**iOS < 26.1 — `.timeSensitive` local notification.** Delivered via `UNNotificationInterruptionLevel.timeSensitive`, the strongest tier available to third-party apps. Breaks through Do Not Disturb when the user keeps the per-Focus "Time-Sensitive Notifications" toggle on (the default). Requires the `com.apple.developer.usernotifications.time-sensitive` entitlement (`Pomodoro/Pomodoro.entitlements`); paid Apple Developer Program required. Stays silent in Sleep/Personal Focus when those Focus modes have Time-Sensitive disabled at the iOS level.

Only one path schedules per timer. On iOS 26.1+ devices the `.timeSensitive` notification is not used (don't ride both pipelines). The Live Activity is unchanged on both paths — it remains the custom `PomodoroActivityAttributes` activity. Critical Alerts (silent-mode bypass) are intentionally not used: separate Apple approval is granted only for safety/medical/severe-weather use cases.

When the user is in the foreground and `complete()` runs before the alarm fires, the pending alarm/notification is cancelled to avoid a duplicate ring.

## Constraints
- No server / no accounts — all data local via SwiftData
- Pomodoro duration fixed at 25 minutes (debug builds may override via the `POMODORO_DURATION` env var — see README)
- Only one Pomodoro at a time. Aligned with the Pomodoro Technique principle (one task per Pomodoro); also simplifies the Live Activity model — orphan cleanup can safely end *all* existing activities without identifying which one belongs to "this" timer.
