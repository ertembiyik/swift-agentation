import UIKit
import SwiftUI

final class OverlayWindow: UIWindow {

    override var canBecomeKey: Bool {
        Agentation.shared.isCapturing
    }

    private var overlayHostingController: UIHostingController<OverlayRootView>
    private var toolbarHostingView: PassThroughHostingView<ToolbarView>

    init(scene: UIWindowScene) {
        let rootVC = UIHostingController(rootView: OverlayRootView())
        rootVC.view.backgroundColor = .clear
        self.overlayHostingController = rootVC

        let toolbarView = ToolbarView()
        let toolbarHostingView = PassThroughHostingView(rootView: toolbarView)
        self.toolbarHostingView = toolbarHostingView

        super.init(windowScene: scene)

        self.rootViewController = rootVC
        self.windowLevel = .alert + 100
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true

        self.addSubview(toolbarHostingView)
        self.bringSubviewToFront(toolbarHostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        toolbarHostingView.frame = overlayHostingController.view.bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let presented = rootViewController?.presentedViewController?.view,
           let hit = presented.hitTest(convert(point, to: presented), with: event) {
            return hit
        }

        if let toolbarHit = toolbarHostingView.hitTest(convert(point, to: toolbarHostingView), with: event) {
            return toolbarHit
        }

        guard Agentation.shared.isCapturing else {
            return nil
        }

        return super.hitTest(point, with: event)
    }
}

private struct OverlayRootView: View {

    var body: some View {
        if let session = Agentation.shared.activeSession {
            if session.isPaused {
                PausedOverlayView(session: session)
            } else {
                CaptureOverlayView(session: session)
            }
        }
    }
}
