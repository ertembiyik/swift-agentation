import Foundation

struct WeakRef<T: AnyObject> {
    weak var value: T?
}
