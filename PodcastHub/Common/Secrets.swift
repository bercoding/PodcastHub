import Foundation

enum Secrets {
    static var listenNotesAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "LISTEN_NOTES_API_KEY") as? String
    }

    static var podcastIndexAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "PODCAST_INDEX_API_KEY") as? String
    }

    static var podcastIndexAPISecret: String? {
        Bundle.main.object(forInfoDictionaryKey: "PODCAST_INDEX_API_SECRET") as? String
    }
}
