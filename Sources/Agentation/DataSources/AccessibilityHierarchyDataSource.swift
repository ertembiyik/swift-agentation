import UIKit

@MainActor
final class AccessibilityHierarchyDataSource: HierarchyDataSource {

    private var frameLookup: [UUID: CGRect] = [:]

    private let ignoredWindowClassNames: Set<String> = [
        "UITextEffectsWindow"
    ]

    func capture() async -> HierarchySnapshot {
        frameLookup.removeAll()
        var roots: [AccessibilityElementInfo] = []

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                guard !shouldIgnoreWindow(window) else { continue }
                let children = collectAccessibleElements(window, parentPath: "", depth: 0)
                guard !children.isEmpty else { continue }
                roots.append(contentsOf: children)
            }
        }

        let leafElements = roots.flatMap { $0.leafElements() }

        return HierarchySnapshot(
            leafElements: leafElements,
            capturedAt: Date(),
            sourceType: .accessibility,
            viewportSize: viewportSize(),
            screenName: currentScreenName()
        )
    }

    private func collectAccessibleElements(_ element: NSObject, parentPath: String, depth: Int) -> [AccessibilityElementInfo] {
        guard depth < 50 else { return [] }

        if element.isAccessibilityElement {
            let frame = accessibilityFrame(for: element)
            guard frame.width > 0, frame.height > 0 else { return [] }

            let label = element.accessibilityLabel ?? ""
            let value = element.accessibilityValue ?? ""
            let hint = element.accessibilityHint ?? ""
            let traits = element.accessibilityTraits
            let role = roleFromTraits(traits)
            let pathComponent = buildPathComponent(label: label, role: role)
            let path = parentPath.isEmpty ? pathComponent : "\(parentPath) > \(pathComponent)"

            let id = UUID()
            frameLookup[id] = frame

            return [AccessibilityElementInfo(
                id: id,
                role: role,
                label: label,
                value: value,
                hint: hint,
                frame: frame,
                traits: traits,
                children: [],
                path: path
            )]
        }

        var results: [AccessibilityElementInfo] = []

        if let customElements = element.accessibilityElements {
            for child in customElements {
                guard let childObj = child as? NSObject else { continue }
                results.append(contentsOf: collectAccessibleElements(childObj, parentPath: parentPath, depth: depth + 1))
            }
        } else {
            let count = element.accessibilityElementCount()
            if count != NSNotFound && count > 0 {
                for i in 0..<count {
                    guard let child = element.accessibilityElement(at: i) as? NSObject else { continue }
                    results.append(contentsOf: collectAccessibleElements(child, parentPath: parentPath, depth: depth + 1))
                }
            } else if let view = element as? UIView {
                for subview in view.subviews {
                    guard !subview.isHidden, subview.alpha > 0.01 else { continue }
                    results.append(contentsOf: collectAccessibleElements(subview, parentPath: parentPath, depth: depth + 1))
                }
            }
        }

        return results
    }

    private func accessibilityFrame(for element: NSObject) -> CGRect {
        let frame = element.accessibilityFrame
        guard frame != .zero else {
            guard let view = element as? UIView else { return .zero }
            return view.convert(view.bounds, to: nil)
        }
        return frame
    }

    private func roleFromTraits(_ traits: UIAccessibilityTraits) -> String {
        if traits.contains(.button) { return "Button" }
        if traits.contains(.link) { return "Link" }
        if traits.contains(.header) { return "Header" }
        if traits.contains(.image) { return "Image" }
        if traits.contains(.staticText) { return "StaticText" }
        if traits.contains(.searchField) { return "SearchField" }
        if traits.contains(.adjustable) { return "Adjustable" }
        if traits.contains(.tabBar) { return "TabBar" }
        return ""
    }

    private func buildPathComponent(label: String, role: String) -> String {
        if !label.isEmpty {
            let truncated = label.count > 20 ? String(label.prefix(20)) + "..." : label
            return "\"\(truncated)\""
        }
        if !role.isEmpty {
            return role
        }
        return "Element"
    }

    private func shouldIgnoreWindow(_ window: UIWindow) -> Bool {
        if window is OverlayWindow { return true }
        let className = String(describing: type(of: window))
        return ignoredWindowClassNames.contains(className)
    }

    private func currentScreenName() -> String {
        guard let topVC = topViewController() else { return "Unknown" }
        return String(describing: type(of: topVC))
    }

    private func viewportSize() -> CGSize {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { !shouldIgnoreWindow($0) })
        else { return .zero }
        return window.bounds.size
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
        if let tab = baseVC as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseVC
    }
}
