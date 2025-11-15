//
//  LocationManager.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Manages user location and map positioning
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275), // Athens center
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private var shouldAutoUpdate = false // Don't auto-update map position

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        // Don't start continuous updates - only get location when requested
    }

    func requestLocation() {
        shouldAutoUpdate = true
        locationManager.requestLocation()
    }

    func updateRegion(center: CLLocationCoordinate2D, updateCamera: Bool = true) {
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        if updateCamera {
            cameraPosition = .region(region)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.userLocation = location.coordinate
            // Only update region and camera if user requested it
            if self.shouldAutoUpdate {
                self.updateRegion(center: location.coordinate, updateCamera: true)
                self.shouldAutoUpdate = false
            } else {
                // Just update the region data without moving the camera
                self.updateRegion(center: location.coordinate, updateCamera: false)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
