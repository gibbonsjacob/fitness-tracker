//
//  ContentView.swift
//  FitnessTracker
//
//  Created by Jacob Gibbons on 5/31/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \CardioActivity.date, order: .reverse) private var activities: [CardioActivity]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cardio Tracker")
                    .font(.largeTitle)
                    .bold()

                metricSection(title: "Running", type: .running)
                metricSection(title: "Walking", type: .walking)

                Spacer()

                NavigationLink("Log Activity") {
                    LogActivityView()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func metricSection(title: String, type: ActivityType) -> some View {
        let monthActivities = CardioActivity.activitiesThisMonth(for: type, from: activities)
        let distance = CardioActivity.totalDistance(for: monthActivities)
        let pace = CardioActivity.averagePace(for: monthActivities)

        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("This Month: \(CardioActivity.formatDistance(distance))")
            Text("Avg Pace: \(pace ?? "—")")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CardioActivity.self, inMemory: true)
}
