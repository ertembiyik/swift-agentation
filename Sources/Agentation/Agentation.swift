import UIKit
import SwiftUI

@MainActor
public final class Agentation {

    public static let shared = Agentation()

    public private(set) var currentSession: AgentationSession?

    public var isActive: Bool {
        currentSession?.isActive ?? false
    }

    private var floatingButtonWindow: FloatingButtonWindow?

    private init() {}

    public func start(from sourceFrame: CGRect? = nil, onComplete: ((PageFeedback) -> Void)? = nil) {
        if let existing = currentSession, existing.isActive {
            existing.stop()
        }

        let session = AgentationSession()
        session.sourceFrame = sourceFrame
        session.onComplete = { [weak self] feedback in
            self?.showFloatingButtonAfterStop()
            self?.currentSession = nil
            onComplete?(feedback)
        }

        currentSession = session
        session.start()
    }

    public func stop() {
        currentSession?.stop()
        currentSession = nil
    }

    private func showFloatingButtonAfterStop() {
        floatingButtonWindow?.isHidden = false
    }

    public func togglePause() {
        currentSession?.togglePause()
    }

    @discardableResult
    public func copyFeedback() -> String? {
        guard let session = currentSession else { return nil }
        let output = formatFeedback(session.feedback, format: session.outputFormat)
        copyToClipboard(output)
        return output
    }

    public func clearFeedback() {
        currentSession?.clearFeedback()
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

    public func showFloatingButton() {
        guard floatingButtonWindow == nil else { return }
        let window = FloatingButtonWindow(onTap: toggleAgentation)
        window.isHidden = false
        floatingButtonWindow = window
    }

    public func hideFloatingButton() {
        floatingButtonWindow?.isHidden = true
        floatingButtonWindow = nil
    }

    private func toggleAgentation() {
        if isActive {
            stop()
        } else {
            let sourceFrame = floatingButtonWindow?.buttonFrame
            floatingButtonWindow?.isHidden = true
            start(from: sourceFrame)
        }
    }

    public func quickCapture(
        format: AgentationSession.OutputFormat = .markdown,
        completion: @escaping (String) -> Void
    ) {
        start { feedback in
            let output = formatFeedback(feedback, format: format)
            completion(output)
        }
    }
}

private func formatFeedback(_ feedback: PageFeedback, format: AgentationSession.OutputFormat) -> String {
    switch format {
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

#if DEBUG
extension Agentation {

    public func enableShakeToStart() {
        ShakeDetector.shared.onShake = { [weak self] in
            self?.toggleAgentation()
        }
        ShakeDetector.shared.isEnabled = true
    }
}

@MainActor
final class ShakeDetector {
    static let shared = ShakeDetector()

    var isEnabled = false
    var onShake: (() -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .deviceDidShake,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard self?.isEnabled == true else { return }
            self?.onShake?()
        }
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("AgentationDeviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}
#endif

@MainActor
private final class FloatingButtonWindow: UIWindow {

    private let onTap: () -> Void
    private var panGesture: UIPanGestureRecognizer?

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap

        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first

        super.init(frame: CGRect(x: 0, y: 0, width: 56, height: 56))

        if let windowScene {
            self.windowScene = windowScene
        }

        self.windowLevel = .alert + 50
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true

        let buttonView = FloatingButtonView(onTap: onTap)
        let hostingController = UIHostingController(rootView: buttonView)
        hostingController.view.backgroundColor = .clear
        self.rootViewController = hostingController

        positionWindow()
        setupPanGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func positionWindow() {
        guard let windowScene = self.windowScene else { return }

        let screenBounds = windowScene.screen.bounds
        let safeAreaInsets = windowScene.windows.first?.safeAreaInsets ?? .zero

        self.frame = CGRect(
            x: screenBounds.width - 56 - 16,
            y: screenBounds.height - 56 - safeAreaInsets.bottom - 16,
            width: 56,
            height: 56
        )
    }

    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(pan)
        self.panGesture = pan
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let windowScene = self.windowScene else { return }

        let translation = gesture.translation(in: self)
        let screenBounds = windowScene.screen.bounds
        let safeAreaInsets = windowScene.windows.first?.safeAreaInsets ?? .zero

        var newX = self.frame.origin.x + translation.x
        var newY = self.frame.origin.y + translation.y

        let minX: CGFloat = 8
        let maxX = screenBounds.width - 56 - 8
        let minY = safeAreaInsets.top + 8
        let maxY = screenBounds.height - 56 - safeAreaInsets.bottom - 8

        newX = max(minX, min(maxX, newX))
        newY = max(minY, min(maxY, newY))

        self.frame.origin = CGPoint(x: newX, y: newY)
        gesture.setTranslation(.zero, in: self)
    }

    var buttonFrame: CGRect {
        return self.frame
    }
}

private struct FloatingButtonView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
        }
        .universalGlassButtonStyle()
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

public struct AgentationTriggerButton: View {
    public init() {}

    public var body: some View {
        Button {
            if Agentation.shared.isActive {
                Agentation.shared.stop()
            } else {
                Agentation.shared.start()
            }
        } label: {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
        }
        .universalGlassButtonStyle()
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
