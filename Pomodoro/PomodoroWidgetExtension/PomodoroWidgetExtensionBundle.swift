//
//  PomodoroWidgetExtensionBundle.swift
//  PomodoroWidgetExtension
//

import SwiftUI
import WidgetKit

@main
struct PomodoroWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        PomodoroWidgetExtensionLiveActivity()
        #if canImport(AlarmKit)
        if #available(iOS 26.1, *) {
            PomodoroAlarmLiveActivity()
        }
        #endif
    }
}
