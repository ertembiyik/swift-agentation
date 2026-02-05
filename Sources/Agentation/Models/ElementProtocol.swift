import CoreGraphics
import Foundation

@MainActor
protocol ElementProtocol: Identifiable {
    var displayName: String { get }
    var shortType: String { get }
    var frame: CGRect { get }
    var id: UUID { get }
}
