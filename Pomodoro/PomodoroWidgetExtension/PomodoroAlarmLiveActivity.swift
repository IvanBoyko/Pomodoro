#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 26.1, *)
struct PomodoroAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<PomodoroAlarmMetadata>.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text("Pomodoro")
                    .foregroundStyle(.secondary)
                Spacer()
                countdown(for: context.state)
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.orange)
                trailingButton(state: context.state, alarmID: context.state.alarmID)
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
                    countdown(for: context.state)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    trailingButton(state: context.state, alarmID: context.state.alarmID)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(.orange)
            } compactTrailing: {
                countdown(for: context.state).monospacedDigit().foregroundStyle(.orange)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func countdown(for state: AlarmPresentationState) -> some View {
        switch state.mode {
        case .countdown(let countdown):
            Text(timerInterval: countdown.startDate...countdown.fireDate, countsDown: true)
        case .paused(let paused):
            Text(formatted(Int(paused.totalCountdownDuration - paused.previouslyElapsedDuration)))
        case .alert:
            Text("00:00")
        @unknown default:
            Text("")
        }
    }

    @ViewBuilder
    private func trailingButton(state: AlarmPresentationState, alarmID: UUID) -> some View {
        switch state.mode {
        case .countdown:
            Button(intent: PomodoroAlarmSecondaryIntent(alarmID: alarmID)) {
                Image(systemName: "pause.fill")
            }
            .tint(.orange)
        case .paused:
            Button(intent: PomodoroAlarmSecondaryIntent(alarmID: alarmID)) {
                Image(systemName: "play.fill")
            }
            .tint(.orange)
        case .alert:
            Button(intent: PomodoroAlarmStopIntent(alarmID: alarmID)) {
                Image(systemName: "stop.fill")
            }
            .tint(.red)
        @unknown default:
            EmptyView()
        }
    }

    private func formatted(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
#endif
