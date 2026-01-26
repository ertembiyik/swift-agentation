import SwiftUI
import UIKit
import Agentation

@main
struct AgentationExampleApp: App {
    init() {
        // Agentation auto-installs when a scene becomes available.
        // You can also call install() explicitly for immediate setup.
        Agentation.shared.install()

        #if DEBUG
        Agentation.shared.enableShakeToStart()
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
