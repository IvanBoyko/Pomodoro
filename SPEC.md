# Pomodoro Tracker - Technical Specification

## Overview
A native iOS app (SwiftUI + SwiftData) for tracking Pomodoro sessions throughout the day, categorizing them, and reviewing daily/weekly summaries.

## Target
- **Platform:** iOS 17+
- **Framework:** SwiftUI
- **Persistence:** SwiftData
- **Notifications:** UserNotifications (local)
- **Architecture:** MVVM

## Data Models

### Category
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| name | String | e.g. "Personal", "Work" |
| colorHex | String | Hex color for UI |
| createdAt | Date | |

### PomodoroSession
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| startedAt | Date | When timer started |
| completedAt | Date | When timer finished |
| category | Category? | Assigned after completion |

## Screens

### 1. Timer (Main Screen)
- Large circular countdown timer (25:00)
- Start / Pause / Resume / Cancel controls
- Shows current session count for today
- When timer completes: vibration + local notification + presents category assignment sheet

### 2. Category Assignment Sheet
- Presented modally after timer completes
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

### 5. Categories Management
- List of categories with color indicators
- Add / Edit / Delete categories
- Swipe-to-delete with confirmation

## Navigation
- TabView with 3 tabs: Timer, Daily Summary, Weekly Summary
- Categories accessible from a toolbar button on Timer tab

## Timer Behavior
- 25-minute countdown
- Runs via `Timer.scheduledTimer` with background time tracking (store start time, compute remaining on foreground)
- Local notification scheduled at start so it fires even if app is backgrounded
- Pause cancels the pending notification; resume reschedules it for the remaining time
- On completion: haptic feedback + sound + category assignment sheet

## Constraints
- No server / no accounts — all data local via SwiftData
- Pomodoro duration fixed at 25 minutes (no configuration needed for MVP)
