import UIKit
import SwiftUI

final class OverlayWindow: UIWindow {

    override var canBecomeKey: Bool {
        Agentation.shared.isCapturing
    }

    private var overlayHostingController: PassThroughHostingViewController<OverlayRootView>

    init(scene: UIWindowScene) {
        let rootVC = PassThroughHostingViewController(rootView: OverlayRootView())
        rootVC.view.backgroundColor = .clear
        self.overlayHostingController = rootVC

        super.init(windowScene: scene)

        self.rootViewController = rootVC
        self.windowLevel = .alert + 100
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let presented = overlayHostingController.presentedViewController?.view,
           let hit = presented.hitTest(convert(point, to: presented), with: event) {
            return hit
        }

        if let toolbarHit = overlayHostingController.view.hitTest(convert(point, to: overlayHostingController.view), with: event) {
            return toolbarHit
        }

        guard Agentation.shared.isCapturing else {
            return nil
        }

        return super.hitTest(point, with: event)
    }

}


