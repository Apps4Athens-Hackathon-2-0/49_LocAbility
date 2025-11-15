//
//  OpenStreetMapService.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Fetches accessibility data from OpenStreetMap
//

import Foundation
import CoreLocation

@MainActor
class OpenStreetMapService: ObservableObject {
    @Published var fetchedSpots: [AccessibilitySpot] = []
    @Published var isFetching = false
    @Published var error: String?

    // Overpass API endpoint for querying OpenStreetMap
    private let overpassEndpoint = "https://overpass-api.de/api/interpreter"

    /// Fetch accessibility features from OpenStreetMap around a location
    func fetchAccessibilityFeatures(around coordinate: CLLocationCoordinate2D, radius: Double = 1000) async {
        isFetching = true
        error = nil

        // Build Overpass QL query for accessibility features
        let query = buildOverpassQuery(lat: coordinate.latitude, lon: coordinate.longitude, radius: radius)

        guard let url = URL(string: overpassEndpoint) else {
            error = "Invalid URL"
            isFetching = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                error = "Server error"
                isFetching = false
                return
            }

            // Parse the response
            let spots = parseOverpassResponse(data)
            fetchedSpots = spots
            isFetching = false

        } catch {
            self.error = error.localizedDescription
            isFetching = false
        }
    }

    /// Build Overpass QL query for accessibility features
    private func buildOverpassQuery(lat: Double, lon: Double, radius: Double) -> String {
        """
        [out:json][timeout:25];
        (
          // Wheelchair accessible entrances
          node["entrance"="yes"]["wheelchair"="yes"](around:\(radius),\(lat),\(lon));

          // Wheelchair ramps
          node["highway"="steps"]["ramp:wheelchair"="yes"](around:\(radius),\(lat),\(lon));
          way["highway"="steps"]["ramp:wheelchair"="yes"](around:\(radius),\(lat),\(lon));

          // Elevators
          node["highway"="elevator"](around:\(radius),\(lat),\(lon));

          // Accessible parking
          node["amenity"="parking"]["wheelchair"="yes"](around:\(radius),\(lat),\(lon));
          way["amenity"="parking"]["wheelchair"="yes"](around:\(radius),\(lat),\(lon));

          // Accessible toilets
          node["amenity"="toilets"]["wheelchair"="yes"](around:\(radius),\(lat),\(lon));

          // Tactile paving for visual impairment
          node["tactile_paving"="yes"](around:\(radius),\(lat),\(lon));
        );
        out body;
        >;
        out skel qt;
        """
    }

    /// Parse Overpass API response into AccessibilitySpot objects
    private func parseOverpassResponse(_ data: Data) -> [AccessibilitySpot] {
        var spots: [AccessibilitySpot] = []

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let elements = json["elements"] as? [[String: Any]] else {
                return []
            }

            for element in elements {
                guard let lat = element["lat"] as? Double,
                      let lon = element["lon"] as? Double,
                      let tags = element["tags"] as? [String: String] else {
                    continue
                }

                // Determine spot type based on OSM tags
                let (type, title) = determineSpotType(from: tags)

                let description = tags["description"] ??
                                 tags["note"] ??
                                 "Accessibility feature from OpenStreetMap"

                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                let spot = AccessibilitySpot(
                    title: title,
                    description: description,
                    type: type,
                    status: .working, // Assume working unless reported otherwise
                    coordinate: coordinate
                )

                spots.append(spot)
            }

        } catch {
            print("Failed to parse OSM data: \(error)")
        }

        return spots
    }

    /// Determine AccessibilitySpot type from OSM tags
    private func determineSpotType(from tags: [String: String]) -> (SpotType, String) {
        // Check for elevator
        if tags["highway"] == "elevator" {
            let name = tags["name"] ?? "Elevator"
            return (.elevator, name)
        }

        // Check for ramp
        if tags["ramp:wheelchair"] == "yes" || tags["ramp"] == "yes" {
            let name = tags["name"] ?? "Wheelchair Ramp"
            return (.ramp, name)
        }

        // Check for accessible entrance
        if tags["entrance"] == "yes" && tags["wheelchair"] == "yes" {
            let name = tags["name"] ?? "Accessible Entrance"
            return (.accessibleEntrance, name)
        }

        // Check for accessible parking
        if tags["amenity"] == "parking" && tags["wheelchair"] == "yes" {
            let name = tags["name"] ?? "Accessible Parking"
            return (.accessibleParking, name)
        }

        // Check for accessible toilet
        if tags["amenity"] == "toilets" && tags["wheelchair"] == "yes" {
            let name = tags["name"] ?? "Accessible Toilet"
            return (.accessibleToilet, name)
        }

        // Check for step-free path
        if tags["tactile_paving"] == "yes" {
            let name = tags["name"] ?? "Step-free Route"
            return (.stepFreeRoute, name)
        }

        // Default
        return (.accessibleEntrance, tags["name"] ?? "Accessible Feature")
    }
}
