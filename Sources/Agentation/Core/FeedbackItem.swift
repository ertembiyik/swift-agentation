import CoreGraphics
import Foundation

/// A user annotation attached to a captured UI element.
///
/// Each feedback item records which element was annotated, the user's text, and enough
/// context (frame, path, screen) to produce meaningful output for an AI coding agent.
public struct FeedbackItem: Identifiable, Sendable {

    public let id: UUID
    public let elementId: UUID
    public let text: String
    public let elementDisplayName: String
    public let elementShortType: String
    public let elementFrame: CGRect
    public let elementPath: String
    public let screenName: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        elementId: UUID,
        text: String,
        elementDisplayName: String,
        elementShortType: String,
        elementFrame: CGRect,
        elementPath: String,
        screenName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.elementId = elementId
        self.text = text
        self.elementDisplayName = elementDisplayName
        self.elementShortType = elementShortType
        self.elementFrame = elementFrame
        self.elementPath = elementPath
        self.screenName = screenName
        self.createdAt = createdAt
    }

}
