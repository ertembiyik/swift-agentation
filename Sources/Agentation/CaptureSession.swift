import UIKit

@MainActor
@Observable
public final class CaptureSession {

    let dataSource: any HierarchyDataSource
    public internal(set) var snapshot: HierarchySnapshot
    public internal(set) var isPaused: Bool = false
    public internal(set) var selectedElement: SnapshotElement?
    public private(set) var feedbackItems: [FeedbackItem]
    public let startedAt: Date

    public var annotationCount: Int { feedbackItems.count }

    init(
        dataSource: any HierarchyDataSource,
        snapshot: HierarchySnapshot,
        feedbackItems: [FeedbackItem] = [],
        startedAt: Date = Date()
    ) {
        self.dataSource = dataSource
        self.snapshot = snapshot
        self.feedbackItems = feedbackItems
        self.startedAt = startedAt
    }

    public func addFeedback(_ text: String, for element: SnapshotElement) {
        let item = FeedbackItem(
            elementId: element.id,
            text: text,
            elementDisplayName: element.displayName,
            elementShortType: element.shortType,
            elementFrame: element.frame,
            elementPath: element.path
        )
        feedbackItems.append(item)
    }

    public func updateFeedback(_ item: FeedbackItem, with text: String) {
        guard let index = feedbackItems.firstIndex(where: { $0.id == item.id }) else { return }
        feedbackItems[index] = FeedbackItem(
            id: item.id,
            elementId: item.elementId,
            text: text,
            elementDisplayName: item.elementDisplayName,
            elementShortType: item.elementShortType,
            elementFrame: item.elementFrame,
            elementPath: item.elementPath,
            createdAt: item.createdAt
        )
    }

    public func removeFeedback(_ item: FeedbackItem) {
        feedbackItems.removeAll { $0.id == item.id }
    }

    public func clearFeedback() {
        feedbackItems.removeAll()
    }

    public func feedbackItem(for elementId: UUID) -> FeedbackItem? {
        feedbackItems.first { $0.elementId == elementId }
    }

    public func elementHasFeedback(_ elementId: UUID) -> Bool {
        feedbackItems.contains { $0.elementId == elementId }
    }

    public func hitTest(point: CGPoint) -> SnapshotElement? {
        let candidates = snapshot.leafElements.filter { $0.frame.contains(point) }
        return candidates.min(by: { ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height) })
    }

    public func formatAsMarkdown() -> String {
        var output = "## Page Feedback: \(snapshot.pageName)\n"
        output += "**Viewport:** \(Int(snapshot.viewportSize.width))×\(Int(snapshot.viewportSize.height))\n\n"

        for (index, item) in feedbackItems.enumerated() {
            let number = index + 1
            let elementTitle = item.elementDisplayName.isEmpty
                ? item.elementShortType
                : "\(item.elementShortType) \"\(item.elementDisplayName)\""

            output += "### \(number). \(elementTitle)\n"
            output += "**Location:** \(item.elementPath)\n"

            let frame = item.elementFrame
            output += "**Frame:** x:\(Int(frame.origin.x)) y:\(Int(frame.origin.y)) w:\(Int(frame.size.width)) h:\(Int(frame.size.height))\n"
            output += "**Feedback:** \(item.text)\n\n"
        }

        return output
    }

    public func formatAsJSON() throws -> Data {
        struct Output: Encodable {
            let page: String
            let viewport: ViewportOutput
            let items: [ItemOutput]

            struct ViewportOutput: Encodable {
                let width: Int
                let height: Int
            }

            struct ItemOutput: Encodable {
                let type: String
                let displayName: String
                let path: String
                let frame: FrameOutput
                let feedback: String

                struct FrameOutput: Encodable {
                    let x: Int
                    let y: Int
                    let width: Int
                    let height: Int
                }
            }
        }

        let output = Output(
            page: snapshot.pageName,
            viewport: Output.ViewportOutput(
                width: Int(snapshot.viewportSize.width),
                height: Int(snapshot.viewportSize.height)
            ),
            items: feedbackItems.map { item in
                Output.ItemOutput(
                    type: item.elementShortType,
                    displayName: item.elementDisplayName,
                    path: item.elementPath,
                    frame: Output.ItemOutput.FrameOutput(
                        x: Int(item.elementFrame.origin.x),
                        y: Int(item.elementFrame.origin.y),
                        width: Int(item.elementFrame.size.width),
                        height: Int(item.elementFrame.size.height)
                    ),
                    feedback: item.text
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(output)
    }
}
