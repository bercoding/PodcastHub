import Foundation

final class PodcastIndexRepository: PodcastRepositoryType {
    private let apiClient: APIClientType
    private let credentials: PodcastIndexCredentials
    private let maxItems: Int

    init(
        apiClient: APIClientType,
        credentials: PodcastIndexCredentials,
        maxItems: Int = 20
    ) {
        self.apiClient = apiClient
        self.credentials = credentials
        self.maxItems = maxItems
    }

    func getTrending(page: Int) async throws -> [Show] {
        let endpoint = PodcastIndexEndpoint.trending(max: maxItems)
        let request = endpoint.makeRequest(credentials: credentials)
        let response: PodcastIndexFeedListResponse = try await apiClient.request(request)
        return response.feeds.map { $0.toShow() }
    }

    func searchShows(query: String, page: Int) async throws -> [Show] {
        let endpoint = PodcastIndexEndpoint.search(query: query, max: maxItems)
        let request = endpoint.makeRequest(credentials: credentials)
        let response: PodcastIndexFeedListResponse = try await apiClient.request(request)
        return response.feeds.map { $0.toShow() }
    }

    func getShowDetail(id: String) async throws -> Show {
        guard let feedId = Int(id) else {
            throw MockRepositoryError.showNotFound
        }

        async let feedResponse: PodcastIndexFeedDetailResponse = fetchFeed(id: feedId)
        async let episodesResponse: PodcastIndexEpisodesResponse = fetchEpisodes(feedId: feedId)

        let (feed, episodes) = try await (feedResponse.feed, episodesResponse.items)
        let mappedEpisodes = episodes
            .map { $0.toEpisode() }
            .sorted { ($0.publishDate ?? .distantPast) > ($1.publishDate ?? .distantPast) }
        return feed.toShow(episodes: mappedEpisodes)
    }

    private func fetchFeed(id: Int) async throws -> PodcastIndexFeedDetailResponse {
        let request = PodcastIndexEndpoint.feed(id: id).makeRequest(credentials: credentials)
        return try await apiClient.request(request)
    }

    private func fetchEpisodes(feedId: Int) async throws -> PodcastIndexEpisodesResponse {
        let request = PodcastIndexEndpoint.episodes(feedId: feedId, max: maxItems)
            .makeRequest(credentials: credentials)
        return try await apiClient.request(request)
    }
}
