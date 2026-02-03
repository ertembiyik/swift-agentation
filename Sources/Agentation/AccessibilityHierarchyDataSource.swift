import UIKit

@MainActor
final class AccessibilityHierarchyDataSource: HierarchyDataSource {

    private var frameLookup: [UUID: CGRect] = [:]

    func capture() async -> HierarchySnapshot {
        frameLookup.removeAll()

        return HierarchySnapshot(
            leafElements: [],
            capturedAt: Date(),
            sourceType: .accessibility,
            viewportSize: .zero,
            pageName: "Unknown"
        )
    }

    func resolve(elementId: UUID) -> ElementResolution? {
        guard let frame = frameLookup[elementId] else { return nil }
        return .frame(frame)
    }
}
