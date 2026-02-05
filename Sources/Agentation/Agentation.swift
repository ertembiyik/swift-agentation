import UIKit
import SwiftUI

@MainActor
@Observable
public final class Agentation {

    public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    enum State {
        case idle
        case capturing(CaptureSession)
    }

    public static let shared = Agentation()

    public var isCapturing: Bool {
        guard let session = activeSession else {
            return false
        }
        return !session.isPaused
    }

    public var isActive: Bool {
        activeSession != nil
    }

    public var annotationCount: Int {
        activeSession?.annotationCount ?? lastSession?.annotationCount ?? 0
    }

    var dataSource: any HierarchyDataSource {
        switch selectedDataSourceType {
        case .viewHierarchy: viewDataSource
        case .accessibility: accessibilityDataSource
        }
    }

    var activeSession: CaptureSession? {
        if case .capturing(let session) = state {
            return session
        }

        return nil
    }

    public var selectedDataSourceType = DataSourceType.accessibility
    public var outputFormat = OutputFormat.markdown
    public var includeHiddenElements = false
    public var includeSystemViews = false
    public var experimentalFrameTracking = false

    var isToolbarVisible = true
    var lastSession: CaptureSession?

    @ObservationIgnored
    var toolbarFrame: CGRect = .zero

    private var state = State.idle
    private var overlayWindow: OverlayWindow?
    private var sceneObservationTask: Task<Void, Never>?

    private let viewDataSource = ViewHierarchyDataSource()
    private let accessibilityDataSource = AccessibilityHierarchyDataSource()

    private init() { }

    public func install(in scene: UIWindowScene? = nil) {
        let targetScene = scene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene

        guard let targetScene else {
            startSceneObservationTask()

            return
        }

        installIfNeeded(in: targetScene)
    }

    public func start() async {
        guard case .idle = state else {
            return
        }

        dismissKeyboardGlobally()

        let snapshot = await dataSource.capture()

        let feedbackItems = lastSession?.feedbackItems ?? []

        let session = CaptureSession(
            dataSource: dataSource,
            snapshot: snapshot,
            feedbackItems: feedbackItems,
            enableFrameTracking: experimentalFrameTracking,
            startedAt: Date()
        )

        state = .capturing(session)
    }

    public func stop() {
        guard let session = activeSession else {
            return
        }

        lastSession = session
        state = .idle
        overlayWindow?.endEditing(true)
    }

    public func pause() {
        guard let session = activeSession, !session.isPaused else {
            return
        }

        session.selectedElement = nil
        session.isPaused = true
    }

    public func resume() async {
        guard let session = activeSession, session.isPaused else {
            return
        }

        let snapshot = await dataSource.capture()

        session.snapshot = snapshot
        session.selectedElement = nil
        session.isPaused = false
    }

    @discardableResult
    public func copyFeedback() -> String? {
        guard let session = activeSession ?? lastSession else {
            return nil
        }

        let output = formatOutput(for: session)
        UIPasteboard.general.string = output
        return output
    }

    public func clearFeedback() {
        activeSession?.clearFeedback()
    }

    public func showToolbar() {
        isToolbarVisible = true
    }

    public func hideToolbar() {
        isToolbarVisible = false
    }

    public func captureHierarchy() async -> HierarchySnapshot {
        await dataSource.capture()
    }

    private func startSceneObservationTask() {
        sceneObservationTask?.cancel()
        sceneObservationTask = nil

        sceneObservationTask = Task { @MainActor [weak self] in
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self?.installIfNeeded(in: scene)
            }

            for await notification in NotificationCenter.default.notifications(named: UIScene.didActivateNotification) {
                guard let self, self.overlayWindow == nil else {
                    break
                }

                guard let scene = notification.object as? UIWindowScene else {
                    continue
                }

                self.installIfNeeded(in: scene)
                break
            }
        }
    }

    private func installIfNeeded(in scene: UIWindowScene) {
        guard overlayWindow == nil else {
            return
        }

        let window = OverlayWindow(scene: scene)
        window.isHidden = false
        overlayWindow = window

        sceneObservationTask?.cancel()
        sceneObservationTask = nil
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
