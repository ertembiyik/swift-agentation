import Foundation

public struct FeedbackItem: Identifiable, Sendable {
    public let id: UUID
    public let element: ElementInfo
    public let feedback: String
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        element: ElementInfo,
        feedback: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.element = element
        self.feedback = feedback
        self.timestamp = timestamp
    }
}
