import UIKit
import SwiftUI

// MARK: - Main Agentation Class

@Observable
public final class Agentation {

    // MARK: - State

    public enum State: Equatable {
        case idle
        case capturing
    }

    public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    // MARK: - Singleton

    @MainActor
    public static let shared = Agentation()

    // MARK: - Observable Properties

    public private(set) var state: State = .idle
    public private(set) var feedback: PageFeedback = PageFeedback(pageName: "", viewportSize: .zero)
    public private(set) var isPaused: Bool = false

    public var outputFormat: OutputFormat = .markdown
    public var includeHiddenElements: Bool = false
    public var includeSystemViews: Bool = false

    // MARK: - Computed Properties

    public var isCapturing: Bool {
        state == .capturing
    }

    public var annotationCount: Int {
        feedback.items.count
    }

    // MARK: - Internal State

    @MainActor
    private var overlayWindow: OverlayWindow?

    @MainActor
    private var sceneObservationTask: Task<Void, Never>?

    @MainActor
    var isToolbarVisible: Bool = true

    @ObservationIgnored
    var toolbarFrame: CGRect = .zero

    private var onCompleteCallback: ((PageFeedback) -> Void)?

    // MARK: - Initialization

    @MainActor
    private init() {
        sceneObservationTask = Task { @MainActor [weak self] in
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self?.installIfNeeded(in: scene)
            }

            for await notification in NotificationCenter.default.notifications(named: UIScene.didActivateNotification) {
                guard let self, self.overlayWindow == nil else { break }
                guard let scene = notification.object as? UIWindowScene else { continue }
                self.installIfNeeded(in: scene)
                break
            }
        }
    }

    // MARK: - Installation

    @MainActor
    public func install(in scene: UIWindowScene? = nil) {
        let targetScene = scene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let windowScene = targetScene else { return }
        installIfNeeded(in: windowScene)
    }

    @MainActor
    private func installIfNeeded(in scene: UIWindowScene) {
        guard overlayWindow == nil else { return }

        let window = OverlayWindow(scene: scene)
        window.isHidden = false
        overlayWindow = window

        sceneObservationTask?.cancel()
        sceneObservationTask = nil
    }

    // MARK: - Capture Control

    @MainActor
    public func start(onComplete: ((PageFeedback) -> Void)? = nil) {
        if state == .capturing {
            stop()
        }

        let inspector = HierarchyInspector.shared
        feedback = PageFeedback(
            pageName: inspector.currentPageName(),
            viewportSize: inspector.viewportSize()
        )

        dismissKeyboardGlobally()

        onCompleteCallback = onComplete
        state = .capturing
        isPaused = false

        overlayWindow?.refreshHierarchy()
    }

    @MainActor
    public func stop() {
        guard state == .capturing else { return }

        overlayWindow?.endEditing(true)
        overlayWindow?.clearAllHighlights()
        restoreKeyWindowToApp()

        state = .idle
        isPaused = false
        onCompleteCallback?(feedback)
        onCompleteCallback = nil
    }

    @MainActor
    public func togglePause() {
        isPaused.toggle()
        if isPaused {
            overlayWindow?.clearHoverHighlight()
        }
    }

    // MARK: - Feedback Management

    @MainActor
    public func addFeedback(_ text: String, for element: ElementInfo) {
        let item = FeedbackItem(element: element, feedback: text)
        feedback.items.append(item)
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
    }

    @MainActor
    public func removeFeedback(_ item: FeedbackItem) {
        feedback.items.removeAll { $0.id == item.id }
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
    }

    @MainActor
    public func clearFeedback() {
        feedback.items.removeAll()
        overlayWindow?.clearAllHighlights()
    }

    @MainActor
    @discardableResult
    public func copyFeedback() -> String? {
        let output = formatOutput()
        UIPasteboard.general.string = output
        return output
    }

    // MARK: - Toolbar Visibility

    @MainActor
    public func showToolbar() {
        isToolbarVisible = true
    }

    @MainActor
    public func hideToolbar() {
        isToolbarVisible = false
    }

    // MARK: - Hierarchy Inspection

    @MainActor
    public func captureHierarchy() -> [ElementInfo] {
        HierarchyInspector.shared.captureHierarchy()
    }

    @MainActor
    public func debugHierarchy() -> String {
        HierarchyInspector.shared.printHierarchy()
    }

    @MainActor
    public func viewControllerHierarchy() -> String {
        HierarchyInspector.shared.printViewControllerHierarchy()
    }

    // MARK: - Convenience

    @MainActor
    public func quickCapture(format: OutputFormat = .markdown, completion: @escaping (String) -> Void) {
        start { feedback in
            let output: String
            switch format {
            case .markdown:
                output = feedback.toMarkdown()
            case .json:
                if let data = try? feedback.toJSON(), let json = String(data: data, encoding: .utf8) {
                    output = json
                } else {
                    output = feedback.toMarkdown()
                }
            }
            completion(output)
        }
    }

    // MARK: - Internal

    @MainActor
    func refreshHierarchy() {
        overlayWindow?.refreshHierarchy()
    }

    private func formatOutput() -> String {
        switch outputFormat {
        case .markdown:
            return feedback.toMarkdown()
        case .json:
            if let data = try? feedback.toJSON(), let json = String(data: data, encoding: .utf8) {
                return json
            }
            return feedback.toMarkdown()
        }
    }

    @MainActor
    private func dismissKeyboardGlobally() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @MainActor
    private func restoreKeyWindowToApp() {
        for scene in UIApplication.shared.connectedScenes {
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
