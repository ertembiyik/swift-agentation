import CoreGraphics
import Foundation

@MainActor
protocol ElementProtocol: Identifiable {
    var id: UUID { get }
    var displayName: String { get }
    var shortType: String { get }
    var frame: CGRect { get }
}
