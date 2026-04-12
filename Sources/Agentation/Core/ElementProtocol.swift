import CoreGraphics
import Foundation

/// Common properties shared by all captured element types.
@MainActor
protocol ElementProtocol: Identifiable {
    var displayName: String { get }
    var shortType: String { get }
    var frame: CGRect { get }
    var id: UUID { get }
}
