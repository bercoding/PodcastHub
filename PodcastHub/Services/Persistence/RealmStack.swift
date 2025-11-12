import Foundation

#if canImport(RealmSwift)
import RealmSwift

protocol RealmStackType {
    func realm() throws -> Realm
}

final class RealmStack: RealmStackType {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = Realm.Configuration(schemaVersion: 1)) {
        self.configuration = configuration
    }

    func realm() throws -> Realm {
        try Realm(configuration: configuration)
    }
}

// swiftlint:disable attributes
final class RealmShow: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var title: String = ""
    @Persisted var publisher: String = ""
    @Persisted var imageURL: String = ""
    @Persisted var genres = List<String>()
    @Persisted var lastUpdated: Date = .init()
}

final class RealmEpisode: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var showId: String = ""
    @Persisted var title: String = ""
    @Persisted var audioURL: String = ""
    @Persisted var thumbnailURL: String = ""
    @Persisted var duration: Int = 0
    @Persisted var publishDate: Date = .init()
    @Persisted var descriptionText: String = ""
    @Persisted var lastPlaybackPosition: Double = 0
}
// swiftlint:enable attributes

#else

protocol RealmStackType {}

enum RealmUnavailableError: Error, LocalizedError {
    case moduleMissing

    var errorDescription: String? {
        "RealmSwift chưa được tích hợp."
    }
}

final class RealmStack: RealmStackType {
    init(configuration: Any? = nil) {}
}

#endif
