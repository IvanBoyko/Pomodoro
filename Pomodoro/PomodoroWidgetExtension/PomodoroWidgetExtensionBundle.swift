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
    }
}
