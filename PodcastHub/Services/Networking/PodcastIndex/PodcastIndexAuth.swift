import Foundation

struct PodcastIndexCredentials {
    let key: String
    let secret: String
}

enum PodcastIndexAuthProvider {
    static func credentials() -> PodcastIndexCredentials? {
        guard
            let key = Secrets.podcastIndexAPIKey,
            let secret = Secrets.podcastIndexAPISecret,
            !key.isEmpty,
            !secret.isEmpty
        else {
            return nil
        }
        return PodcastIndexCredentials(key: key, secret: secret)
    }

    static func signedHeaders(
        for credentials: PodcastIndexCredentials,
        timestamp: Int = Int(Date().timeIntervalSince1970)
    ) -> [String: String] {
        let signatureBase = "\(credentials.key)\(credentials.secret)\(timestamp)"
        let authorization = SHA1.hexDigest(signatureBase)
        return [
            "X-Auth-Key": credentials.key,
            "X-Auth-Date": "\(timestamp)",
            "Authorization": authorization,
            "User-Agent": "PodcastHub/1.0 (iOS)"
        ]
    }
}
