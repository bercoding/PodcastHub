import Foundation

protocol ShowDetailViewModelProtocol: AnyObject {
    var onShowLoaded: ((Show) -> Void)? { get set }
    var onEpisodesChanged: (([Episode]) -> Void)? { get set }
    var onLoadingStateChanged: ((Bool) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func load()
    func refresh()
}

final class ShowDetailViewModel: ShowDetailViewModelProtocol {
    var onShowLoaded: ((Show) -> Void)?
    var onEpisodesChanged: (([Episode]) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private let repository: PodcastRepositoryType
    private let showId: String
    private var show: Show?
    private var isLoading = false

    init(repository: PodcastRepositoryType, showId: String) {
        self.repository = repository
        self.showId = showId
    }

    func load() {
        guard !isLoading else {
            return
        }
        isLoading = true
        onLoadingStateChanged?(true)
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let fetchedShow = try await repository.getShowDetail(id: showId)
                show = fetchedShow
                DispatchQueue.main.async {
                    self.onShowLoaded?(fetchedShow)
                    self.onEpisodesChanged?(fetchedShow.latestEpisodes)
                    self.onLoadingStateChanged?(false)
                }
            } catch {
                DispatchQueue.main.async {
                    self.onError?(error.localizedDescription)
                    self.onLoadingStateChanged?(false)
                }
            }
            isLoading = false
        }
    }

    func refresh() {
        isLoading = false
        load()
    }
}
