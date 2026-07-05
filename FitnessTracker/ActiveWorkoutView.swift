//
//  ActiveWorkoutView.swift
//  FitnessTracker
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var tracker = WorkoutTracker()
    @State private var completedWorkout: CompletedWorkout?
    @State private var showDiscardConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Type", selection: $tracker.activityType) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(tracker.isInProgress)

                if !tracker.isInProgress {
                    Text(tracker.gpsStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if tracker.isInProgress {
                    WorkoutRouteMapView(coordinates: tracker.routeCoordinates)
                        .frame(height: 200)
                }

                VStack(spacing: 8) {
                    Text(statusLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CardioActivity.formatDurationClock(tracker.elapsedSeconds))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                if tracker.isInProgress {
                    HStack(spacing: 32) {
                        WorkoutMetric(
                            title: "Distance",
                            value: CardioActivity.formatDistance(tracker.distanceMiles)
                        )
                        WorkoutMetric(
                            title: "Pace",
                            value: tracker.currentPace ?? "—"
                        )
                    }

                    Text(tracker.gpsStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    if tracker.canStart {
                        Button("Start") {
                            tracker.start()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }

                    if tracker.canPause {
                        Button("Pause") {
                            tracker.pause()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }

                    if tracker.canResume {
                        Button("Resume") {
                            tracker.resume()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }

                    if tracker.canFinish {
                        Button("Finish") {
                            finishWorkout()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(tracker.isInProgress)
        .toolbar {
            if tracker.isInProgress {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDiscardConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog(
            "Discard this workout?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Workout", role: .destructive) {
                tracker.discard()
                dismiss()
            }
        } message: {
            Text("Your tracked time and distance will not be saved.")
        }
        .navigationDestination(item: $completedWorkout) { workout in
            LogActivityView(
                initialActivityType: workout.activityType,
                initialDurationSeconds: workout.durationSeconds,
                initialDistanceMiles: workout.distanceMiles > 0 ? workout.distanceMiles : nil,
                initialDate: workout.date
            )
        }
        .animation(.default, value: tracker.phase)
        .animation(.default, value: tracker.elapsedSeconds)
        .animation(.default, value: tracker.distanceMiles)
    }

    private var statusLabel: String {
        switch tracker.phase {
        case .ready:
            "Ready"
        case .active:
            "In Progress"
        case .paused:
            "Paused"
        }
    }

    private func finishWorkout() {
        guard let workout = tracker.finish() else { return }

        if workout.distanceMiles > 0 {
            saveWorkout(workout)
            dismiss()
        } else {
            completedWorkout = workout
        }
    }

    private func saveWorkout(_ workout: CompletedWorkout) {
        let activity = CardioActivity(
            activityType: workout.activityType,
            distanceMiles: workout.distanceMiles,
            durationSeconds: workout.durationSeconds,
            date: workout.date
        )
        activity.setRouteCoordinates(workout.routeCoordinates)
        modelContext.insert(activity)
        try? modelContext.save()
    }
}

private struct WorkoutMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }
}

#Preview {
    NavigationStack {
        ActiveWorkoutView()
    }
    .modelContainer(for: CardioActivity.self, inMemory: true)
}
