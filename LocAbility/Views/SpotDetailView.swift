//
//  SpotDetailView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Detail view for accessibility spot
//

import SwiftUI
import MapKit
import UIKit

struct SpotDetailView: View {
    let spot: AccessibilitySpot
    @Environment(\.dismiss) var dismiss
    @State private var mapSnapshot: UIImage?
    @State private var streetViewImage: UIImage?
    @State private var streetViewError: String?
    @State private var isLoadingStreetView = true
    @State private var hasLoadedMedia = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    mediaHeader
                    infoCard
                    descriptionSection
                    locationSection
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Spot details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            guard !hasLoadedMedia else { return }
            hasLoadedMedia = true
            await loadMediaAssets()
        }
    }

    private var mediaHeader: some View {
        let hasMedia = (streetViewImage != nil) || (mapSnapshot != nil)
        let mediaHeight: CGFloat = 210
        let headerShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                headerShape
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: mediaHeight)

                if let image = streetViewImage ?? mapSnapshot {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: mediaHeight)
                        .clipShape(headerShape)
                }

                if hasMedia {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(headerShape)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(spot.type.rawValue)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()

                    HStack {
                        Spacer()
                        mediaSourceBadge
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Fetching a street-level preview…")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }

                if isLoadingStreetView {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(hasMedia ? .white : .gray)
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipShape(headerShape)
            .shadow(color: .black.opacity(0.12), radius: 10, y: 6)

            if let error = streetViewError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            } else if streetViewImage != nil {
                Text("Street imagery courtesy of Mapillary (free community data).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else if mapSnapshot != nil {
                Text("Falling back to a satellite snapshot until street imagery is available.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediaSourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: streetViewImage != nil ? "camera.aperture" : "map")
            Text(streetViewImage != nil ? "Street View" : "Satellite Preview")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(Capsule())
    }

    private var infoCard: some View {
        detailCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(iconBackgroundColor)
                            .frame(width: 52, height: 52)

                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(spot.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(spot.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                Divider()

                HStack(spacing: 12) {
                    StatusBadge(status: spot.status)

                    Label("Community verified", systemImage: "checkmark.shield")
                        .font(.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if !spot.description.isEmpty {
            detailCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Description", systemImage: "text.alignleft")
                        .font(.headline)
                    Text(spot.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var locationSection: some View {
        detailCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Location", systemImage: "location.fill")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lat: \(spot.coordinate.latitude, specifier: "%.5f")")
                        Text("Lon: \(spot.coordinate.longitude, specifier: "%.5f")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        copyCoordinates()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var actionButtons: some View {
        detailCard {
            VStack(spacing: 12) {
                Button(action: openInMaps) {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel("Get directions to this location")

                Button {
                    // TODO: Report issue hook
                } label: {
                    Label("Report issue", systemImage: "exclamationmark.triangle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel("Report issue with this spot")
            }
        }
    }

    private func copyCoordinates() {
        UIPasteboard.general.string = "\(spot.coordinate.latitude), \(spot.coordinate.longitude)"
    }

    @ViewBuilder
    private func detailCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
    }

    private func loadMediaAssets() async {
        async let streetTask = loadStreetViewImage()
        async let mapTask = generateMapSnapshot()
        _ = await (streetTask, mapTask)
    }

    private func loadStreetViewImage() async {
        await MainActor.run {
            isLoadingStreetView = true
            streetViewError = nil
        }

        do {
            let mapillaryURL = try await fetchMapillaryImage(
                latitude: spot.coordinate.latitude,
                longitude: spot.coordinate.longitude
            )

            if let url = mapillaryURL {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        streetViewImage = image
                        isLoadingStreetView = false
                    }
                    return
                }
            }

            await MainActor.run {
                streetViewError = "Street imagery unavailable for this spot."
                isLoadingStreetView = false
            }
        } catch {
            print("Failed to load street view: \(error)")
            await MainActor.run {
                streetViewError = "Could not load street imagery right now."
                isLoadingStreetView = false
            }
        }
    }

    private func fetchMapillaryImage(latitude: Double, longitude: Double) async throws -> URL? {
        // Mapillary API to find nearby images
        let radius = 50 // meters
        // Use the Mapillary app credentials provided for LocAbility
        let mapillaryAccessToken = "MLY|24992045877104932|6527963c9ce58d5cf41d9d2e419cdf42"
        let urlString = "https://graph.mapillary.com/images?access_token=\(mapillaryAccessToken)&fields=thumb_1024_url&bbox=\(longitude-0.001),\(latitude-0.001),\(longitude+0.001),\(latitude+0.001)&limit=1"

        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct MapillaryResponse: Codable {
            let data: [MapillaryImage]?
            let error: MapillaryError?
        }

        struct MapillaryImage: Codable {
            let thumb_1024_url: String?
        }

        struct MapillaryError: Codable {
            let message: String?
        }

        let response = try JSONDecoder().decode(MapillaryResponse.self, from: data)

        if let errorMessage = response.error?.message {
            print("Mapillary API error: \(errorMessage)")
        }

        if let imageUrlString = response.data?.first?.thumb_1024_url,
           let imageUrl = URL(string: imageUrlString) {
            return imageUrl
        }

        return nil
    }

    private func generateMapSnapshot() async {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        options.size = CGSize(width: UIScreen.main.bounds.width, height: 300)
        options.mapType = .hybridFlyover
        options.showsBuildings = true

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()

            let image = UIGraphicsImageRenderer(size: options.size).image { context in
                snapshot.image.draw(at: .zero)

                let pinPoint = snapshot.point(for: spot.coordinate)
                let pinSize: CGFloat = 60

                context.cgContext.setShadow(
                    offset: CGSize(width: 0, height: 4),
                    blur: 8,
                    color: UIColor.black.withAlphaComponent(0.4).cgColor
                )

                let pinRect = CGRect(
                    x: pinPoint.x - pinSize / 2,
                    y: pinPoint.y - pinSize,
                    width: pinSize,
                    height: pinSize
                )

                context.cgContext.setFillColor(UIColor(iconBackgroundColor).cgColor)
                context.cgContext.fillEllipse(in: pinRect)

                context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
                context.cgContext.setStrokeColor(UIColor.white.cgColor)
                context.cgContext.setLineWidth(4)
                context.cgContext.strokeEllipse(in: pinRect)

                let iconSize = pinSize * 0.5
                let iconRect = CGRect(
                    x: pinPoint.x - iconSize / 2,
                    y: pinPoint.y - pinSize + (pinSize - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )

                let icon = UIImage(systemName: iconName)?
                    .withConfiguration(UIImage.SymbolConfiguration(pointSize: iconSize * 0.6, weight: .semibold))
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                icon?.draw(in: iconRect)
            }

            await MainActor.run {
                mapSnapshot = image
            }
        } catch {
            print("Failed to generate map snapshot: \(error)")
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
