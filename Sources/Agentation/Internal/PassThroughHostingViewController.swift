import SwiftUI
import UIKit

final class PassThroughHostingViewController<Content: View & HitTestable>: UIViewController {

    private let rootView: Content

    init(rootView: Content) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PassThroughHostingView(rootView: rootView)
    }
}
