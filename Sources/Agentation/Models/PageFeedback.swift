import Foundation
import CoreGraphics

public struct PageFeedback: Sendable {
    public let pageName: String
    public let viewportSize: CGSize
    public var items: [FeedbackItem]
    public let captureStarted: Date

    public init(
        pageName: String,
        viewportSize: CGSize,
        items: [FeedbackItem] = [],
        captureStarted: Date = Date()
    ) {
        self.pageName = pageName
        self.viewportSize = viewportSize
        self.items = items
        self.captureStarted = captureStarted
    }

    public func toMarkdown() -> String {
        var output = "## Page Feedback: \(pageName)\n"
        output += "**Viewport:** \(Int(viewportSize.width))×\(Int(viewportSize.height))\n\n"

        for (index, item) in items.enumerated() {
            let number = index + 1
            let element = item.element

            let elementTitle: String
            if let label = element.accessibilityLabel, !label.isEmpty {
                elementTitle = "\(element.shortType) \"\(label)\""
            } else if let identifier = element.accessibilityIdentifier, !identifier.isEmpty {
                elementTitle = "\(element.shortType) #\(identifier)"
            } else if let tag = element.agentationTag, !tag.isEmpty {
                elementTitle = "\(element.shortType) [\(tag)]"
            } else {
                elementTitle = element.shortType
            }

            output += "### \(number). \(elementTitle)\n"
            output += "**Location:** \(element.path)\n"

            let frame = element.frame
            output += "**Frame:** x:\(Int(frame.origin.x)) y:\(Int(frame.origin.y)) w:\(Int(frame.size.width)) h:\(Int(frame.size.height))\n"

            output += "**Feedback:** \(item.feedback)\n\n"
        }

        return output
    }

    public func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

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
                let label: String?
                let identifier: String?
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
            page: pageName,
            viewport: Output.ViewportOutput(
                width: Int(viewportSize.width),
                height: Int(viewportSize.height)
            ),
            items: items.map { item in
                Output.ItemOutput(
                    type: item.element.shortType,
                    label: item.element.accessibilityLabel,
                    identifier: item.element.accessibilityIdentifier,
                    path: item.element.path,
                    frame: Output.ItemOutput.FrameOutput(
                        x: Int(item.element.frame.origin.x),
                        y: Int(item.element.frame.origin.y),
                        width: Int(item.element.frame.size.width),
                        height: Int(item.element.frame.size.height)
                    ),
                    feedback: item.feedback
                )
            }
        )

        return try encoder.encode(output)
    }
}
