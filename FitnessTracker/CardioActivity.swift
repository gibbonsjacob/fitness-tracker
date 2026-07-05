//
//  CardioActivity.swift
//  FitnessTracker
//

import Foundation
import SwiftData

enum ActivityType: String, Codable, CaseIterable {
    case running
    case walking

    var label: String {
        switch self {
        case .running: "Running"
        case .walking: "Walking"
        }
    }
}

@Model
final class CardioActivity {
    var activityType: ActivityType
    var distanceMiles: Double
    var durationSeconds: Double
    var date: Date

    init(
        activityType: ActivityType,
        distanceMiles: Double,
        durationSeconds: Double,
        date: Date
    ) {
        self.activityType = activityType
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
        self.date = date
    }
}

extension CardioActivity {
    static func activitiesThisMonth(
        for type: ActivityType,
        from activities: [CardioActivity]
    ) -> [CardioActivity] {
        let calendar = Calendar.current
        let now = Date()
        return activities.filter { activity in
            activity.activityType == type &&
            calendar.isDate(activity.date, equalTo: now, toGranularity: .month)
        }
    }

    static func totalDistance(for activities: [CardioActivity]) -> Double {
        activities.reduce(0) { $0 + $1.distanceMiles }
    }

    static func totalDuration(for activities: [CardioActivity]) -> Double {
        activities.reduce(0) { $0 + $1.durationSeconds }
    }

    static func averagePace(for activities: [CardioActivity]) -> String? {
        let totalDistance = activities.reduce(0) { $0 + $1.distanceMiles }
        let totalDuration = activities.reduce(0) { $0 + $1.durationSeconds }
        guard totalDistance > 0 else { return nil }
        return formatPace(secondsPerMile: totalDuration / totalDistance)
    }

    static func formatPace(secondsPerMile: Double) -> String {
        let minutes = Int(secondsPerMile) / 60
        let seconds = Int(secondsPerMile) % 60
        return String(format: "%d:%02d / mi", minutes, seconds)
    }

    static func formatDistance(_ miles: Double) -> String {
        String(format: "%.1f mi", miles)
    }

    static func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    static func formatDurationClock(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }

    var formattedPace: String {
        guard distanceMiles > 0 else { return "—" }
        return Self.formatPace(secondsPerMile: durationSeconds / distanceMiles)
    }
}
