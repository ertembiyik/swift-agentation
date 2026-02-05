import UIKit

@MainActor
enum UIUtils {

    static func owningViewController(for view: UIView) -> UIViewController? {
        var current: UIView? = view
        while let v = current {
            if let vc = v.value(forKey: "viewDelegate") as? UIViewController,
               !(vc is UINavigationController),
               !(vc is UITabBarController) {
                return vc
            }
            current = v.superview
        }
        return nil
    }

}
