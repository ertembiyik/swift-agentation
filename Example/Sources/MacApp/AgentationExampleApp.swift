import SwiftUI
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
            contentView
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Start Agentation") {
                    Agentation.shared.start { feedback in
                        print("=== Agentation Feedback ===")
                        print(feedback.toMarkdown())
                        print("===========================")
                    }
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
            }
        }
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(iOS)
        TabView {
            NavigationStack {
                SwiftUIDemoView()
            }
            .tabItem {
                Label("SwiftUI", systemImage: "swift")
            }

            NavigationStack {
                UIKitDemoViewWrapper()
            }
            .tabItem {
                Label("UIKit", systemImage: "hammer")
            }
        }
        #else
        NavigationStack {
            SwiftUIDemoView()
        }
        #endif
    }
}

#if os(iOS)
import UIKit

struct UIKitDemoViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitDemoViewController {
        UIKitDemoViewController()
    }

    func updateUIViewController(_ uiViewController: UIKitDemoViewController, context: Context) {}
}
#endif
