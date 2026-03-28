//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PomodoroApp: App {
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
                    requestNotificationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
}
