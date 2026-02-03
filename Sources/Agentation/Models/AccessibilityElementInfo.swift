import CoreGraphics
import Foundation
import UIKit

struct AccessibilityElementInfo: ElementProtocol, Sendable {
    let id: UUID
    let role: String
    let label: String
    let value: String
    let hint: String
    let frame: CGRect
    let traits: UIAccessibilityTraits
    let children: [AccessibilityElementInfo]
    let path: String

    var displayName: String {
        if !label.isEmpty { return label }
        if !role.isEmpty { return role }
        return "Element"
    }

    var shortType: String {
        role.isEmpty ? "element" : role.lowercased()
    }

    func leafElements() -> [SnapshotElement] {
        if children.isEmpty {
            return [SnapshotElement(id: id, displayName: displayName, shortType: shortType, frame: frame, path: path)]
        }
        return children.flatMap { $0.leafElements() }
    }
}
