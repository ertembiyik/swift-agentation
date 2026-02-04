import UIKit
import SwiftUI

final class PassThroughHostingViewController<Content: View & HitTestable>: UIViewController {

    private let rootView: Content

    init(rootView: Content) {
        self.rootView = rootView

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PassThroughHostingView(rootView: rootView)
    }

}
