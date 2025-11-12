import Foundation

protocol PodcastRepositoryType {
    func getTrending(page: Int) async throws -> [Show]
    func searchShows(query: String, page: Int) async throws -> [Show]
    func getShowDetail(id: String) async throws -> Show
}

final class PodcastRepository: PodcastRepositoryType {
    private let remoteDataSource: PodcastRemoteDataSourceType
    private let localDataSource: PodcastLocalDataSourceType
    private let pageSize: Int

    init(
        remoteDataSource: PodcastRemoteDataSourceType,
        localDataSource: PodcastLocalDataSourceType,
        pageSize: Int = 20
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.pageSize = pageSize
    }

    func getTrending(page: Int) async throws -> [Show] {
        do {
            let shows = try await remoteDataSource.fetchTrending(page: page, pageSize: pageSize)
            try localDataSource.saveShows(shows)
            return shows
        } catch {
            let cached = try? localDataSource.fetchShows()
            guard let cached, !cached.isEmpty else {
                throw error
            }
            return cached
        }
    }

    func searchShows(query: String, page: Int) async throws -> [Show] {
        try await remoteDataSource.search(query: query, page: page, pageSize: pageSize)
    }

    func getShowDetail(id: String) async throws -> Show {
        do {
            let show = try await remoteDataSource.fetchShowDetail(id: id)
            try localDataSource.saveEpisodes(show.latestEpisodes, for: id)
            return show
        } catch {
            let cachedEpisodes = try localDataSource.fetchEpisodes(for: id)
            guard let cachedShow = try localDataSource.fetchShow(id: id), !cachedEpisodes.isEmpty else {
                throw error
            }
            return Show(
                id: cachedShow.id,
                title: cachedShow.title,
                publisher: cachedShow.publisher,
                imageURL: cachedShow.imageURL,
                thumbnailURL: cachedShow.thumbnailURL,
                totalEpisodes: cachedShow.totalEpisodes,
                description: cachedShow.description,
                rss: cachedShow.rss,
                genres: cachedShow.genres,
                latestEpisodes: cachedEpisodes
            )
        }
    }
}
