//
//  ActiveWorkoutView.swift
//  FitnessTracker
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var tracker = WorkoutTracker()
    @State private var completedWorkout: CompletedWorkout?
    @State private var showDiscardConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            Picker("Type", selection: $tracker.activityType) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .disabled(tracker.isInProgress)

            Spacer()

            VStack(spacing: 8) {
                Text(statusLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(CardioActivity.formatDurationClock(tracker.elapsedSeconds))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer()

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
                        completedWorkout = tracker.finish()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
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
            Text("Your tracked time will not be saved.")
        }
        .navigationDestination(item: $completedWorkout) { workout in
            LogActivityView(
                initialActivityType: workout.activityType,
                initialDurationSeconds: workout.durationSeconds,
                initialDate: workout.date
            )
        }
        .animation(.default, value: tracker.phase)
        .animation(.default, value: tracker.elapsedSeconds)
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
}

#Preview {
    NavigationStack {
        ActiveWorkoutView()
    }
}
