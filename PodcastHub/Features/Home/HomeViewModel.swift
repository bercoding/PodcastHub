import Foundation

protocol HomeViewModelProtocol: AnyObject {
    var onShowsChanged: (([Show]) -> Void)? { get set }
    var onLoadingStateChanged: ((Bool) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func loadTrending()
    func loadNextPageIfNeeded(currentIndex: Int)
    func didSelectShow(_ show: Show)
}

final class HomeViewModel: HomeViewModelProtocol {
    var onShowsChanged: (([Show]) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private let repository: PodcastRepositoryType
    private let router: HomeRouting
    private var shows: [Show] = []
    private var isLoading = false
    private var currentPage = 1
    private var hasMore = true

    init(repository: PodcastRepositoryType, router: HomeRouting) {
        self.repository = repository
        self.router = router
    }

    func loadTrending() {
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
                let newShows = try await repository.getTrending(page: currentPage)
                if newShows.isEmpty {
                    hasMore = false
                }
                if currentPage == 1 {
                    shows = newShows
                } else {
                    shows.append(contentsOf: newShows)
                }
                DispatchQueue.main.async {
                    self.onShowsChanged?(self.shows)
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

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard hasMore, currentIndex >= shows.count - 5 else {
            return
        }
        currentPage += 1
        loadTrending()
    }

    func didSelectShow(_ show: Show) {
        router.showDetail(for: show)
    }
}

protocol HomeRouting {
    func showDetail(for show: Show)
}
