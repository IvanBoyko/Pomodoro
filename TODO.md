# High-level TODO list

## FEATURE: Allow timer notifications even on DND mode, imitate official iOS timer app
(Blocked: requires paid Apple Developer Program — Time Sensitive Notifications entitlement)

## FEATURE: Add Pause and Cancel buttons to the lock screen timer, like the official iOS timer app

## TEST: Retrospectively cover code with automated tests, run them in CI

## BUG: Completion haptic plays only on the first Pomodoro; subsequent completions fail silently
On the 2nd and 3rd completion in the same app session the haptic doesn't fire and Xcode logs `CHHapticEngine … Player start failed (error 2003329396)` per completion. Hypothesis: a fresh `CHHapticEngine` is created on every completion without stopping the previous one, so the audio session is still held by the prior engine when `engine.start` runs and the player never plays. Likely fix: hold a single engine for the view-model's lifetime and reuse it instead of allocating a new one each time.
