import Foundation
import CoreGraphics

public struct ElementInfo: Identifiable, Sendable {
    public let id: UUID
    public let accessibilityLabel: String?
    public let accessibilityIdentifier: String?
    public let accessibilityHint: String?
    public let accessibilityValue: String?
    public let typeName: String
    public let frame: CGRect
    public let path: String
    public let children: [ElementInfo]
    public let debugDescription: String?
    public let agentationTag: String?

    public init(
        id: UUID = UUID(),
        accessibilityLabel: String? = nil,
        accessibilityIdentifier: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        typeName: String,
        frame: CGRect,
        path: String,
        children: [ElementInfo] = [],
        debugDescription: String? = nil,
        agentationTag: String? = nil
    ) {
        self.id = id
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.typeName = typeName
        self.frame = frame
        self.path = path
        self.children = children
        self.debugDescription = debugDescription
        self.agentationTag = agentationTag
    }

    public var displayName: String {
        if let label = accessibilityLabel, !label.isEmpty {
            return label
        }
        if let identifier = accessibilityIdentifier, !identifier.isEmpty {
            return identifier
        }
        if let tag = agentationTag, !tag.isEmpty {
            return tag
        }
        return typeName
    }

    public var shortType: String {
        let name = typeName
            .replacingOccurrences(of: "UI", with: "")
            .replacingOccurrences(of: "_", with: "")

        switch typeName {
        case let t where t.contains("Button"):
            return "button"
        case let t where t.contains("TextField") || t.contains("TextInput") || t.contains("TextEditor"):
            return "input"
        case let t where t.contains("Label") || t.contains("Text"):
            return "text"
        case let t where t.contains("Image"):
            return "image"
        case let t where t.contains("Switch") || t.contains("Toggle"):
            return "toggle"
        case let t where t.contains("Slider"):
            return "slider"
        case let t where t.contains("ScrollView"):
            return "scrollview"
        case let t where t.contains("TableView") || t.contains("List"):
            return "list"
        case let t where t.contains("CollectionView"):
            return "collection"
        case let t where t.contains("NavigationBar"):
            return "navbar"
        case let t where t.contains("TabBar"):
            return "tabbar"
        case let t where t.contains("Link"):
            return "link"
        default:
            return name.lowercased()
        }
    }

    public func flattened() -> [ElementInfo] {
        var result = [self]
        for child in children {
            result.append(contentsOf: child.flattened())
        }
        return result
    }

    public func elementAt(point: CGPoint) -> ElementInfo? {
        var candidates: [ElementInfo] = []
        collectElementsContaining(point: point, into: &candidates)
        return candidates.min(by: { elementArea($0) < elementArea($1) })
    }

    private func collectElementsContaining(point: CGPoint, into candidates: inout [ElementInfo]) {
        guard frame.contains(point) else { return }
        candidates.append(self)
        for child in children {
            child.collectElementsContaining(point: point, into: &candidates)
        }
    }

    private func elementArea(_ element: ElementInfo) -> CGFloat {
        element.frame.width * element.frame.height
    }
}
