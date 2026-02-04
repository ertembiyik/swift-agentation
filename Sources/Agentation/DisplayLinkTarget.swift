import UIKit

final class DisplayLinkTarget: @unchecked Sendable {

    private var displayLink: CADisplayLink?
    private let action: @MainActor () -> Void

    @MainActor
    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @MainActor
    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func invalidate() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        MainActor.assumeIsolated {
            action()
        }
    }
}
