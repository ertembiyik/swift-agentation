import UIKit

struct WeakViewRef {
    weak var view: UIView?
}

@MainActor
final class ViewHierarchyDataSource: HierarchyDataSource {

    private(set) var viewLookup: [UUID: WeakViewRef] = [:]

    var ignoredWindowClassNames: Set<String> = [
        "UITextEffectsWindow"
    ]

    func capture() async -> HierarchySnapshot {
        viewLookup.removeAll()
        var roots: [ViewElementInfo] = []

        let allScenes = UIApplication.shared.connectedScenes
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                guard !shouldIgnoreWindow(window) else { continue }
                let windowElement = inspectView(window, parentPath: "", depth: 0)
                roots.append(windowElement)
            }
        }

        let leafElements = roots.flatMap { $0.leafElements() }

        return HierarchySnapshot(
            leafElements: leafElements,
            capturedAt: Date(),
            sourceType: .viewHierarchy,
            viewportSize: viewportSize(),
            screenName: currentScreenName()
        )
    }

    func currentScreenName() -> String {
        guard let topVC = topViewController() else { return "Unknown" }
        return String(describing: type(of: topVC))
    }

    func viewportSize() -> CGSize {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { !shouldIgnoreWindow($0) })
        else { return .zero }
        return window.bounds.size
    }

    func printHierarchy() -> String {
        var output = ""
        let selector = NSSelectorFromString("_subtreeDescription")
        let allScenes = UIApplication.shared.connectedScenes

        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                guard !shouldIgnoreWindow(window) else { continue }
                if window.responds(to: selector) {
                    let result = window.perform(selector)
                    if let description = result?.takeUnretainedValue() as? String {
                        output += description + "\n"
                    }
                }
            }
        }

        return output
    }

    func printViewControllerHierarchy() -> String {
        let selector = NSSelectorFromString("_printHierarchy")

        guard let rootVC = topViewController()?.view.window?.rootViewController else {
            return ""
        }

        if rootVC.responds(to: selector) {
            let result = rootVC.perform(selector)
            if let description = result?.takeUnretainedValue() as? String {
                return description
            }
        }

        return ""
    }

    private func shouldIgnoreWindow(_ window: UIWindow) -> Bool {
        if window is OverlayWindow { return true }
        let className = String(describing: type(of: window))
        return ignoredWindowClassNames.contains(className)
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow && !shouldIgnoreWindow($0) }?
            .rootViewController

        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseVC
    }

    private func inspectView(_ view: UIView, parentPath: String, depth: Int) -> ViewElementInfo {
        let typeName = String(describing: type(of: view))
        let pathComponent = buildPathComponent(for: view)
        let currentPath = parentPath.isEmpty ? pathComponent : "\(parentPath) > \(pathComponent)"
        let screenFrame = view.convert(view.bounds, to: nil)

        var children: [ViewElementInfo] = []
        for subview in view.subviews {
            guard !subview.isHidden, subview.alpha > 0.01 else { continue }
            guard subview.bounds.width > 0, subview.bounds.height > 0 else { continue }
            children.append(inspectView(subview, parentPath: currentPath, depth: depth + 1))
        }

        let elementId = UUID()
        viewLookup[elementId] = WeakViewRef(view: view)

        return ViewElementInfo(
            id: elementId,
            typeName: typeName,
            frame: screenFrame,
            accessibilityLabel: view.accessibilityLabel ?? "",
            accessibilityIdentifier: view.accessibilityIdentifier ?? "",
            accessibilityHint: view.accessibilityHint ?? "",
            accessibilityValue: view.accessibilityValue ?? "",
            agentationTag: AgentationTagRegistry.shared.tag(for: view) ?? "",
            children: children,
            path: currentPath
        )
    }

    private func buildPathComponent(for view: UIView) -> String {
        if let tag = AgentationTagRegistry.shared.tag(for: view) {
            return "[\(tag)]"
        }

        let identifier = view.accessibilityIdentifier
        let label = view.accessibilityLabel

        if let identifier, !identifier.isEmpty {
            return "#\(identifier)"
        }
        if let label, !label.isEmpty {
            let truncated = label.count > 20 ? String(label.prefix(20)) + "..." : label
            return "\"\(truncated)\""
        }

        let typeName = String(describing: type(of: view))
        var simplified = typeName
            .replacingOccurrences(of: "UI", with: "")
            .replacingOccurrences(of: "NS", with: "")
            .replacingOccurrences(of: "_", with: "")

        if typeName.contains("HostingView") || typeName.contains("_UIHosting") || typeName.contains("_NSHosting") {
            simplified = "HostingView"
        }

        return simplified
    }
}
