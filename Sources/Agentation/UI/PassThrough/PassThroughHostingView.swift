import SwiftUI
import UIKit



final class PassThroughHostingView<Content: View & HitTestable>: _UIHostingView<Content> {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let globalPoint = convert(point, to: nil)

        guard rootView.contains(globalPoint) else {
            return false
        }

        return super.point(inside: point, with: event)
    }

}
