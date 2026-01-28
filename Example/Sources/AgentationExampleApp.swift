import SwiftUI
import UIKit
#if DEBUG
import Agentation
#endif

@main
struct AgentationExampleApp: App {

    init() {
#if DEBUG
        Agentation.shared.install()
#endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SwiftUIDemoView()
            }
        }
    }
}

struct UIKitDemoViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIKitDemoViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
