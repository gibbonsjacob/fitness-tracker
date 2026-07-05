//
//  WorkoutRouteMapView.swift
//  FitnessTracker
//

import MapKit
import SwiftUI

struct WorkoutRouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Map(initialPosition: mapPosition) {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.blue, lineWidth: 4)
            } else if let coordinate = coordinates.first {
                Marker("Start", coordinate: coordinate)
            }
        }
        .mapStyle(.standard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var mapPosition: MapCameraPosition {
        guard !coordinates.isEmpty else {
            return .automatic
        }

        return .region(Self.region(containing: coordinates))
    }

    static func region(containing coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for coordinate in coordinates {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.4, 0.005),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.4, 0.005)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    WorkoutRouteMapView(
        coordinates: [
            CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            CLLocationCoordinate2D(latitude: 37.3359, longitude: -122.0080),
            CLLocationCoordinate2D(latitude: 37.3369, longitude: -122.0070),
        ]
    )
    .frame(height: 200)
    .padding()
}
