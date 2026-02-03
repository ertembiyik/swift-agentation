import UIKit
import SwiftUI

@MainActor
@Observable
public final class Agentation {

    public enum State {
        case idle
        case capturing(CaptureSession)
        case paused(CaptureSession)
    }

    public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    public static let shared = Agentation()

    public private(set) var state: State = .idle
    public private(set) var lastSession: CaptureSession?

    public var outputFormat: OutputFormat = .markdown
    public var includeHiddenElements: Bool = false
    public var includeSystemViews: Bool = false

    var isToolbarVisible: Bool = true

    @ObservationIgnored
    var toolbarFrame: CGRect = .zero

    private var overlayWindow: OverlayWindow?
    private var sceneObservationTask: Task<Void, Never>?

    public var selectedDataSourceType: DataSourceType = .viewHierarchy

    private let viewDataSource = ViewHierarchyDataSource()
    private let accessibilityDataSource = AccessibilityHierarchyDataSource()

    var dataSource: any HierarchyDataSource {
        switch selectedDataSourceType {
        case .viewHierarchy: viewDataSource
        case .accessibility: accessibilityDataSource
        }
    }

    public var activeSession: CaptureSession? {
        switch state {
        case .idle: return nil
        case .capturing(let session): return session
        case .paused(let session): return session
        }
    }

    public var isCapturing: Bool {
        if case .capturing = state { return true }
        return false
    }

    public var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    public var isActive: Bool {
        switch state {
        case .idle: return false
        case .capturing, .paused: return true
        }
    }

    public var annotationCount: Int {
        activeSession?.annotationCount ?? lastSession?.annotationCount ?? 0
    }

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

    public func start() async {
        guard case .idle = state else { return }

        dismissKeyboardGlobally()

        let snapshot = await dataSource.capture()

        let feedbackItems = lastSession?.feedbackItems ?? []

        let session = CaptureSession(
            dataSource: dataSource,
            snapshot: snapshot,
            feedbackItems: feedbackItems,
            startedAt: Date()
        )

        state = .capturing(session)
    }

    public func stop() {
        guard let session = activeSession else { return }
        lastSession = session
        state = .idle
        overlayWindow?.endEditing(true)
    }

    public func pause() {
        guard case .capturing(let session) = state else { return }
        session.selectedElement = nil
        state = .paused(session)
    }

    public func resume() async {
        guard case .paused(let session) = state else { return }

        let snapshot = await dataSource.capture()

        session.snapshot = snapshot
        session.selectedElement = nil

        state = .capturing(session)
    }

    @discardableResult
    public func copyFeedback() -> String? {
        guard let session = activeSession ?? lastSession else { return nil }
        let output = formatOutput(for: session)
        UIPasteboard.general.string = output
        return output
    }

    public func clearFeedback() {
        activeSession?.clearFeedback()
    }

    public func showToolbar() { isToolbarVisible = true }
    public func hideToolbar() { isToolbarVisible = false }

    public func captureHierarchy() async -> HierarchySnapshot {
        await dataSource.capture()
    }

    public func debugHierarchy() -> String {
        viewDataSource.printHierarchy()
    }

    @discardableResult
    public func viewControllerHierarchy() -> String {
        viewDataSource.printViewControllerHierarchy()
    }

    private func formatOutput(for session: CaptureSession) -> String {
        switch outputFormat {
        case .markdown:
            return session.formatAsMarkdown()
        case .json:
            if let data = try? session.formatAsJSON(), let json = String(data: data, encoding: .utf8) {
                return json
            }
            return session.formatAsMarkdown()
        }
    }

    private func dismissKeyboardGlobally() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
