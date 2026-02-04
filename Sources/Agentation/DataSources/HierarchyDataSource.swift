import UIKit

@MainActor
protocol HierarchyDataSource {
    func capture() async -> HierarchySnapshot
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
