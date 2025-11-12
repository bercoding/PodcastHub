import Foundation
#if canImport(RealmSwift)
import RealmSwift
#endif

protocol PodcastLocalDataSourceType {
    func saveShows(_ shows: [Show]) throws
    func fetchShows() throws -> [Show]
    func fetchShow(id: String) throws -> Show?
    func saveEpisodes(_ episodes: [Episode], for showId: String) throws
    func fetchEpisodes(for showId: String) throws -> [Episode]
}

#if canImport(RealmSwift)

final class PodcastLocalDataSource: PodcastLocalDataSourceType {
    private let realmStack: RealmStackType
    private let userDefaultsStore: UserDefaultsStoreType

    init(
        realmStack: RealmStackType,
        userDefaultsStore: UserDefaultsStoreType
    ) {
        self.realmStack = realmStack
        self.userDefaultsStore = userDefaultsStore
    }

    func saveShows(_ shows: [Show]) throws {
        let realm = try realmStack.realm()
        let objects = shows.map { show -> RealmShow in
            let realmShow = RealmShow()
            realmShow.id = show.id
            realmShow.title = show.title
            realmShow.publisher = show.publisher
            realmShow.imageURL = show.imageURL?.absoluteString ?? ""
            realmShow.genres.removeAll()
            realmShow.genres.append(objectsIn: show.genres)
            realmShow.lastUpdated = Date()
            return realmShow
        }
        try realm.write {
            realm.add(objects, update: .modified)
        }
    }

    func fetchShows() throws -> [Show] {
        let realm = try realmStack.realm()
        return realm.objects(RealmShow.self).map { show in
            Show(
                id: show.id,
                title: show.title,
                publisher: show.publisher,
                imageURL: URL(string: show.imageURL),
                thumbnailURL: URL(string: show.imageURL),
                totalEpisodes: 0,
                description: "",
                rss: nil,
                genres: Array(show.genres),
                latestEpisodes: []
            )
        }
    }

    func fetchShow(id: String) throws -> Show? {
        let realm = try realmStack.realm()
        guard let show = realm.object(ofType: RealmShow.self, forPrimaryKey: id) else {
            return nil
        }
        return Show(
            id: show.id,
            title: show.title,
            publisher: show.publisher,
            imageURL: URL(string: show.imageURL),
            thumbnailURL: URL(string: show.imageURL),
            totalEpisodes: 0,
            description: "",
            rss: nil,
            genres: Array(show.genres),
            latestEpisodes: []
        )
    }

    func saveEpisodes(_ episodes: [Episode], for showId: String) throws {
        let realm = try realmStack.realm()
        let objects = episodes.map { episode -> RealmEpisode in
            let realmEpisode = RealmEpisode()
            realmEpisode.id = episode.id
            realmEpisode.showId = showId
            realmEpisode.title = episode.title
            realmEpisode.audioURL = episode.audioURL?.absoluteString ?? ""
            realmEpisode.thumbnailURL = episode.thumbnailURL?.absoluteString ?? ""
            realmEpisode.duration = episode.duration
            realmEpisode.publishDate = episode.publishDate ?? Date()
            realmEpisode.descriptionText = episode.description
            return realmEpisode
        }
        try realm.write {
            realm.add(objects, update: .modified)
        }
    }

    func fetchEpisodes(for showId: String) throws -> [Episode] {
        let realm = try realmStack.realm()
        return realm.objects(RealmEpisode.self)
            .filter("showId == %@", showId)
            .sorted(byKeyPath: "publishDate", ascending: false)
            .map { episode in
                Episode(
                    id: episode.id,
                    title: episode.title,
                    audioURL: URL(string: episode.audioURL),
                    thumbnailURL: URL(string: episode.thumbnailURL),
                    description: episode.descriptionText,
                    duration: episode.duration,
                    publishDate: episode.publishDate,
                    isExplicit: false
                )
            }
    }
}

#else

final class PodcastLocalDataSource: PodcastLocalDataSourceType {
    private let userDefaultsStore: UserDefaultsStoreType
    private var shows: [String: Show] = [:]
    private var episodes: [String: [Episode]] = [:]

    init(
        realmStack: RealmStackType,
        userDefaultsStore: UserDefaultsStoreType
    ) {
        self.userDefaultsStore = userDefaultsStore
        _ = realmStack // giữ interface đồng nhất, nhưng không dùng khi thiếu Realm
    }

    func saveShows(_ shows: [Show]) throws {
        shows.forEach { self.shows[$0.id] = $0 }
    }

    func fetchShows() throws -> [Show] {
        Array(shows.values)
    }

    func fetchShow(id: String) throws -> Show? {
        shows[id]
    }

    func saveEpisodes(_ episodes: [Episode], for showId: String) throws {
        self.episodes[showId] = episodes
    }

    func fetchEpisodes(for showId: String) throws -> [Episode] {
        episodes[showId] ?? []
    }
}

#endif
