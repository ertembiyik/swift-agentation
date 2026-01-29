import UIKit
import SwiftUI

@MainActor
@Observable
public final class Agentation {

    public enum State: Equatable {
        case idle
        case capturing
    }

    public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    public static let shared = Agentation()

    public private(set) var state: State = .idle
    public private(set) var feedback: PageFeedback = PageFeedback(pageName: "", viewportSize: .zero)
    public private(set) var isPaused: Bool = false

    public var outputFormat: OutputFormat = .markdown
    public var includeHiddenElements: Bool = false
    public var includeSystemViews: Bool = false

    public var isCapturing: Bool {
        state == .capturing
    }

    public var annotationCount: Int {
        feedback.items.count
    }

    private var overlayWindow: OverlayWindow?
    private var sceneObservationTask: Task<Void, Never>?
    var isToolbarVisible: Bool = true

    @ObservationIgnored
    var toolbarFrame: CGRect = .zero

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

    public func install(in scene: UIWindowScene? = nil) {
        let targetScene = scene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let windowScene = targetScene else { return }
        installIfNeeded(in: windowScene)
    }

    private func installIfNeeded(in scene: UIWindowScene) {
        guard overlayWindow == nil else { return }

        let window = OverlayWindow(scene: scene)
        window.isHidden = false
        overlayWindow = window

        sceneObservationTask?.cancel()
        sceneObservationTask = nil
    }

    public func start() {
        if state == .capturing {
            return
        }

        let inspector = HierarchyInspector.shared
        if feedback.items.isEmpty {
            feedback = PageFeedback(
                pageName: inspector.currentPageName(),
                viewportSize: inspector.viewportSize()
            )
        }

        dismissKeyboardGlobally()

        state = .capturing
        isPaused = false

        overlayWindow?.refreshHierarchy()
    }

    public func stop() {
        guard state == .capturing else { return }

        overlayWindow?.endEditing(true)
        overlayWindow?.clearHoverHighlight()
        restoreKeyWindowToApp()

        state = .idle
        isPaused = false
    }

    public func togglePause() {
        isPaused.toggle()

        viewControllerHierarchy()

        if isPaused {
            overlayWindow?.clearHoverHighlight()
        }
    }

    public func addFeedback(_ text: String, for element: ElementInfo) {
        let item = FeedbackItem(element: element, feedback: text)
        feedback.items.append(item)
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
    }

    public func updateFeedback(_ item: FeedbackItem, with text: String) {
        guard let index = feedback.items.firstIndex(where: { $0.id == item.id }) else { return }
        let updated = FeedbackItem(id: item.id, element: item.element, feedback: text, timestamp: item.timestamp)
        feedback.items[index] = updated
    }

    public func feedbackItem(for element: ElementInfo) -> FeedbackItem? {
        feedback.items.first { $0.element.id == element.id }
    }

    public func removeFeedback(_ item: FeedbackItem) {
        feedback.items.removeAll { $0.id == item.id }
        overlayWindow?.updateSelectedHighlights(for: feedback.items)
    }

    public func clearFeedback() {
        feedback.items.removeAll()
        overlayWindow?.clearAllHighlights()
    }

    @discardableResult
    public func copyFeedback() -> String? {
        let output = formatOutput()
        UIPasteboard.general.string = output
        return output
    }

    public func showToolbar() {
        isToolbarVisible = true
    }

    public func hideToolbar() {
        isToolbarVisible = false
    }

    public func captureHierarchy() -> [ElementInfo] {
        HierarchyInspector.shared.captureHierarchy()
    }

    public func debugHierarchy() -> String {
        HierarchyInspector.shared.printHierarchy()
    }

    public func viewControllerHierarchy() -> String {
        HierarchyInspector.shared.printViewControllerHierarchy()
    }

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

    private func dismissKeyboardGlobally() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func restoreKeyWindowToApp() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !(window is OverlayWindow) {
                if window.canBecomeKey {
                    window.makeKeyAndVisible()
                    return
                }
            }
        }
    }
}
