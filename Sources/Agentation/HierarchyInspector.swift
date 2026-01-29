import UIKit

@MainActor
public final class HierarchyInspector {

    public static let shared = HierarchyInspector()

    private(set) var viewLookup: [UUID: WeakViewRef] = [:]

    public var ignoredWindowClassNames: Set<String> = [
        "UITextEffectsWindow"
    ]

    private init() {}

    private func shouldIgnoreWindow(_ window: UIWindow) -> Bool {
        if window is AgentationOverlayWindow { return true }
        let className = String(describing: type(of: window))
        return ignoredWindowClassNames.contains(className)
    }

    public func captureHierarchy() -> [ElementInfo] {
        viewLookup.removeAll()
        var elements: [ElementInfo] = []

        let allScenes = UIApplication.shared.connectedScenes
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }

            for window in windowScene.windows {
                if shouldIgnoreWindow(window) { continue }

                let windowElement = inspectView(
                    window,
                    parentPath: "",
                    depth: 0
                )
                elements.append(windowElement)
            }
        }

        return elements
    }

    func view(for elementId: UUID) -> UIView? {
        viewLookup[elementId]?.view
    }

    public func currentPageName() -> String {
        guard let topViewController = topViewController() else {
            return "Unknown"
        }
        return String(describing: type(of: topViewController))
    }

    public func viewportSize() -> CGSize {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { !shouldIgnoreWindow($0) })
        else {
            return .zero
        }
        return window.bounds.size
    }

    public func printHierarchy() -> String {
        var output = ""

        let selector = NSSelectorFromString("_subtreeDescription")

        let allScenes = UIApplication.shared.connectedScenes

        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }

            for window in windowScene.windows {
                if shouldIgnoreWindow(window) { continue }
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

    public func printViewControllerHierarchy() -> String {
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

    private func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
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

    private func inspectView(
        _ view: UIView,
        parentPath: String,
        depth: Int
    ) -> ElementInfo {
        let typeName = String(describing: type(of: view))

        let pathComponent = buildPathComponent(for: view)
        let currentPath = parentPath.isEmpty ? pathComponent : "\(parentPath) > \(pathComponent)"

        let screenFrame = view.convert(view.bounds, to: nil)
        let accessibilityLabel = view.accessibilityLabel
        let accessibilityIdentifier = view.accessibilityIdentifier
        let accessibilityHint = view.accessibilityHint
        let accessibilityValue = view.accessibilityValue
        let subviews = view.subviews
        let isHidden = view.isHidden
        let alpha = view.alpha

        let agentationTag = AgentationTagRegistry.shared.tag(for: view)

        var children: [ElementInfo] = []
        for subview in subviews {
            guard !subview.isHidden, subview.alpha > 0.01 else { continue }
            guard subview.bounds.width > 0, subview.bounds.height > 0 else { continue }

            let childInfo = inspectView(
                subview,
                parentPath: currentPath,
                depth: depth + 1
            )
            children.append(childInfo)
        }

        let elementId = UUID()
        viewLookup[elementId] = WeakViewRef(view: view)

        return ElementInfo(
            id: elementId,
            accessibilityLabel: accessibilityLabel,
            accessibilityIdentifier: accessibilityIdentifier,
            accessibilityHint: accessibilityHint,
            accessibilityValue: accessibilityValue,
            typeName: typeName,
            frame: screenFrame,
            path: currentPath,
            children: children,
            agentationTag: agentationTag
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

        return "\(simplified)"
    }
}

struct WeakViewRef {
    weak var view: UIView?
}

internal class AgentationOverlayWindow: UIWindow {}

@MainActor
public final class AgentationTagRegistry {
    public static let shared = AgentationTagRegistry()

    private var tags: [ObjectIdentifier: String] = [:]

    private init() {}

    public func setTag(_ tag: String, for view: UIView) {
        tags[ObjectIdentifier(view)] = tag
    }

    public func tag(for view: UIView) -> String? {
        tags[ObjectIdentifier(view)]
    }

    public func removeTag(for view: UIView) {
        tags.removeValue(forKey: ObjectIdentifier(view))
    }

    public func clearAll() {
        tags.removeAll()
    }
}
