//
//  WorkoutLocationManager.swift
//  FitnessTracker
//

import CoreLocation
import Foundation

@Observable
@MainActor
final class WorkoutLocationManager: NSObject {
    private static let metersPerMile = 1_609.344
    private static let maxHorizontalAccuracy = 50.0

    var distanceMiles: Double = 0
    var authorizationStatus: CLAuthorizationStatus
    var isTracking = false
    private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var accumulatedDistanceMeters: Double = 0
    private var pendingTrackingStart = false

    var statusMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission required"
        case .denied, .restricted:
            return "Location access denied"
        case .authorizedWhenInUse, .authorizedAlways:
            if !isTracking {
                return pendingTrackingStart ? "Waiting for location permission..." : "GPS ready"
            }
            return lastLocation == nil ? "Acquiring GPS..." : "GPS active"
        @unknown default:
            return "GPS unavailable"
        }
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    override init() {
        authorizationStatus = .notDetermined
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func startTracking() {
        switch manager.authorizationStatus {
        case .notDetermined:
            pendingTrackingStart = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginTracking()
        default:
            pendingTrackingStart = false
        }
    }

    func pauseTracking() {
        isTracking = false
        configureBackgroundUpdates(enabled: false)
        manager.stopUpdatingLocation()
    }

    func resumeTracking() {
        guard isAuthorized else { return }

        lastLocation = nil
        isTracking = true
        configureBackgroundUpdates(enabled: true)
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        pendingTrackingStart = false
        isTracking = false
        configureBackgroundUpdates(enabled: false)
        manager.stopUpdatingLocation()
    }

    func reset() {
        stopTracking()
        lastLocation = nil
        accumulatedDistanceMeters = 0
        distanceMiles = 0
        routeCoordinates = []
    }

    private func beginTracking() {
        lastLocation = nil
        accumulatedDistanceMeters = 0
        distanceMiles = 0
        routeCoordinates = []
        isTracking = true
        configureBackgroundUpdates(enabled: true)
        manager.startUpdatingLocation()
    }

    private func configureBackgroundUpdates(enabled: Bool) {
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let canUseBackgroundLocation = backgroundModes.contains("location")

        if enabled && canUseBackgroundLocation {
            manager.showsBackgroundLocationIndicator = true
            manager.allowsBackgroundLocationUpdates = true
        } else {
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
        }
    }

    private func processLocation(_ location: CLLocation) {
        guard isTracking else { return }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= Self.maxHorizontalAccuracy else {
            return
        }

        routeCoordinates.append(location.coordinate)

        if let lastLocation {
            let segmentMeters = location.distance(from: lastLocation)
            guard segmentMeters > 0 else { return }
            accumulatedDistanceMeters += segmentMeters
            distanceMiles = accumulatedDistanceMeters / Self.metersPerMile
        }

        lastLocation = location
    }

    private func handleAuthorizationChange(for manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        guard pendingTrackingStart else { return }

        if isAuthorized {
            pendingTrackingStart = false
            beginTracking()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            pendingTrackingStart = false
        }
    }
}

extension WorkoutLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [location] in
            processLocation(location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            handleAuthorizationChange(for: manager)
        }
    }
}
