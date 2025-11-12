import Foundation

struct Show: Decodable, Hashable {
    let id: String
    let title: String
    let publisher: String
    let imageURL: URL?
    let thumbnailURL: URL?
    let totalEpisodes: Int
    let description: String
    let rss: String?
    let genres: [String]
    let latestEpisodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case id
        case title = "titleOriginal"
        case publisher = "publisherOriginal"
        case image
        case thumbnail
        case totalEpisodes
        case description = "descriptionOriginal"
        case rss
        case genres = "genreIds"
        case latestEpisodes
    }

    init(
        id: String,
        title: String,
        publisher: String,
        imageURL: URL?,
        thumbnailURL: URL?,
        totalEpisodes: Int,
        description: String,
        rss: String?,
        genres: [String],
        latestEpisodes: [Episode]
    ) {
        self.id = id
        self.title = title
        self.publisher = publisher
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.totalEpisodes = totalEpisodes
        self.description = description
        self.rss = rss
        self.genres = genres
        self.latestEpisodes = latestEpisodes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.publisher = try container.decode(String.self, forKey: .publisher)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .image)
        self.thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnail)
        self.totalEpisodes = try container.decodeIfPresent(Int.self, forKey: .totalEpisodes) ?? 0
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.rss = try container.decodeIfPresent(String.self, forKey: .rss)
        self.genres = try container.decodeIfPresent([Int].self, forKey: .genres)?.map(String.init) ?? []
        self.latestEpisodes = try container.decodeIfPresent([Episode].self, forKey: .latestEpisodes) ?? []
    }
}

struct Episode: Decodable, Hashable {
    let id: String
    let title: String
    let audioURL: URL?
    let thumbnailURL: URL?
    let description: String
    let duration: Int
    let publishDate: Date?
    let isExplicit: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title = "titleOriginal"
        case audio
        case thumbnail
        case description = "descriptionOriginal"
        case audioLengthSec
        case pubDateMs
        case explicitContent
    }

    init(
        id: String,
        title: String,
        audioURL: URL?,
        thumbnailURL: URL?,
        description: String,
        duration: Int,
        publishDate: Date?,
        isExplicit: Bool
    ) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.thumbnailURL = thumbnailURL
        self.description = description
        self.duration = duration
        self.publishDate = publishDate
        self.isExplicit = isExplicit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.audioURL = try container.decodeIfPresent(URL.self, forKey: .audio)
        self.thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnail)
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.duration = try container.decodeIfPresent(Int.self, forKey: .audioLengthSec) ?? 0
        if let milliseconds = try container.decodeIfPresent(Int64.self, forKey: .pubDateMs) {
            self.publishDate = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
        } else {
            self.publishDate = nil
        }
        self.isExplicit = try container.decodeIfPresent(Bool.self, forKey: .explicitContent) ?? false
    }
}

struct PodcastListResponse: Decodable {
    let total: Int?
    let podcasts: [Show]

    enum CodingKeys: String, CodingKey {
        case total
        case podcasts
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.total = try container.decodeIfPresent(Int.self, forKey: .total)
        if let podcasts = try container.decodeIfPresent([Show].self, forKey: .podcasts) {
            self.podcasts = podcasts
        } else if let results = try container.decodeIfPresent([Show].self, forKey: .results) {
            self.podcasts = results
        } else {
            self.podcasts = []
        }
    }
}
