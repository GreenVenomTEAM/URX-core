import UIKit
import Evander

/// Minimal in-process startup for the upstream Sileo UI.
/// Root/jailbreak helpers and the upstream app delegate are deliberately not embedded.
public enum SileoEmbedBootstrap {
    public static func prepare(rootController: UIViewController) {
        guard let tabController = rootController as? UITabBarController else { return }

        // Keep Sileo's data and repository state in the app sandbox.
        Evander.prepare()
        SileoThemeManager.shared.updateUserInterface()
        _ = RepoManager.shared
        _ = PackageListManager.shared
        _ = DatabaseManager.shared
        _ = DownloadManager.shared
        _ = LanguageHelper.shared

        tabController.delegate = tabController as? UITabBarControllerDelegate
        for (index, controller) in (tabController.viewControllers ?? []).enumerated() {
            _ = controller.view
            if let navigationController = controller as? UINavigationController {
                _ = navigationController.viewControllers.first?.view
            }
            if index == 4 {
                controller.tabBarItem.title = "Search"
            }
        }
    }
}
