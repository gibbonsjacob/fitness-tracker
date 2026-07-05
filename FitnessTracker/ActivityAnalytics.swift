//
//  ActivityAnalytics.swift
//  FitnessTracker
//

import Foundation

struct PeriodSummary: Identifiable {
    let id: Date
    let label: String
    let distanceMiles: Double
    let durationSeconds: Double
    let activityCount: Int

    var averagePace: String? {
        guard distanceMiles > 0, durationSeconds > 0 else { return nil }
        return CardioActivity.formatPace(secondsPerMile: durationSeconds / distanceMiles)
    }
}

enum ActivityAnalytics {
    static func weeklyBuckets(
        for type: ActivityType,
        from activities: [CardioActivity],
        weekCount: Int = 8,
        calendar: Calendar = .current
    ) -> [PeriodSummary] {
        guard let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return []
        }

        return (0..<weekCount).reversed().compactMap { offset in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: startOfCurrentWeek),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return nil
            }

            let periodActivities = activities.filter { activity in
                activity.activityType == type &&
                activity.date >= weekStart &&
                activity.date < weekEnd
            }

            let label = weekStart.formatted(.dateTime.month(.abbreviated).day())
            return makeSummary(
                start: weekStart,
                label: label,
                activities: periodActivities
            )
        }
    }

    static func monthlyBuckets(
        for type: ActivityType,
        from activities: [CardioActivity],
        monthCount: Int = 6,
        calendar: Calendar = .current
    ) -> [PeriodSummary] {
        guard let startOfCurrentMonth = calendar.dateInterval(of: .month, for: Date())?.start else {
            return []
        }

        return (0..<monthCount).reversed().compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: startOfCurrentMonth),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return nil
            }

            let periodActivities = activities.filter { activity in
                activity.activityType == type &&
                activity.date >= monthStart &&
                activity.date < monthEnd
            }

            let label = monthStart.formatted(.dateTime.month(.abbreviated))
            return makeSummary(
                start: monthStart,
                label: label,
                activities: periodActivities
            )
        }
    }

    static func yearToDateSummary(
        for type: ActivityType,
        from activities: [CardioActivity],
        calendar: Calendar = .current
    ) -> PeriodSummary? {
        guard let yearStart = calendar.dateInterval(of: .year, for: Date())?.start else {
            return nil
        }

        let yearActivities = activities.filter { activity in
            activity.activityType == type && activity.date >= yearStart
        }

        guard !yearActivities.isEmpty else { return nil }

        return makeSummary(
            start: yearStart,
            label: "Year to Date",
            activities: yearActivities
        )
    }

    static func aggregate(_ buckets: [PeriodSummary]) -> PeriodSummary? {
        guard buckets.contains(where: { $0.activityCount > 0 }) else { return nil }

        let distance = buckets.reduce(0) { $0 + $1.distanceMiles }
        let duration = buckets.reduce(0) { $0 + $1.durationSeconds }
        let count = buckets.reduce(0) { $0 + $1.activityCount }

        return PeriodSummary(
            id: buckets.first?.id ?? Date(),
            label: "Total",
            distanceMiles: distance,
            durationSeconds: duration,
            activityCount: count
        )
    }

    private static func makeSummary(
        start: Date,
        label: String,
        activities: [CardioActivity]
    ) -> PeriodSummary {
        PeriodSummary(
            id: start,
            label: label,
            distanceMiles: CardioActivity.totalDistance(for: activities),
            durationSeconds: CardioActivity.totalDuration(for: activities),
            activityCount: activities.count
        )
    }
}
