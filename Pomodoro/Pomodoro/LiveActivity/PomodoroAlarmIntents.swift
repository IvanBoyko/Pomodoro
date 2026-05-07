#if canImport(AlarmKit)
import AlarmKit
import AppIntents
import Foundation

@available(iOS 26.1, *)
struct PomodoroAlarmStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Pomodoro Alarm"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: id)
        }
        return .result()
    }
}

@available(iOS 26.1, *)
struct PomodoroAlarmSecondaryIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or Resume Pomodoro"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else { return .result() }
        let alarms = try AlarmManager.shared.alarms
        guard let alarm = alarms.first(where: { $0.id == id }) else { return .result() }
        switch alarm.state {
        case .countdown: try AlarmManager.shared.pause(id: id)
        case .paused: try AlarmManager.shared.resume(id: id)
        default: break
        }
        return .result()
    }
}
#endif
