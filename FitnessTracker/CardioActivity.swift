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
}
