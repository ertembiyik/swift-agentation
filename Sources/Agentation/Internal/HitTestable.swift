import UIKit

protocol HitTestable {
    func contains(_ point: CGPoint) -> Bool
}
