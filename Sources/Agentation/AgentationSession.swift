#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif os(macOS)
import AppKit
#endif
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

    public var onComplete: ((PageFeedback) -> Void)?
    public var onCopy: ((String) -> Void)?

    #if os(iOS) || targetEnvironment(macCatalyst)
    private var overlayWindow: OverlayWindow?
    #elseif os(macOS)
    private var overlayPanel: OverlayPanel?
    #endif

    public init() {
        let inspector = HierarchyInspector.shared
        self.feedback = PageFeedback(
            pageName: inspector.currentPageName(),
            viewportSize: inspector.viewportSize()
        )
    }

    public func start(from sourceFrame: CGRect? = nil) {
        guard !isActive else { return }

        let inspector = HierarchyInspector.shared
        feedback = PageFeedback(
            pageName: inspector.currentPageName(),
            viewportSize: inspector.viewportSize()
        )

        #if os(iOS) || targetEnvironment(macCatalyst)
        dismissKeyboardGlobally()

        let overlay = OverlayWindow(session: self, sourceFrame: sourceFrame)
        overlay.isHidden = false
        overlay.makeKeyAndVisible()
        overlayWindow = overlay
        #elseif os(macOS)
        guard let mainWindow = NSApplication.shared.windows.first(where: { !($0 is AgentationOverlayPanel) }) else {
            return
        }

        let overlay = OverlayPanel(session: self, contentRect: mainWindow.frame, sourceFrame: sourceFrame)
        overlay.orderFront(nil)
        overlayPanel = overlay
        #endif

        isActive = true
        isPaused = false
    }

    public func stop() {
        guard isActive else { return }

        #if os(iOS) || targetEnvironment(macCatalyst)
        overlayWindow?.endEditing(true)
        overlayWindow?.prepareForRemoval()
        overlayWindow?.isHidden = true
        overlayWindow?.resignKey()
        overlayWindow?.windowScene = nil
        overlayWindow = nil
        restoreKeyWindowToApp()
        #elseif os(macOS)
        overlayPanel?.prepareForRemoval()
        overlayPanel?.orderOut(nil)
        overlayPanel?.close()
        overlayPanel = nil
        #endif

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
        #if os(iOS) || targetEnvironment(macCatalyst)
        overlayWindow?.refreshHierarchy()
        #elseif os(macOS)
        overlayPanel?.refreshHierarchy()
        #endif
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
        #if os(iOS) || targetEnvironment(macCatalyst)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func clearHoverHighlight() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        overlayWindow?.clearHoverHighlight()
        #elseif os(macOS)
        overlayPanel?.clearHoverHighlight()
        #endif
    }

    private func updateSelectedHighlights() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
        #elseif os(macOS)
        overlayPanel?.updateSelectedHighlights(for: feedback.items)
        #endif
    }

    private func clearAllHighlights() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        overlayWindow?.clearAllHighlights()
        #elseif os(macOS)
        overlayPanel?.clearAllHighlights()
        #endif
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
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
    #endif
}
