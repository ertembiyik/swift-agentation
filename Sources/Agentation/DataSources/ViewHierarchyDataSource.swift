import UIKit

@MainActor
final class ViewHierarchyDataSource: HierarchyDataSource {

    private(set) var viewLookup: [UUID: WeakRef<UIView>] = [:]

    func capture() async -> HierarchySnapshot {
        viewLookup.removeAll()
        var roots: [ViewElementInfo] = []

        for window in appWindows {
            roots.append(inspectView(window, accessibilityPath: "", depth: 0))
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

    func resolve(elementId: UUID) -> CGRect? {
        guard let view = viewLookup[elementId]?.value, view.window != nil else {
            return nil
        }
        return view.convert(view.bounds, to: nil)
    }

    private func inspectView(_ view: UIView, accessibilityPath: String, depth: Int) -> ViewElementInfo {
        let typeName = String(describing: type(of: view))
        let component = accessibilityPathComponent(for: view)
        let currentAccessibilityPath: String
        if let component {
            currentAccessibilityPath = accessibilityPath.isEmpty ? component : "\(accessibilityPath) > \(component)"
        } else {
            currentAccessibilityPath = accessibilityPath
        }

        let vcName = viewControllerName(for: view)
        let fullPath = currentAccessibilityPath.isEmpty ? vcName : "\(vcName) > \(currentAccessibilityPath)"

        let screenFrame = view.convert(view.bounds, to: nil)

        var children: [ViewElementInfo] = []
        for subview in view.subviews {
            guard !subview.isHidden, subview.alpha > 0.01 else {
                continue
            }

            guard subview.bounds.width > 0, subview.bounds.height > 0 else {
                continue
            }
            children.append(inspectView(subview, accessibilityPath: currentAccessibilityPath, depth: depth + 1))
        }

        let elementId = UUID()
        viewLookup[elementId] = WeakRef(value: view)

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
            path: fullPath
        )
    }

    private func viewControllerName(for view: UIView) -> String {
        guard let vc = UIViewUtils.owningViewController(for: view) else {
            return currentScreenName()
        }
        return String(describing: type(of: vc))
    }

    private func accessibilityPathComponent(for view: UIView) -> String? {
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

        return nil
    }
}
