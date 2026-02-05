import UIKit
import SwiftUI

final class OverlayWindow: UIWindow {

    override var canBecomeKey: Bool {
        Agentation.shared.isCapturing
    }

    private let overlayHostingController: PassThroughHostingViewController<OverlayRootView>

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
        guard let result = super.hitTest(point, with: event), result != self else {
            return nil
        }

        return result
    }

}
