import CoreGraphics
import Foundation

public enum DataSourceType: String, CaseIterable, Sendable {
    case viewHierarchy
    case accessibility
}

public struct SnapshotElement: Identifiable, Sendable {
    public let id: UUID
    public let displayName: String
    public let shortType: String
    public let frame: CGRect
    public let path: String
}

public struct HierarchySnapshot: Sendable {
    public let leafElements: [SnapshotElement]
    public let capturedAt: Date
    public let sourceType: DataSourceType
    public let viewportSize: CGSize
    public let screenName: String
}
