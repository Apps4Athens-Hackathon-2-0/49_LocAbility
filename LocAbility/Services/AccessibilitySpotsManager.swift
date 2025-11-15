//
//  AccessibilitySpotsManager.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Manages accessibility spots data and scoring
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
class AccessibilitySpotsManager: ObservableObject {
    @Published var spots: [AccessibilitySpot] = []
    private let osmService = OpenStreetMapService()

    init() {
        loadSampleData()
    }

    // MARK: - OpenStreetMap Integration

    /// Fetch accessibility features from OpenStreetMap
    func fetchFromOpenStreetMap(around coordinate: CLLocationCoordinate2D) async {
        await osmService.fetchAccessibilityFeatures(around: coordinate, radius: 1000)

        // Merge OSM data with existing spots (avoid duplicates)
        for osmSpot in osmService.fetchedSpots {
            // Check if we already have a spot very close to this location
            let isDuplicate = spots.contains { existingSpot in
                coordinate.distance(to: existingSpot.coordinate) < 10 // Within 10 meters
            }

            if !isDuplicate {
                spots.append(osmSpot)
            }
        }

        print("✅ Fetched \(osmService.fetchedSpots.count) spots from OpenStreetMap")
    }

    // MARK: - Data Management

    func addSpot(_ spot: AccessibilitySpot) {
        spots.append(spot)
        saveSpots()

        // In production, sync with backend API
        // uploadToServer(spot)
    }

    func removeSpot(_ spot: AccessibilitySpot) {
        spots.removeAll { $0.id == spot.id }
        saveSpots()
    }

    func updateSpot(_ spot: AccessibilitySpot) {
        if let index = spots.firstIndex(where: { $0.id == spot.id }) {
            spots[index] = spot
            saveSpots()
        }
    }

    // MARK: - Queries

    func getSpotsNear(location: CLLocationCoordinate2D, radius: Double) -> [AccessibilitySpot] {
        spots
            .map { spot in
                var updatedSpot = spot
                updatedSpot.distance = location.distance(to: spot.coordinate)
                return updatedSpot
            }
            .filter { ($0.distance ?? Double.infinity) <= radius }
            .sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }

    func calculateAreaScore(center: CLLocationCoordinate2D, radius: Double) -> Int {
        let nearbySpots = getSpotsNear(location: center, radius: radius)

        guard !nearbySpots.isEmpty else { return 0 }

        // Calculate score based on:
        // 1. Number of accessible features
        // 2. Variety of feature types
        // 3. Status of features (working vs not working)

        let totalSpots = nearbySpots.count
        let workingSpots = nearbySpots.filter { $0.status == .working }.count
        let uniqueTypes = Set(nearbySpots.map { $0.type }).count

        // Weighted scoring
        let quantityScore = min(totalSpots * 5, 40) // Max 40 points for quantity
        let qualityScore = Double(workingSpots) / Double(totalSpots) * 30 // Max 30 points for quality
        let varietyScore = uniqueTypes * 5 // Max 30 points for variety (6 types)

        let totalScore = Int(Double(quantityScore) + qualityScore + Double(varietyScore))
        return min(totalScore, 100)
    }

    // MARK: - Persistence

    private func saveSpots() {
        // In production, save to CoreData or CloudKit
        if let encoded = try? JSONEncoder().encode(spots) {
            UserDefaults.standard.set(encoded, forKey: "accessibility_spots")
        }
    }

    private func loadSpots() {
        if let data = UserDefaults.standard.data(forKey: "accessibility_spots"),
           let decoded = try? JSONDecoder().decode([AccessibilitySpot].self, from: data) {
            spots = decoded
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        spots = [
            AccessibilitySpot(
                title: "Syntagma Metro",
                description: "Elevator to all platforms, well-maintained and spacious",
                type: .elevator,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9755, longitude: 23.7348),
                distance: 100
            ),
            AccessibilitySpot(
                title: "Parliament Ramp",
                description: "Wide ramp with handrails on both sides",
                type: .ramp,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9756, longitude: 23.7350),
                distance: 120
            ),
            AccessibilitySpot(
                title: "Ermou Street Entrance",
                description: "Step-free entrance to shopping area",
                type: .accessibleEntrance,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9760, longitude: 23.7340),
                distance: 200
            ),
            AccessibilitySpot(
                title: "Monastiraki Elevator",
                description: "Currently out of service",
                type: .elevator,
                status: .notWorking,
                coordinate: CLLocationCoordinate2D(latitude: 37.9766, longitude: 23.7257),
                distance: 450
            ),
            AccessibilitySpot(
                title: "Plaka Accessible Route",
                description: "Step-free path through historic neighborhood",
                type: .stepFreeRoute,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9730, longitude: 23.7270),
                distance: 350
            ),
            AccessibilitySpot(
                title: "Acropolis Museum Ramp",
                description: "Modern ramp with automatic doors",
                type: .ramp,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9686, longitude: 23.7281),
                distance: 800
            ),
            AccessibilitySpot(
                title: "Accessible Parking Syntagma",
                description: "4 designated accessible parking spaces",
                type: .accessibleParking,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9753, longitude: 23.7345),
                distance: 90
            ),
            AccessibilitySpot(
                title: "Accessible Toilet - Syntagma",
                description: "Public accessible toilet, clean and spacious",
                type: .accessibleToilet,
                status: .working,
                coordinate: CLLocationCoordinate2D(latitude: 37.9758, longitude: 23.7351),
                distance: 110
            )
        ]
    }
}

// MARK: - Coordinate Distance Extension

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
}
