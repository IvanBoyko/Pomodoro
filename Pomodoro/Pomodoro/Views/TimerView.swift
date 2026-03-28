//
//  TimerView.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PomodoroSession.completedAt) private var allSessions: [PomodoroSession]

    @State private var timerVM = TimerViewModel()
    @State private var showCategories = false

    private var todaySessions: [PomodoroSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allSessions.filter { $0.completedAt >= startOfDay }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 260, height: 260)

                    Circle()
                        .trim(from: 0, to: timerVM.progress)
                        .stroke(
                            timerVM.isRunning ? Color.accentColor : Color.green,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerVM.progress)

                    VStack(spacing: 8) {
                        Text(timerVM.displayTime)
                            .font(.system(size: 56, weight: .thin, design: .monospaced))
                            .contentTransition(.numericText())

                        if !timerVM.isRunning && !timerVM.isCompleted {
                            Text("25 minutes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 20) {
                    if timerVM.isRunning {
                        Button(role: .destructive) {
                            timerVM.cancel()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            timerVM.start()
                        } label: {
                            Label("Start Pomodoro", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 32)

                VStack(spacing: 4) {
                    Text("\(todaySessions.count)")
                        .font(.title.bold())
                    Text("Pomodoros today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCategories = true
                    } label: {
                        Image(systemName: "tag")
                    }
                }
            }
            .sheet(isPresented: $showCategories) {
                CategoriesView()
            }
            .sheet(isPresented: $timerVM.showCategoryPicker) {
                CategoryPickerSheet(timerVM: timerVM)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                timerVM.recalculateOnForeground()
            }
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [PomodoroCategory.self, PomodoroSession.self], inMemory: true)
}
