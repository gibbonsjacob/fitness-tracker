//
//  HistoryView.swift
//  FitnessTracker
//

import SwiftUI
import SwiftData

private enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case running = "Running"
    case walking = "Walking"

    func matches(_ activity: CardioActivity) -> Bool {
        switch self {
        case .all:
            return true
        case .running:
            return activity.activityType == .running
        case .walking:
            return activity.activityType == .walking
        }
    }
}

struct HistoryView: View {
    @Query(sort: \CardioActivity.date, order: .reverse) private var activities: [CardioActivity]
    @Environment(\.modelContext) private var modelContext

    @State private var filter: HistoryFilter = .all

    private var filteredActivities: [CardioActivity] {
        activities.filter { filter.matches($0) }
    }

    private var summaryTitle: String {
        switch filter {
        case .all:
            "All Time"
        case .running:
            "All Time — Running"
        case .walking:
            "All Time — Walking"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(HistoryFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            AllTimeSummarySection(
                title: summaryTitle,
                activities: filteredActivities
            )
            .padding()

            if filteredActivities.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: "figure.run")
                } description: {
                    Text(emptyDescription)
                }
            } else {
                List {
                    ForEach(filteredActivities) { activity in
                        ActivityHistoryRow(activity: activity, showType: filter == .all)
                    }
                    .onDelete(perform: deleteActivities)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyTitle: String {
        switch filter {
        case .all:
            "No Activities Yet"
        case .running:
            "No Runs Yet"
        case .walking:
            "No Walks Yet"
        }
    }

    private var emptyDescription: String {
        switch filter {
        case .all:
            "Logged activities will appear here."
        case .running:
            "Your running history will appear here."
        case .walking:
            "Your walking history will appear here."
        }
    }

    private func deleteActivities(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredActivities[index])
        }

        try? modelContext.save()
    }
}

private struct AllTimeSummarySection: View {
    let title: String
    let activities: [CardioActivity]

    private var totalDistance: Double {
        CardioActivity.totalDistance(for: activities)
    }

    private var averagePace: String? {
        CardioActivity.averagePace(for: activities)
    }

    private var totalDuration: Double {
        CardioActivity.totalDuration(for: activities)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 16) {
                SummaryMetric(
                    title: "Distance",
                    value: CardioActivity.formatDistance(totalDistance)
                )
                SummaryMetric(
                    title: "Avg Pace",
                    value: averagePace ?? "—"
                )
            }

            HStack(spacing: 16) {
                SummaryMetric(
                    title: "Total Time",
                    value: CardioActivity.formatDuration(totalDuration)
                )
                SummaryMetric(
                    title: "Activities",
                    value: "\(activities.count)"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ActivityHistoryRow: View {
    let activity: CardioActivity
    let showType: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(activity.date, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.headline)

                Spacer()

                if showType {
                    Text(activity.activityType.label)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(activity.activityType == .running ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 12) {
                Label(CardioActivity.formatDistance(activity.distanceMiles), systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                Label(CardioActivity.formatDuration(activity.durationSeconds), systemImage: "clock")
                Label(activity.formattedPace, systemImage: "speedometer")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: CardioActivity.self, inMemory: true)
}
