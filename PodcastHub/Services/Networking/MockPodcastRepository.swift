import Foundation

final class MockPodcastRepository: PodcastRepositoryType {
    private let shows: [Show]

    init(dataLoader: MockDataLoader = MockDataLoader()) {
        self.shows = dataLoader.loadShows()
    }

    func getTrending(page: Int) async throws -> [Show] {
        shows
    }

    func searchShows(query: String, page: Int) async throws -> [Show] {
        guard !query.isEmpty else {
            return shows
        }
        let lowercasedQuery = query.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return shows.filter {
            let searchable = "\($0.title) \($0.publisher)".folding(
                options: .diacriticInsensitive,
                locale: .current
            ).lowercased()
            return searchable.contains(lowercasedQuery)
        }
    }

    func getShowDetail(id: String) async throws -> Show {
        guard let show = shows.first(where: { $0.id == id }) else {
            throw MockRepositoryError.showNotFound
        }
        return show
    }
}

enum MockRepositoryError: LocalizedError {
    case showNotFound

    var errorDescription: String? {
        "Không tìm thấy show trong mock data."
    }
}

private struct MockPodcastResponse: Decodable {
    let podcasts: [MockShow]
}

private struct MockShow: Decodable {
    let id: String
    let title: String
    let publisher: String
    let description: String
    let imageURL: String
    let thumbnailURL: String
    let rss: String
    let genres: [String]
    let episodes: [MockEpisode]

    func toShow() -> Show {
        Show(
            id: id,
            title: title,
            publisher: publisher,
            imageURL: URL(string: imageURL),
            thumbnailURL: URL(string: thumbnailURL),
            totalEpisodes: episodes.count,
            description: description,
            rss: rss,
            genres: genres,
            latestEpisodes: episodes.map { $0.toEpisode() }
        )
    }
}

private struct MockEpisode: Decodable {
    let id: String
    let title: String
    let audioURL: String
    let thumbnailURL: String
    let description: String
    let duration: Int
    let publishDate: Date
    let explicit: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case audioURL
        case thumbnailURL
        case description
        case duration
        case publishDate
        case explicit
    }

    func toEpisode() -> Episode {
        Episode(
            id: id,
            title: title,
            audioURL: URL(string: audioURL),
            thumbnailURL: URL(string: thumbnailURL),
            description: description,
            duration: duration,
            publishDate: publishDate,
            isExplicit: explicit
        )
    }
}

struct MockDataLoader {
    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadShows() -> [Show] {
        guard let url = Bundle.main.url(forResource: "podcasts", withExtension: "json") else {
            print("⚠️ Không tìm thấy MockData/podcasts.json trong bundle.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let response = try decoder.decode(MockPodcastResponse.self, from: data)
            return response.podcasts.map { $0.toShow() }
        } catch {
            print("⚠️ Không đọc được mock data: \(error.localizedDescription)")
            return []
        }
    }
}
