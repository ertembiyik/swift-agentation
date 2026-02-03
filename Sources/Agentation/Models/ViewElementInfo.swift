import CoreGraphics
import Foundation

struct ViewElementInfo: ElementProtocol, Sendable {
    let id: UUID
    let typeName: String
    let frame: CGRect
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let accessibilityHint: String
    let accessibilityValue: String
    let agentationTag: String
    let children: [ViewElementInfo]
    let path: String

    var displayName: String {
        if !accessibilityLabel.isEmpty { return accessibilityLabel }
        if !accessibilityIdentifier.isEmpty { return accessibilityIdentifier }
        if !agentationTag.isEmpty { return agentationTag }
        return typeName
    }

    var shortType: String {
        switch typeName {
        case let t where t.contains("Button"): return "button"
        case let t where t.contains("TextField") || t.contains("TextInput") || t.contains("TextEditor"): return "input"
        case let t where t.contains("Label") || t.contains("Text"): return "text"
        case let t where t.contains("Image"): return "image"
        case let t where t.contains("Switch") || t.contains("Toggle"): return "toggle"
        case let t where t.contains("Slider"): return "slider"
        case let t where t.contains("ScrollView"): return "scrollview"
        case let t where t.contains("TableView") || t.contains("List"): return "list"
        case let t where t.contains("CollectionView"): return "collection"
        case let t where t.contains("NavigationBar"): return "navbar"
        case let t where t.contains("TabBar"): return "tabbar"
        case let t where t.contains("Link"): return "link"
        default:
            return typeName
                .replacingOccurrences(of: "UI", with: "")
                .replacingOccurrences(of: "_", with: "")
                .lowercased()
        }
    }

    func leafElements() -> [SnapshotElement] {
        if children.isEmpty {
            return [SnapshotElement(id: id, displayName: displayName, shortType: shortType, frame: frame, path: path)]
        }
        return children.flatMap { $0.leafElements() }
    }
}
