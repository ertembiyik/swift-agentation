//
//  HierarchySnapshot.swift
//  Agentation
//
//  Created by Ertem Biyik on 2025.
//

import CoreGraphics
import Foundation

/// Strategy used to discover on-screen elements.
///
/// Agentation supports two approaches for walking the UI tree. The accessibility source
/// is recommended for most cases; the view hierarchy source is useful when you need
/// coverage of elements that aren't exposed to VoiceOver.
/// ```swift
/// Agentation.shared.selectedDataSourceType = .accessibility
/// ```
nonisolated public enum DataSourceType: String, CaseIterable, Sendable {
    /// Uses the iOS accessibility tree. Works well with both SwiftUI and UIKit.
    case accessibility
    /// Walks the `UIView` tree directly. Requires `.agentationTag()` for SwiftUI views.
    case viewHierarchy
}

/// A single element captured from the view hierarchy.
public struct SnapshotElement: Identifiable, Sendable {
    public let id: UUID
    public let displayName: String
    public let shortType: String
    public let frame: CGRect
    public let path: String
}

/// Point-in-time capture of the on-screen view hierarchy.
///
/// Created by ``Agentation/start()`` or ``Agentation/captureHierarchy()``.
/// Contains the flattened list of leaf elements that are available for annotation.
public struct HierarchySnapshot: Sendable {
    public let leafElements: [SnapshotElement]
    public let capturedAt: Date
    public let sourceType: DataSourceType
    public let viewportSize: CGSize
    public let screenName: String
}
