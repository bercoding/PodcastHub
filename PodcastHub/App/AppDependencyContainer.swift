import Foundation

final class AppDependencyContainer {
    private lazy var apiClient: APIClientType = APIClient()
    private lazy var userDefaultsStore = UserDefaultsStore(userDefaults: .standard)
    private lazy var realmStack = RealmStack()
    private lazy var mockRepository = MockPodcastRepository()
    private lazy var podcastRepository: PodcastRepositoryType = {
        if let credentials = PodcastIndexAuthProvider.credentials() {
            return PodcastIndexRepository(apiClient: apiClient, credentials: credentials)
        } else {
            print("⚠️ Podcast Index credentials không tồn tại — sử dụng mock data.")
            return mockRepository
        }
    }()

    func makePodcastRepository() -> PodcastRepositoryType {
        podcastRepository
    }

    func makeHomeViewController(router: HomeRouting) -> HomeViewController {
        let repository = makePodcastRepository()
        let viewModel = HomeViewModel(repository: repository, router: router)
        return HomeViewController(viewModel: viewModel)
    }

    func makeSearchViewController(router: SearchRouting) -> SearchViewController {
        let repository = makePodcastRepository()
        let viewModel = SearchViewModel(repository: repository, router: router)
        return SearchViewController(viewModel: viewModel)
    }

    func makeShowDetailViewController(showId: String) -> ShowDetailViewController {
        let repository = makePodcastRepository()
        let viewModel = ShowDetailViewModel(repository: repository, showId: showId)
        return ShowDetailViewController(viewModel: viewModel)
    }
}
