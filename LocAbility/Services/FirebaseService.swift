//
//  FirebaseService.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Firebase Firestore integration for real-time spot synchronization
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import CoreLocation

@MainActor
class FirebaseService: ObservableObject {

    private let db = Firestore.firestore()
    private let spotsCollection = "accessibility_spots"

    @Published var isUploading = false
    @Published var isDownloading = false

    // MARK: - Upload Spot to Firebase

    /// Upload a new accessibility spot to Firestore
    func uploadSpot(_ spot: AccessibilitySpot) async throws {
        isUploading = true
        defer { isUploading = false }

        let spotData: [String: Any] = [
            "id": spot.id.uuidString,
            "title": spot.title,
            "description": spot.description,
            "type": spot.type.rawValue,
            "status": spot.status.rawValue,
            "latitude": spot.coordinate.latitude,
            "longitude": spot.coordinate.longitude,
            "createdAt": Timestamp(date: Date()),
            "photoURL": spot.photoURL?.absoluteString ?? "",
            "upvotes": 0,
            "downvotes": 0
        ]

        do {
            try await db.collection(spotsCollection).document(spot.id.uuidString).setData(spotData)
            print("✅ Uploaded spot to Firebase: \(spot.title)")
        } catch {
            print("❌ Firebase upload error: \(error)")
            throw error
        }
    }

    // MARK: - Download Spots from Firebase

    /// Fetch all accessibility spots from Firestore
    func fetchAllSpots() async throws -> [AccessibilitySpot] {
        isDownloading = true
        defer { isDownloading = false }

        do {
            let snapshot = try await db.collection(spotsCollection).getDocuments()

            let spots = snapshot.documents.compactMap { document -> AccessibilitySpot? in
                let data = document.data()

                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = data["title"] as? String,
                      let description = data["description"] as? String,
                      let typeString = data["type"] as? String,
                      let type = SpotType(rawValue: typeString),
                      let statusString = data["status"] as? String,
                      let status = SpotStatus(rawValue: statusString),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double else {
                    print("⚠️ Skipping invalid spot data: \(document.documentID)")
                    return nil
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                var spot = AccessibilitySpot(
                    id: id,
                    title: title,
                    description: description,
                    type: type,
                    status: status,
                    coordinate: coordinate
                )

                // Add photo URL if available
                if let photoURLString = data["photoURL"] as? String,
                   !photoURLString.isEmpty,
                   let photoURL = URL(string: photoURLString) {
                    spot.photoURL = photoURL
                }

                return spot
            }

            print("✅ Downloaded \(spots.count) spots from Firebase")
            return spots

        } catch {
            print("❌ Firebase download error: \(error)")
            throw error
        }
    }

    // MARK: - Real-time Listener

    /// Listen for real-time updates to spots (for live map)
    func listenForSpotUpdates(completion: @escaping ([AccessibilitySpot]) -> Void) -> ListenerRegistration {

        let listener = db.collection(spotsCollection).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firestore listener error: \(error)")
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ Empty snapshot")
                return
            }

            let spots = snapshot.documents.compactMap { document -> AccessibilitySpot? in
                let data = document.data()

                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = data["title"] as? String,
                      let description = data["description"] as? String,
                      let typeString = data["type"] as? String,
                      let type = SpotType(rawValue: typeString),
                      let statusString = data["status"] as? String,
                      let status = SpotStatus(rawValue: statusString),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double else {
                    return nil
                }

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                var spot = AccessibilitySpot(
                    id: id,
                    title: title,
                    description: description,
                    type: type,
                    status: status,
                    coordinate: coordinate
                )

                if let photoURLString = data["photoURL"] as? String,
                   !photoURLString.isEmpty,
                   let photoURL = URL(string: photoURLString) {
                    spot.photoURL = photoURL
                }

                return spot
            }

            print("🔄 Real-time update: \(spots.count) spots")
            Task { @MainActor in
                completion(spots)
            }
        }

        return listener
    }

    // MARK: - Upvote/Downvote (for community moderation)

    /// Upvote a spot
    func upvoteSpot(_ spotId: UUID) async throws {
        try await db.collection(spotsCollection).document(spotId.uuidString).updateData([
            "upvotes": FieldValue.increment(Int64(1))
        ])
        print("👍 Upvoted spot: \(spotId)")
    }

    /// Downvote a spot
    func downvoteSpot(_ spotId: UUID) async throws {
        try await db.collection(spotsCollection).document(spotId.uuidString).updateData([
            "downvotes": FieldValue.increment(Int64(1))
        ])
        print("👎 Downvoted spot: \(spotId)")
    }

    // MARK: - Delete Spot

    /// Delete a spot from Firestore
    func deleteSpot(_ spotId: UUID) async throws {
        try await db.collection(spotsCollection).document(spotId.uuidString).delete()
        print("🗑️ Deleted spot: \(spotId)")
    }
}
