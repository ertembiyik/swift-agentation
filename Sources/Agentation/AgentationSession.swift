import UIKit
import Observation

@MainActor
@Observable
public final class AgentationSession {

    public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    public private(set) var isActive: Bool = false
    public private(set) var isPaused: Bool = false
    public private(set) var feedback: PageFeedback

    public var outputFormat: OutputFormat = .markdown
    public var includeHiddenElements: Bool = false
    public var includeSystemViews: Bool = false
    public var sourceFrame: CGRect?

    public var onComplete: ((PageFeedback) -> Void)?
    public var onCopy: ((String) -> Void)?

    private var overlayWindow: OverlayWindow?

    public init() {
        let inspector = HierarchyInspector.shared
        self.feedback = PageFeedback(
            pageName: inspector.currentPageName(),
            viewportSize: inspector.viewportSize()
        )
    }

    public func start() {
        guard !isActive else { return }

        let inspector = HierarchyInspector.shared
        feedback = PageFeedback(
            pageName: inspector.currentPageName(),
            viewportSize: inspector.viewportSize()
        )

        dismissKeyboardGlobally()

        let overlay = OverlayWindow(session: self)
        overlay.isHidden = false
        overlay.makeKeyAndVisible()
        overlayWindow = overlay

        isActive = true
        isPaused = false
    }

    public func stop() {
        guard isActive else { return }

        overlayWindow?.endEditing(true)
        overlayWindow?.prepareForRemoval()
        overlayWindow?.isHidden = true
        overlayWindow?.resignKey()
        overlayWindow?.windowScene = nil
        overlayWindow = nil
        restoreKeyWindowToApp()

        isActive = false
        isPaused = false
        onComplete?(feedback)
    }

    public func togglePause() {
        isPaused.toggle()

        if isPaused {
            clearHoverHighlight()
        }
    }

    public func addFeedback(_ text: String, for element: ElementInfo) {
        let item = FeedbackItem(element: element, feedback: text)
        feedback.items.append(item)
        updateSelectedHighlights()
    }

    public func removeFeedback(_ item: FeedbackItem) {
        feedback.items.removeAll { $0.id == item.id }
        updateSelectedHighlights()
    }

    public func removeFeedback(for elementId: UUID) {
        feedback.items.removeAll { $0.element.id == elementId }
        updateSelectedHighlights()
    }

    public func clearFeedback() {
        feedback.items.removeAll()
        clearAllHighlights()
    }

    public func copyFeedback() {
        let output = formatOutput()
        copyToClipboard(output)
        onCopy?(output)
    }

    public func refreshHierarchy() {
        overlayWindow?.refreshHierarchy()
    }

    private func formatOutput() -> String {
        switch outputFormat {
        case .markdown:
            return feedback.toMarkdown()
        case .json:
            if let data = try? feedback.toJSON(),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
            return feedback.toMarkdown()
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    private func clearHoverHighlight() {
        overlayWindow?.clearHoverHighlight()
    }

    private func updateSelectedHighlights() {
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
    }

    private func clearAllHighlights() {
        overlayWindow?.clearAllHighlights()
    }

    private func dismissKeyboardGlobally() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func restoreKeyWindowToApp() {
        let allScenes = UIApplication.shared.connectedScenes
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !(window is AgentationOverlayWindow) {
                if window.canBecomeKey {
                    window.makeKeyAndVisible()
                    return
                }
            }
        }
    }
}
