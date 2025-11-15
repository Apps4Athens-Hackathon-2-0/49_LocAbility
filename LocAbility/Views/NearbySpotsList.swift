//
//  NearbySpotsList.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  List of nearby accessibility spots
//

import SwiftUI

struct NearbySpotsList: View {
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @EnvironmentObject var locationManager: LocationManager

    var nearbySpots: [AccessibilitySpot] {
        spotsManager.getSpotsNear(
            location: locationManager.region.center,
            radius: 500
        ).prefix(5).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby Spots")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if !nearbySpots.isEmpty {
                    Text("\(nearbySpots.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            if nearbySpots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))

                    Text("No accessibility spots nearby")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Be the first to add one!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityLabel("No accessibility spots found nearby")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(nearbySpots) { spot in
                        SpotRowView(spot: spot)
                    }
                }
                .padding(.horizontal, 20)
                .accessibilityLabel("List of \(nearbySpots.count) nearby accessibility spots")
            }
        }
    }
}

struct SpotRowView: View {
    let spot: AccessibilitySpot

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [spot.statusColor.opacity(0.2), spot.statusColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(spot.type.emoji)
                    .font(.system(size: 26))
            }
            .accessibilityHidden(true)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(spot.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(spot.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: spot.status.icon)
                        .font(.caption)
                        .foregroundColor(spot.statusColor)

                    Text(spot.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(spot.statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(spot.statusColor.opacity(0.12))
                .cornerRadius(6)
            }

            Spacer()

            // Distance
            VStack(spacing: 2) {
                if let distance = spot.distance {
                    Text(distance < 1000 ? "\(Int(distance))" : String(format: "%.1f", distance / 1000))
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(distance < 1000 ? "m" : "km")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(spot.type.rawValue) at \(spot.title), \(spot.status.rawValue)")
        .accessibilityHint("Double tap for more details")
    }
}

#Preview {
    NearbySpotsList()
        .environmentObject(AccessibilitySpotsManager())
        .environmentObject(LocationManager())
}
