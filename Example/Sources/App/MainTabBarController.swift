import UIKit
import SwiftUI

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        // UIKit Demo Tab
        let uikitVC = UINavigationController(rootViewController: UIKitDemoViewController())
        uikitVC.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "uiwindow.split.2x1"),
            selectedImage: UIImage(systemName: "uiwindow.split.2x1")
        )

        // SwiftUI Demo Tab
        let swiftUIView = SwiftUIDemoView()
        let swiftUIVC = UIHostingController(rootView: swiftUIView)
        swiftUIVC.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "swift"),
            selectedImage: UIImage(systemName: "swift")
        )
        let swiftUINav = UINavigationController(rootViewController: swiftUIVC)

        viewControllers = [uikitVC, swiftUINav]
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
