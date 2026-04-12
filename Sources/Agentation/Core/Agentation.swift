import UIKit
import SwiftUI

/// Visual feedback overlay for iOS applications.
///
/// Agentation provides a floating toolbar that lets users tap on UI elements, annotate them with feedback,
/// and copy the result as structured output suitable for AI coding agents.
///
/// The typical setup is a one-liner in your app's initializer:
/// ```swift
/// #if DEBUG
/// import Agentation
/// #endif
///
/// @main
/// struct MyApp: App {
///     init() {
///         #if DEBUG
///         Agentation.shared.install()
///         #endif
///     }
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
///
/// Once installed, a small floating button appears over your app. Tapping it starts a capture session
/// where every element on screen becomes tappable for annotation.
///
/// ### Programmatic Control
/// The capture lifecycle can also be driven from code:
/// ```swift
/// await Agentation.shared.start()
/// Agentation.shared.pause()
/// await Agentation.shared.resume()
/// Agentation.shared.stop()
/// ```
///
/// ### Output Formats
/// Feedback can be exported as Markdown (default) or JSON:
/// ```swift
/// Agentation.shared.outputFormat = .json
/// Agentation.shared.copyFeedback()
/// ```
@MainActor
@Observable
public final class Agentation {

    /// Serialization format for feedback output.
    nonisolated public enum OutputFormat: String, CaseIterable, Sendable {
        case markdown
        case json
    }

    enum State {
        case idle
        case capturing(CaptureSession)
    }

    /// Shared instance used throughout the application.
    public static let shared = Agentation()

    public var isCapturing: Bool {
        guard let session = activeSession else {
            return false
        }
        return !session.isPaused
    }

    /// True when a capture session exists, regardless of pause state.
    public var isActive: Bool {
        activeSession != nil
    }

    /// Number of feedback annotations in the current or most recent session.
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

    /// Which data source strategy to use when capturing the view hierarchy.
    ///
    /// The accessibility source (default) works well for both SwiftUI and UIKit.
    /// The view hierarchy source walks `UIView` trees directly, which gives full coverage
    /// in UIKit but requires `.agentationTag()` for SwiftUI views.
    public var selectedDataSourceType = DataSourceType.accessibility

    /// Controls whether ``copyFeedback()`` produces Markdown or JSON.
    public var outputFormat = OutputFormat.markdown

    /// When enabled, elements with very low alpha or zero size are included in snapshots.
    public var includeHiddenElements = false

    /// When enabled, system-provided views (keyboard, status bar internals) appear in snapshots.
    public var includeSystemViews = false

    /// Enables `CADisplayLink`-based tracking so annotation highlights follow moving elements.
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

}

// MARK: - Installation

extension Agentation {

    /// Installs the floating toolbar overlay into the given window scene.
    ///
    /// When called without arguments, Agentation picks the first available `UIWindowScene`.
    /// If no scene is connected yet (e.g. during early app launch), installation is deferred
    /// until a scene activates.
    /// ```swift
    /// Agentation.shared.install()
    /// ```
    /// You can target a specific scene when your app supports multiple windows:
    /// ```swift
    /// Agentation.shared.install(in: scene)
    /// ```
    public func install(in scene: UIWindowScene? = nil) {
        let targetScene = scene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene

        guard let targetScene else {
            startSceneObservationTask()
            return
        }

        installIfNeeded(in: targetScene)
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

}

// MARK: - Session Lifecycle

extension Agentation {

    /// Begins a new capture session, snapshotting the current view hierarchy.
    ///
    /// If a session is already active this method does nothing. Previous feedback annotations
    /// are carried forward into the new session.
    /// ```swift
    /// await Agentation.shared.start()
    /// ```
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

    /// Ends the current capture session.
    ///
    /// The session is preserved internally so ``copyFeedback()`` and ``annotationCount``
    /// continue to reflect the most recent work.
    public func stop() {
        guard let session = activeSession else {
            return
        }

        lastSession = session
        state = .idle
        overlayWindow?.endEditing(true)
    }

    /// Pauses element detection without ending the session.
    ///
    /// While paused, the app is fully interactive. Existing annotations remain visible
    /// but new taps pass through to the underlying UI.
    public func pause() {
        guard let session = activeSession, !session.isPaused else {
            return
        }

        session.selectedElement = nil
        session.isPaused = true
    }

    /// Resumes a paused session with a fresh hierarchy snapshot.
    public func resume() async {
        guard let session = activeSession, session.isPaused else {
            return
        }

        let snapshot = await dataSource.capture()

        session.snapshot = snapshot
        session.selectedElement = nil
        session.isPaused = false
    }

}

// MARK: - Feedback

extension Agentation {

    /// Copies all feedback annotations to the system pasteboard.
    ///
    /// The output format is controlled by ``outputFormat``. Returns the generated string,
    /// or `nil` if there's no session data to format.
    /// ```swift
    /// let output = Agentation.shared.copyFeedback()
    /// ```
    @discardableResult
    public func copyFeedback() -> String? {
        guard let session = activeSession ?? lastSession else {
            return nil
        }

        let output = formatOutput(for: session)
        UIPasteboard.general.string = output
        return output
    }

    /// Removes all feedback annotations from the active session.
    public func clearFeedback() {
        activeSession?.clearFeedback()
    }

    /// Takes a standalone hierarchy snapshot without starting a capture session.
    ///
    /// Useful for programmatic inspection or testing.
    public func captureHierarchy() async -> HierarchySnapshot {
        await dataSource.capture()
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

}

// MARK: - Toolbar Visibility

extension Agentation {

    /// Shows the floating toolbar if it was previously hidden.
    public func showToolbar() {
        isToolbarVisible = true
    }

    /// Hides the floating toolbar without ending the capture session.
    public func hideToolbar() {
        isToolbarVisible = false
    }

    private func dismissKeyboardGlobally() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}
