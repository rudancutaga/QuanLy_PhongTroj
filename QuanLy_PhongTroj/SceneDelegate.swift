//
//  SceneDelegate.swift
//  QuanLy_PhongTroj
//
//  Created by mac on 18/3/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

enum AppDestination {
    case login
    case user
    case admin
}

enum AppSessionPreferences {
    private static let autoLoginKey = "app.session.autoLoginEnabled"

    static var isAutoLoginEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: autoLoginKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLoginKey)
        }
    }
}

final class AppNavigator {
    static let shared = AppNavigator()

    private init() {}

    func routeForCurrentSession(animated: Bool = false) {
        showLoadingRoot()

        guard AppSessionPreferences.isAutoLoginEnabled else {
            try? Auth.auth().signOut()
            route(to: .login, animated: animated)
            return
        }

        guard let currentUser = Auth.auth().currentUser else {
            route(to: .login, animated: animated)
            return
        }

        Firestore.firestore().collection("Users").document(currentUser.uid).getDocument { document, _ in
            let data = document?.data()
            let isActive = data?["isActive"] as? Bool ?? true
            let role = data?["role"] as? String ?? "user"

            DispatchQueue.main.async {
                guard isActive else {
                    try? Auth.auth().signOut()
                    self.route(to: .login, animated: animated)
                    return
                }

                self.route(to: role == "admin" ? .admin : .user, animated: animated)
            }
        }
    }

    func routeToRole(_ role: String, animated: Bool = true) {
        route(to: role == "admin" ? .admin : .user, animated: animated)
    }

    func route(to destination: AppDestination, animated: Bool = true) {
        let rootViewController = makeRootViewController(for: destination)
        setRootViewController(rootViewController, animated: animated)
    }

    func showLoadingRoot() {
        setRootViewController(makeLoadingViewController(), animated: false)
    }

    private func makeRootViewController(for destination: AppDestination) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        switch destination {
        case .login:
            return storyboard.instantiateViewController(withIdentifier: "DangNhapVC")
        case .user:
            return storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        case .admin:
            return storyboard.instantiateViewController(withIdentifier: "AdminTabBarController")
        }
    }

    private func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        guard let window = activeWindow() else { return }

        window.rootViewController = viewController
        window.makeKeyAndVisible()

        guard animated else { return }

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }

    private func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow) ??
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first
    }

    private func makeLoadingViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Đang khởi tạo dự án..."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .medium)

        viewController.view.addSubview(indicator)
        viewController.view.addSubview(label)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
        ])

        return viewController
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground
        self.window = window
        window.makeKeyAndVisible()

        AppNavigator.shared.routeForCurrentSession(animated: false)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
