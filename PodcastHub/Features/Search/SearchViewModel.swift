import Foundation

protocol SearchViewModelProtocol: AnyObject {
    var onResultsChanged: (([Show]) -> Void)? { get set }
    var onLoadingStateChanged: ((Bool) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    func updateSearchQuery(_ query: String)
    func didSelectShow(_ show: Show)
}

final class SearchViewModel: SearchViewModelProtocol {
    var onResultsChanged: (([Show]) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    private let repository: PodcastRepositoryType
    private let router: SearchRouting
    private var currentTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval = 0.4

    init(repository: PodcastRepositoryType, router: SearchRouting) {
        self.repository = repository
        self.router = router
    }

    func updateSearchQuery(_ query: String) {
        currentTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onResultsChanged?([])
            return
        }
        currentTask = Task { [weak self] in
            guard let self else {
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            if Task.isCancelled {
                return
            }
            await performSearch(query: trimmed)
        }
    }

    func didSelectShow(_ show: Show) {
        router.showDetail(for: show)
    }

    @MainActor
    private func performSearch(query: String) async {
        onLoadingStateChanged?(true)
        do {
            let results = try await repository.searchShows(query: query, page: 1)
            onResultsChanged?(results)
        } catch {
            onError?(error.localizedDescription)
        }
        onLoadingStateChanged?(false)
    }
}

protocol SearchRouting {
    func showDetail(for show: Show)
}
