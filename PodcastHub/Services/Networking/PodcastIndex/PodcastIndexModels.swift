import Foundation

struct PodcastIndexFeedListResponse: Decodable {
    let feeds: [PodcastIndexFeed]
}

struct PodcastIndexFeedDetailResponse: Decodable {
    let feed: PodcastIndexFeed
}

struct PodcastIndexEpisodesResponse: Decodable {
    let items: [PodcastIndexEpisode]
}

struct PodcastIndexFeed: Decodable {
    let id: Int
    let title: String
    let author: String?
    let description: String?
    let image: String?
    let artwork: String?
    let url: String?
    let feedUrl: String?
    let categories: [String: String]?
    let episodeCount: Int?
}

struct PodcastIndexEpisode: Decodable {
    let id: Int
    let title: String
    let description: String?
    let enclosureUrl: String?
    let image: String?
    let datePublished: Int?
    let duration: Int?
    let explicit: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case enclosureUrl
        case image
        case datePublished
        case duration
        case explicit
    }
}

extension PodcastIndexFeed {
    func toShow(episodes: [Episode] = []) -> Show {
        Show(
            id: String(id),
            title: title,
            publisher: author ?? "Không rõ tác giả",
            imageURL: URL(string: artwork ?? image ?? ""),
            thumbnailURL: URL(string: image ?? artwork ?? ""),
            totalEpisodes: episodeCount ?? episodes.count,
            description: description ?? "",
            rss: feedUrl ?? url,
            genres: categories.map { Array($0.values) } ?? [],
            latestEpisodes: episodes
        )
    }
}

extension PodcastIndexEpisode {
    func toEpisode() -> Episode {
        Episode(
            id: String(id),
            title: title,
            audioURL: URL(string: enclosureUrl ?? ""),
            thumbnailURL: URL(string: image ?? ""),
            description: description ?? "",
            duration: duration ?? 0,
            publishDate: datePublished.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) },
            isExplicit: (explicit ?? 0) == 1
        )
    }
}
