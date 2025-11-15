//
//  AccessibilitySpot.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Data model for accessibility spots
//

import Foundation
import MapKit
import SwiftUI

struct AccessibilitySpot: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var type: SpotType
    var status: SpotStatus
    var coordinate: CLLocationCoordinate2D
    var photo: UIImage?
    var createdAt: Date
    var distance: Double?

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AccessibilitySpot, rhs: AccessibilitySpot) -> Bool {
        lhs.id == rhs.id
    }

    init(id: UUID = UUID(),
         title: String,
         description: String,
         type: SpotType,
         status: SpotStatus,
         coordinate: CLLocationCoordinate2D,
         photo: UIImage? = nil,
         createdAt: Date = Date(),
         distance: Double? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.status = status
        self.coordinate = coordinate
        self.photo = photo
        self.createdAt = createdAt
        self.distance = distance
    }

    var statusColor: Color {
        switch status {
        case .working: return .green
        case .notWorking: return .red
        case .underMaintenance: return .orange
        }
    }

    func matchesFilter(_ filter: AccessibilityFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .wheelchair:
            return type == .ramp || type == .elevator || type == .accessibleEntrance
        case .stroller:
            return type == .ramp || type == .stepFreeRoute
        case .ramp:
            return type == .ramp
        case .elevator:
            return type == .elevator
        }
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, title, description, type, status, latitude, longitude, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        type = try container.decode(SpotType.self, forKey: .type)
        status = try container.decode(SpotStatus.self, forKey: .status)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        photo = nil
        distance = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Sample data
    static var sample: AccessibilitySpot {
        AccessibilitySpot(
            title: "Syntagma Square Ramp",
            description: "Wide ramp with handrails, well-maintained",
            type: .ramp,
            status: .working,
            coordinate: CLLocationCoordinate2D(latitude: 37.9755, longitude: 23.7348),
            distance: 150
        )
    }
}

enum SpotType: String, Codable, CaseIterable {
    case ramp = "Ramp"
    case elevator = "Elevator"
    case accessibleEntrance = "Accessible Entrance"
    case stepFreeRoute = "Step-Free Route"
    case accessibleParking = "Accessible Parking"
    case accessibleToilet = "Accessible Toilet"

    var emoji: String {
        switch self {
        case .ramp: return "📐"
        case .elevator: return "🛗"
        case .accessibleEntrance: return "🚪"
        case .stepFreeRoute: return "🛤️"
        case .accessibleParking: return "🅿️"
        case .accessibleToilet: return "🚻"
        }
    }
}

enum SpotStatus: String, Codable, CaseIterable {
    case working = "Working"
    case notWorking = "Not Working"
    case underMaintenance = "Under Maintenance"

    var icon: String {
        switch self {
        case .working: return "checkmark.circle.fill"
        case .notWorking: return "xmark.circle.fill"
        case .underMaintenance: return "wrench.and.screwdriver.fill"
        }
    }
}

enum AccessibilityFilter: String, CaseIterable {
    case all = "All"
    case wheelchair = "Wheelchair"
    case stroller = "Stroller"
    case ramp = "Ramps"
    case elevator = "Elevators"

    var emoji: String {
        switch self {
        case .all: return "🌍"
        case .wheelchair: return "♿"
        case .stroller: return "🍼"
        case .ramp: return "📐"
        case .elevator: return "🛗"
        }
    }
}
