import UIKit
import SwiftUI

@MainActor
final class AccessibilityHierarchyDataSource: HierarchyDataSource {

    private var elementLookup: [UUID: WeakRef<NSObject>] = [:]

    func capture() async -> HierarchySnapshot {
        elementLookup.removeAll()
        var roots: [AccessibilityElementInfo] = []

        for window in appWindows {
            let children = collectAccessibleElements(window, depth: 0)
            guard !children.isEmpty else {
                continue
            }
            roots.append(contentsOf: children)
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

    func resolve(elementId: UUID) -> CGRect? {
        guard let element = elementLookup[elementId]?.value else {
            return nil
        }

        let frame = accessibilityFrame(for: element)

        guard frame.width > 0, frame.height > 0 else {
            return nil
        }
        
        return frame
    }

    private func collectAccessibleElements(_ element: NSObject, depth: Int) -> [AccessibilityElementInfo] {
        guard depth < 50 else {
            return []
        }

        if element.isAccessibilityElement {
            let frame = accessibilityFrame(for: element)
            guard frame.width > 0, frame.height > 0 else {
                return []
            }

            let label = element.accessibilityLabel ?? ""
            let value = element.accessibilityValue ?? ""
            let hint = element.accessibilityHint ?? ""
            let traits = element.accessibilityTraits
            let role = roleFromTraits(traits)
            let vcName = viewControllerName(for: element)
            let pathComponent = buildPathComponent(label: label, role: role)
            let path = "\(vcName) > \(pathComponent)"

            let id = UUID()
            elementLookup[id] = WeakRef(value: element)

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
                guard let childObj = child as? NSObject else {
                    continue
                }
                results.append(contentsOf: collectAccessibleElements(childObj, depth: depth + 1))
            }
        } else {
            let count = element.accessibilityElementCount()
            if count != NSNotFound && count > 0 {
                for i in 0..<count {
                    guard let child = element.accessibilityElement(at: i) as? NSObject else {
                        continue
                    }
                    results.append(contentsOf: collectAccessibleElements(child, depth: depth + 1))
                }
            } else if let view = element as? UIView {
                for subview in view.subviews {
                    guard !subview.isHidden, subview.alpha > 0.01 else {
                        continue
                    }
                    results.append(contentsOf: collectAccessibleElements(subview, depth: depth + 1))
                }
            }
        }

        return results
    }

    private func accessibilityFrame(for element: NSObject) -> CGRect {
        let frame = element.accessibilityFrame
        guard frame != .zero else {
            guard let view = element as? UIView else {
                return .zero
            }
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

    private func viewControllerName(for element: NSObject) -> String {
        let view: UIView?
        if let v = element as? UIView {
            view = v
        } else {
            view = element.value(forKey: "accessibilityContainer") as? UIView
        }
        guard let view, let vc = UIUtils.owningViewController(for: view) else {
            return currentScreenName()
        }
        return String(describing: type(of: vc))
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

}
