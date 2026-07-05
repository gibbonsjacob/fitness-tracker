//
//  WorkoutTracker.swift
//  FitnessTracker
//

import Foundation

struct CompletedWorkout: Identifiable, Hashable {
    let id = UUID()
    let activityType: ActivityType
    let durationSeconds: Double
    let date: Date
}

@Observable
@MainActor
final class WorkoutTracker {
    enum Phase {
        case ready
        case active
        case paused
    }

    var activityType: ActivityType = .running
    var phase: Phase = .ready
    var elapsedSeconds: TimeInterval = 0

    private var timer: Timer?
    private var workoutStartDate: Date?

    var canStart: Bool {
        phase == .ready
    }

    var canPause: Bool {
        phase == .active
    }

    var canResume: Bool {
        phase == .paused
    }

    var canFinish: Bool {
        phase != .ready && elapsedSeconds > 0
    }

    var isInProgress: Bool {
        phase != .ready
    }

    var workoutDate: Date {
        workoutStartDate ?? Date()
    }

    func start() {
        guard phase == .ready else { return }

        workoutStartDate = Date()
        elapsedSeconds = 0
        phase = .active
        startTimer()
    }

    func pause() {
        guard phase == .active else { return }

        phase = .paused
        stopTimer()
    }

    func resume() {
        guard phase == .paused else { return }

        phase = .active
        startTimer()
    }

    func finish() -> CompletedWorkout? {
        stopTimer()

        guard elapsedSeconds > 0 else {
            reset()
            return nil
        }

        let workout = CompletedWorkout(
            activityType: activityType,
            durationSeconds: elapsedSeconds,
            date: workoutDate
        )
        reset()
        return workout
    }

    func discard() {
        stopTimer()
        reset()
    }

    private func reset() {
        phase = .ready
        elapsedSeconds = 0
        workoutStartDate = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .active else { return }
                self.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
