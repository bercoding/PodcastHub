//
//  SceneDelegate.swift
//  PodcastHub
//
//  Created by Le Thanh Nhan on 10/11/25.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let appRouter = AppRouter()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)
        appRouter.start(in: window)
        self.window = window
        window.makeKeyAndVisible()
    }
}
