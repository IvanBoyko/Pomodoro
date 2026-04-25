//
//  PomodoroWidgetExtensionLiveActivity.swift
//  PomodoroWidgetExtension
//

import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock screen / banner UI
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text("Pomodoro")
                    .foregroundStyle(.secondary)
                Spacer()
                countdown(context.state)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Pomodoro", systemImage: "timer")
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context.state)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.orange)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                countdown(context.state)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func countdown(_ state: PomodoroActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(formatted(state.pausedRemaining))
        } else {
            Text(timerInterval: Date.now...state.endTime, countsDown: true)
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview("Lock Screen", as: .content, using: PomodoroActivityAttributes()) {
    PomodoroWidgetExtensionLiveActivity()
} contentStates: {
    PomodoroActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(23 * 60 + 4),
        isPaused: false,
        pausedRemaining: 23 * 60 + 4
    )
    PomodoroActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(15 * 60),
        isPaused: true,
        pausedRemaining: 15 * 60
    )
}
