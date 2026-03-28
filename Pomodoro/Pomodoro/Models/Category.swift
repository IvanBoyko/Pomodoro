//
//  Category.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import Foundation
import SwiftData

@Model
final class PomodoroCategory {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \PomodoroSession.category)
    var sessions: [PomodoroSession]

    init(name: String, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sessions = []
    }
}
