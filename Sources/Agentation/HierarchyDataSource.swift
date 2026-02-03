import UIKit

enum ElementResolution {
    case view(UIView)
    case frame(CGRect)
}

@MainActor
protocol HierarchyDataSource {
    func capture() async -> HierarchySnapshot
    func resolve(elementId: UUID) -> ElementResolution?
}
