//
//  ContentView.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            DailySummaryView()
                .tabItem {
                    Label("Today", systemImage: "chart.bar")
                }

            WeeklySummaryView()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PomodoroCategory.self, PomodoroSession.self], inMemory: true)
}
