//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

#if canImport(AlarmKit)
import AlarmKit
#endif
import SwiftUI
import SwiftData
import UserNotifications

@main
struct PomodoroApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PomodoroCategory.self,
            PomodoroSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
                    #if canImport(AlarmKit)
                    if #available(iOS 26.1, *) {
                        Task {
                            do {
                                let state = try await AlarmManager.shared.requestAuthorization()
                                print("AlarmKit authorization: \(state)")
                            } catch {
                                print("AlarmKit authorization request failed: \(error)")
                            }
                        }
                        Task {
                            for await alarms in AlarmManager.shared.alarmUpdates {
                                print("AlarmKit alarms: \(alarms.map { "\($0.id.uuidString.prefix(8))=\($0.state)" })")
                            }
                        }
                    }
                    #endif
                    TimerViewModel.endAllPomodoroActivities()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound])
    }
}
