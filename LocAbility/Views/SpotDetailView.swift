//
//  SpotDetailView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Detail view for accessibility spot
//

import SwiftUI
import MapKit

struct SpotDetailView: View {
    let spot: AccessibilitySpot
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Map background (simplified)
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Spacer()
                                // Large icon
                                ZStack {
                                    Circle()
                                        .fill(iconBackgroundColor)
                                        .frame(width: 120, height: 120)

                                    Image(systemName: iconName)
                                        .font(.system(size: 50, weight: .regular))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                                .padding(.bottom, 30)
                            }
                        )

                    // Content card
                    VStack(alignment: .leading, spacing: 20) {
                        // Title and Type
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spot.title)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack {
                                Text(spot.type.rawValue)
                                    .font(.body)
                                    .foregroundColor(.secondary)

                                Spacer()

                                StatusBadge(status: spot.status)
                            }
                        }

                        Divider()

                        // Description
                        if !spot.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Description", systemImage: "text.alignleft")
                                    .font(.headline)

                                Text(spot.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Description: \(spot.description)")

                            Divider()
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Location", systemImage: "location.fill")
                                .font(.headline)

                            Text("Lat: \(spot.coordinate.latitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Lon: \(spot.coordinate.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Location coordinates")

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                openInMaps()
                            } label: {
                                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .accessibilityLabel("Get directions to this location")

                            Button {
                                // Report issue
                            } label: {
                                Label("Report Issue", systemImage: "exclamationmark.triangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                            .accessibilityLabel("Report issue with this spot")
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        mapItem.name = spot.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    var iconBackgroundColor: Color {
        switch spot.type {
        case .ramp: return Color(red: 0.4, green: 0.8, blue: 0.4)
        case .elevator: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .accessibleEntrance: return Color(red: 0.4, green: 0.8, blue: 0.4)
        case .stepFreeRoute: return Color(red: 0.4, green: 0.8, blue: 0.4)
        case .accessibleParking: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .accessibleToilet: return Color(red: 0.9, green: 0.7, blue: 0.2)
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

struct StatusBadge: View {
    let status: SpotStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)

            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.rawValue)")
    }

    var statusColor: Color {
        switch status {
        case .working: return .green
        case .notWorking: return .red
        case .underMaintenance: return .orange
        }
    }
}

#Preview {
    SpotDetailView(spot: AccessibilitySpot.sample)
}
