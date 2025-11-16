//
//  MapView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Interactive map showing accessibility points
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @Binding var selectedFilter: AccessibilityFilter
    @State private var selectedSpot: AccessibilitySpot?

    var filteredSpots: [AccessibilitySpot] {
        spotsManager.spots.filter { spot in
            selectedFilter == .all || spot.matchesFilter(selectedFilter)
        }
    }

    var body: some View {
        Map(position: $locationManager.cameraPosition, selection: $selectedSpot) {
            // User location
            UserAnnotation()

            // Accessibility spots
            ForEach(filteredSpots) { spot in
                Annotation(spot.title, coordinate: spot.coordinate) {
                    SpotAnnotationView(spot: spot)
                        .accessibilityLabel("\(spot.type.rawValue) at \(spot.title)")
                        .accessibilityHint(spot.description)
                        .accessibilityAddTraits(.isButton)
                }
                .tag(spot)
            }
        }
        .mapControls {
            MapCompass()
                .accessibilityLabel("Map compass")
            MapScaleView()
                .accessibilityLabel("Map scale")
        }
        .mapStyle(.standard(elevation: .flat))
        .sheet(item: $selectedSpot) { spot in
            SpotDetailView(spot: spot)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct SpotAnnotationView: View {
    let spot: AccessibilitySpot

    var body: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(annotationColor.opacity(0.2))
                .frame(width: 50, height: 50)

            // Main circle
            Circle()
                .fill(annotationColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )

            // Icon
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    var annotationColor: Color {
        switch spot.type {
        case .ramp: return Color(red: 0.4, green: 0.8, blue: 0.4) // Green
        case .elevator: return Color(red: 0.3, green: 0.6, blue: 1.0) // Blue
        case .accessibleEntrance: return Color(red: 0.4, green: 0.8, blue: 0.4) // Green
        case .stepFreeRoute: return Color(red: 0.4, green: 0.8, blue: 0.4) // Green
        case .accessibleParking: return Color(red: 0.3, green: 0.6, blue: 1.0) // Blue
        case .accessibleToilet: return Color(red: 0.9, green: 0.7, blue: 0.2) // Yellow
        }
    }

    var iconName: String {
        switch spot.type {
        case .ramp: return "triangle.fill"
        case .elevator: return "arrow.up.arrow.down"
        case .accessibleEntrance: return "door.left.hand.open"
        case .stepFreeRoute: return "arrow.turn.up.right"
        case .accessibleParking: return "parkingsign.circle.fill"
        case .accessibleToilet: return "toilet.fill"
        }
    }
}

#Preview {
    MapView(selectedFilter: .constant(.all))
        .environmentObject(LocationManager())
        .environmentObject(AccessibilitySpotsManager())
}
