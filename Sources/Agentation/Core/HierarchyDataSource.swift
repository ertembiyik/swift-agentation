//
//  HierarchyDataSource.swift
//  Agentation
//
//  Created by Ertem Biyik on 2025.
//

import UIKit

/// A type that can snapshot the current UI and resolve element frames at runtime.
///
/// Agentation ships with two built-in conformances:
///
/// * ``ViewHierarchyDataSource`` — walks the `UIView` tree directly.
/// * ``AccessibilityHierarchyDataSource`` — uses the iOS accessibility tree.
///
/// You can implement your own data source by conforming to this protocol.
@MainActor
protocol HierarchyDataSource {

    /// Captures a snapshot of the current on-screen element tree.
    func capture() async -> HierarchySnapshot

    /// Returns the current screen frame of a previously captured element, or `nil` if the element is no longer visible.
    func resolve(elementId: UUID) -> CGRect?

}

extension HierarchyDataSource {

    var appWindows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .filter { !($0 is OverlayWindow) && String(describing: type(of: $0)) != "UITextEffectsWindow" }
    }

    func currentScreenName() -> String {
        guard let topVC = topViewController() else {
            return "Unknown"
        }
        return String(describing: type(of: topVC))
    }

    func viewportSize() -> CGSize {
        guard let window = appWindows.first else {
            return .zero
        }
        return window.bounds.size
    }

    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? appWindows.first(where: { $0.isKeyWindow })?.rootViewController

        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = baseVC as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }

        return baseVC
    }

}
