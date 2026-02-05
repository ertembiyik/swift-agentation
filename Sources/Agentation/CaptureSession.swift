import UIKit

@MainActor
@Observable
final class CaptureSession {

    var annotationCount: Int {
        feedbackItems.count
    }

    var feedbackByScreen: [(screenName: String, items: [FeedbackItem])] {
        var order: [String] = []
        var grouped: [String: [FeedbackItem]] = [:]

        for item in feedbackItems {
            if grouped[item.screenName] == nil {
                order.append(item.screenName)
            }
            grouped[item.screenName, default: []].append(item)
        }

        return order.map { (screenName: $0, items: grouped[$0]!) }
    }

    var snapshot: HierarchySnapshot
    var isPaused = false
    var selectedElement: SnapshotElement?
    var feedbackItems: [FeedbackItem]
    var liveFrames: [UUID: CGRect] = [:]

    @ObservationIgnored
    private var displayLinkTarget: DisplayLinkTarget?

    let startedAt: Date
    let dataSource: any HierarchyDataSource

    init(
        dataSource: any HierarchyDataSource,
        snapshot: HierarchySnapshot,
        feedbackItems: [FeedbackItem] = [],
        enableFrameTracking: Bool = false,
        startedAt: Date = Date()
    ) {
        self.dataSource = dataSource
        self.snapshot = snapshot
        self.feedbackItems = feedbackItems
        self.startedAt = startedAt
        if enableFrameTracking {
            startFrameTracking()
        }
    }

    deinit {
        displayLinkTarget?.invalidate()
    }

    func liveFrame(for item: FeedbackItem) -> CGRect {
        liveFrames[item.elementId] ?? item.elementFrame
    }

    func addFeedback(_ text: String, for element: SnapshotElement) {
        let item = FeedbackItem(
            elementId: element.id,
            text: text,
            elementDisplayName: element.displayName,
            elementShortType: element.shortType,
            elementFrame: element.frame,
            elementPath: element.path,
            screenName: snapshot.screenName
        )
        feedbackItems.append(item)
    }

    func updateFeedback(_ item: FeedbackItem, with text: String) {
        guard let index = feedbackItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        feedbackItems[index] = FeedbackItem(
            id: item.id,
            elementId: item.elementId,
            text: text,
            elementDisplayName: item.elementDisplayName,
            elementShortType: item.elementShortType,
            elementFrame: item.elementFrame,
            elementPath: item.elementPath,
            screenName: item.screenName,
            createdAt: item.createdAt
        )
    }

    func removeFeedback(_ item: FeedbackItem) {
        feedbackItems.removeAll { $0.id == item.id }
    }

    func clearFeedback() {
        feedbackItems.removeAll()
    }

    func feedbackItem(for elementId: UUID) -> FeedbackItem? {
        feedbackItems.first { $0.elementId == elementId }
    }

    func elementHasFeedback(_ elementId: UUID) -> Bool {
        feedbackItems.contains { $0.elementId == elementId }
    }

    func hitTest(point: CGPoint) -> SnapshotElement? {
        let candidates = snapshot.leafElements.filter { $0.frame.contains(point) }
        return candidates.min(by: { ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height) })
    }

    func formatAsMarkdown() -> String {
        var output = ""
        output += "**Viewport:** \(Int(snapshot.viewportSize.width))×\(Int(snapshot.viewportSize.height))\n\n"

        var itemNumber = 1
        for group in feedbackByScreen {
            output += "## \(group.screenName)\n\n"

            for item in group.items {
                let elementTitle = item.elementDisplayName.isEmpty
                    ? item.elementShortType
                    : "\(item.elementShortType) \"\(item.elementDisplayName)\""

                output += "### \(itemNumber). \(elementTitle)\n"
                output += "**Location:** \(item.elementPath)\n"

                let frame = item.elementFrame
                output += "**Frame:** x:\(Int(frame.origin.x)) y:\(Int(frame.origin.y)) w:\(Int(frame.size.width)) h:\(Int(frame.size.height))\n"
                output += "**Feedback:** \(item.text)\n\n"
                itemNumber += 1
            }
        }

        return output
    }

    func formatAsJSON() throws -> Data {
        struct Output: Encodable {
            let viewport: ViewportOutput
            let screens: [ScreenOutput]

            struct ViewportOutput: Encodable {
                let width: Int
                let height: Int
            }

            struct ScreenOutput: Encodable {
                let screen: String
                let items: [ItemOutput]
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
            viewport: Output.ViewportOutput(
                width: Int(snapshot.viewportSize.width),
                height: Int(snapshot.viewportSize.height)
            ),
            screens: feedbackByScreen.map { group in
                Output.ScreenOutput(
                    screen: group.screenName,
                    items: group.items.map { item in
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
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(output)
    }

    private func startFrameTracking() {
        let target = DisplayLinkTarget { [weak self] in
            self?.updateFrames()
        }
        target.start()
        displayLinkTarget = target
    }

    private func updateFrames() {
        for item in feedbackItems {
            if let frame = dataSource.resolve(elementId: item.elementId) {
                if liveFrames[item.elementId] != frame {
                    liveFrames[item.elementId] = frame
                }
            } else {
                liveFrames.removeValue(forKey: item.elementId)
            }
        }
    }
}
