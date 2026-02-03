import CoreGraphics
import Foundation

public struct FeedbackItem: Identifiable, Sendable {
    public let id: UUID
    public let elementId: UUID
    public let text: String
    public let elementDisplayName: String
    public let elementShortType: String
    public let elementFrame: CGRect
    public let elementPath: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        elementId: UUID,
        text: String,
        elementDisplayName: String,
        elementShortType: String,
        elementFrame: CGRect,
        elementPath: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.elementId = elementId
        self.text = text
        self.elementDisplayName = elementDisplayName
        self.elementShortType = elementShortType
        self.elementFrame = elementFrame
        self.elementPath = elementPath
        self.createdAt = createdAt
    }
}
