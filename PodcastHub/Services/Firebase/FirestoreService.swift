import FirebaseFirestore
import Foundation

protocol FirestoreServiceType {
    func saveSubscriptions(_ showIds: [String], userId: String) async throws
    func fetchSubscriptions(userId: String) async throws -> [String]
    func savePlaybackState(episodeId: String, position: Double, userId: String) async throws
    func fetchPlaybackState(episodeId: String, userId: String) async throws -> Double?
}

final class FirestoreService: FirestoreServiceType {
    private let db = Firestore.firestore()

    func saveSubscriptions(_ showIds: [String], userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.setData([
            "subscriptions": showIds,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func fetchSubscriptions(userId: String) async throws -> [String] {
        let userRef = db.collection("users").document(userId)
        let document = try await userRef.getDocument()
        guard
            let data = document.data(),
            let subscriptions = data["subscriptions"] as? [String]
        else {
            return []
        }
        return subscriptions
    }

    func savePlaybackState(episodeId: String, position: Double, userId: String) async throws {
        let playbackRef = db.collection("users").document(userId)
            .collection("playback").document(episodeId)
        try await playbackRef.setData([
            "position": position,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func fetchPlaybackState(episodeId: String, userId: String) async throws -> Double? {
        let playbackRef = db.collection("users").document(userId)
            .collection("playback").document(episodeId)
        let document = try await playbackRef.getDocument()
        guard
            let data = document.data(),
            let position = data["position"] as? Double
        else {
            return nil
        }
        return position
    }
}
