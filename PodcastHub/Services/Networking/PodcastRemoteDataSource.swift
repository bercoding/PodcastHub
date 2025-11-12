import Foundation

protocol PodcastRemoteDataSourceType {
    func fetchTrending(page: Int, pageSize: Int) async throws -> [Show]
    func search(query: String, page: Int, pageSize: Int) async throws -> [Show]
    func fetchShowDetail(id: String) async throws -> Show
    func fetchRSSFeed(url: URL) async throws -> Data
}

final class PodcastRemoteDataSource: PodcastRemoteDataSourceType {
    private let apiClient: APIClientType

    init(apiClient: APIClientType) {
        self.apiClient = apiClient
    }

    func fetchTrending(page: Int, pageSize: Int) async throws -> [Show] {
        let response: PodcastListResponse = try await apiClient.request(.trending(
            page: page,
            pageSize: pageSize
        ))
        return response.podcasts
    }

    func search(query: String, page: Int, pageSize: Int) async throws -> [Show] {
        let response: PodcastListResponse = try await apiClient.request(.search(
            query: query,
            page: page,
            pageSize: pageSize
        ))
        return response.podcasts
    }

    func fetchShowDetail(id: String) async throws -> Show {
        try await apiClient.request(.showDetail(id: id))
    }

    func fetchRSSFeed(url: URL) async throws -> Data {
        try await apiClient.data(for: url)
    }
}
