//
//  AnalyticsView.swift
//  FitnessTracker
//

import Charts
import SwiftUI
import SwiftData

private enum AnalyticsTimeframe: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct AnalyticsView: View {
    @Query(sort: \CardioActivity.date, order: .reverse) private var activities: [CardioActivity]

    @State private var activityType: ActivityType = .running
    @State private var timeframe: AnalyticsTimeframe = .weekly

    private var buckets: [PeriodSummary] {
        switch timeframe {
        case .weekly:
            ActivityAnalytics.weeklyBuckets(for: activityType, from: activities)
        case .monthly:
            ActivityAnalytics.monthlyBuckets(for: activityType, from: activities)
        }
    }

    private var periodSummary: PeriodSummary? {
        ActivityAnalytics.aggregate(buckets)
    }

    private var yearToDateSummary: PeriodSummary? {
        ActivityAnalytics.yearToDateSummary(for: activityType, from: activities)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Activity", selection: $activityType) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Timeframe", selection: $timeframe) {
                    ForEach(AnalyticsTimeframe.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if let periodSummary {
                    summarySection(
                        title: timeframe == .weekly ? "Last 8 Weeks" : "Last 6 Months",
                        summary: periodSummary
                    )
                }

                if let yearToDateSummary {
                    summarySection(title: "Year to Date", summary: yearToDateSummary)
                }

                chartSection
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distance by \(timeframe == .weekly ? "Week" : "Month")")
                .font(.headline)

            if buckets.allSatisfy({ $0.distanceMiles == 0 }) {
                ContentUnavailableView {
                    Label("No Data Yet", systemImage: "chart.bar")
                } description: {
                    Text("Log \(activityType.label.lowercased()) activities to see trends here.")
                }
                .frame(height: 220)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Period", bucket.label),
                        y: .value("Miles", bucket.distanceMiles)
                    )
                    .foregroundStyle(activityType == .running ? Color.blue : Color.green)
                    .cornerRadius(4)
                }
                .chartYAxisLabel("Miles")
                .frame(height: 220)

                bucketBreakdownList
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var bucketBreakdownList: some View {
        VStack(spacing: 8) {
            ForEach(buckets.reversed()) { bucket in
                if bucket.activityCount > 0 {
                    HStack {
                        Text(bucket.label)
                        Spacer()
                        Text(CardioActivity.formatDistance(bucket.distanceMiles))
                            .monospacedDigit()
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(bucket.averagePace ?? "—")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            }
        }
    }

    @ViewBuilder
    private func summarySection(title: String, summary: PeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 16) {
                AnalyticsMetric(title: "Distance", value: CardioActivity.formatDistance(summary.distanceMiles))
                AnalyticsMetric(title: "Avg Pace", value: summary.averagePace ?? "—")
            }

            HStack(spacing: 16) {
                AnalyticsMetric(title: "Total Time", value: CardioActivity.formatDuration(summary.durationSeconds))
                AnalyticsMetric(title: "Activities", value: "\(summary.activityCount)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct AnalyticsMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
    .modelContainer(for: CardioActivity.self, inMemory: true)
}
