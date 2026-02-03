import UIKit

@MainActor
protocol HierarchyDataSource {
    func capture() async -> HierarchySnapshot
}
