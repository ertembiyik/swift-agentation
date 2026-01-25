import SwiftUI
import UIKit
import Agentation

@main
struct AgentationExampleApp: App {
    init() {
        #if DEBUG
        Agentation.shared.enableShakeToStart()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    SwiftUIDemoView()
                }
                .tabItem {
                    Label("SwiftUI", systemImage: "swift")
                }

                NavigationStack {
                    UIKitDemoViewWrapper()
                        .navigationTitle("UIKit Demo")
                }
                .tabItem {
                    Label("UIKit", systemImage: "hammer")
                }
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
