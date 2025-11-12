import SwiftUI
import UIKit

protocol AppRouting {
    func start(in window: UIWindow)
}

final class AppRouter: AppRouting {
    private let dependencyContainer: AppDependencyContainer
    private weak var tabBarController: UITabBarController?

    init(dependencyContainer: AppDependencyContainer = AppDependencyContainer()) {
        self.dependencyContainer = dependencyContainer
    }

    func start(in window: UIWindow) {
        let homeVC = dependencyContainer.makeHomeViewController(router: self)
        let searchVC = dependencyContainer.makeSearchViewController(router: self)
        let settingsVC = UIHostingController(rootView: SettingsView())

        homeVC.tabBarItem = UITabBarItem(title: "Trang chủ", image: UIImage(systemName: "house.fill"), tag: 0)
        searchVC.tabBarItem = UITabBarItem(
            title: "Tìm kiếm",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 1
        )
        settingsVC.tabBarItem = UITabBarItem(
            title: "Cài đặt",
            image: UIImage(systemName: "gearshape.fill"),
            tag: 2
        )

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            UINavigationController(rootViewController: homeVC),
            UINavigationController(rootViewController: searchVC),
            settingsVC
        ]
        self.tabBarController = tabBarController

        // Attach Mini Player
        MiniPlayerManager.shared.attach(to: tabBarController)

        window.rootViewController = tabBarController
    }

    private func selectedNavigationController() -> UINavigationController? {
        if let selectedNav = tabBarController?.selectedViewController as? UINavigationController {
            return selectedNav
        }
        return tabBarController?.viewControllers?.first as? UINavigationController
    }
}

extension AppRouter: HomeRouting, SearchRouting {
    func showDetail(for show: Show) {
        let showDetailVC = dependencyContainer.makeShowDetailViewController(showId: show.id)
        selectedNavigationController()?.pushViewController(showDetailVC, animated: true)
    }
}
