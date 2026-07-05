//
//  WorkoutTracker.swift
//  FitnessTracker
//

import Foundation

struct CompletedWorkout: Identifiable, Hashable {
    let id = UUID()
    let activityType: ActivityType
    let durationSeconds: Double
    let distanceMiles: Double
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

    private let locationManager = WorkoutLocationManager()
    private var timerTask: Task<Void, Never>?
    private var workoutStartDate: Date?

    var distanceMiles: Double {
        locationManager.distanceMiles
    }

    var gpsStatusMessage: String {
        locationManager.statusMessage
    }

    var currentPace: String? {
        guard distanceMiles > 0, elapsedSeconds > 0 else { return nil }
        return CardioActivity.formatPace(secondsPerMile: elapsedSeconds / distanceMiles)
    }

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
        locationManager.startTracking()
        startTimer()
    }

    func pause() {
        guard phase == .active else { return }

        phase = .paused
        locationManager.pauseTracking()
        stopTimer()
    }

    func resume() {
        guard phase == .paused else { return }

        phase = .active
        locationManager.resumeTracking()
        startTimer()
    }

    func finish() -> CompletedWorkout? {
        stopTimer()
        locationManager.stopTracking()

        guard elapsedSeconds > 0 else {
            reset()
            return nil
        }

        let workout = CompletedWorkout(
            activityType: activityType,
            durationSeconds: elapsedSeconds,
            distanceMiles: distanceMiles,
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
        locationManager.reset()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, phase == .active else { continue }
                elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
