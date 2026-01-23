#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI

@MainActor
public final class Agentation {

    public static let shared = Agentation()

    public private(set) var currentSession: AgentationSession?

    public var isActive: Bool {
        currentSession?.isActive ?? false
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    private var floatingButtonWindow: FloatingButtonWindow?
    #elseif os(macOS)
    private var floatingButtonPanel: FloatingButtonPanel?
    #endif

    private init() {}

    public func start(from sourceFrame: CGRect? = nil, onComplete: ((PageFeedback) -> Void)? = nil) {
        if let existing = currentSession, existing.isActive {
            existing.stop()
        }

        let session = AgentationSession()
        session.onComplete = { [weak self] feedback in
            self?.currentSession = nil
            onComplete?(feedback)
        }

        currentSession = session
        session.start(from: sourceFrame)
    }

    public func stop() {
        currentSession?.stop()
        currentSession = nil
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

    #if os(iOS) || targetEnvironment(macCatalyst)
    public func viewControllerHierarchy() -> String {
        HierarchyInspector.shared.printViewControllerHierarchy()
    }
    #endif

    public func showFloatingButton() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        guard floatingButtonWindow == nil else { return }
        let window = FloatingButtonWindow(onTap: toggleAgentation)
        window.isHidden = false
        floatingButtonWindow = window
        #elseif os(macOS)
        guard floatingButtonPanel == nil else { return }
        let panel = FloatingButtonPanel(onTap: toggleAgentation)
        panel.orderFront(nil)
        floatingButtonPanel = panel
        #endif
    }

    public func hideFloatingButton() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        floatingButtonWindow?.isHidden = true
        floatingButtonWindow = nil
        #elseif os(macOS)
        floatingButtonPanel?.orderOut(nil)
        floatingButtonPanel?.close()
        floatingButtonPanel = nil
        #endif
    }

    private func toggleAgentation() {
        if isActive {
            stop()
        } else {
            start()
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
    #if os(iOS) || targetEnvironment(macCatalyst)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
}

#if os(iOS) || targetEnvironment(macCatalyst)
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
}

#elseif os(macOS)

@MainActor
private final class FloatingButtonPanel: NSPanel {

    private let onTap: () -> Void

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap

        let buttonSize: CGFloat = 56

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: buttonSize, height: buttonSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true

        let buttonView = FloatingButtonView(onTap: onTap)
        let hostingView = NSHostingView(rootView: buttonView)
        self.contentView = hostingView

        positionPanel()
    }

    private func positionPanel() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let buttonSize: CGFloat = 56
        let margin: CGFloat = 16

        self.setFrameOrigin(NSPoint(
            x: screenFrame.maxX - buttonSize - margin,
            y: screenFrame.minY + margin
        ))
    }
}

#endif

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
