import SwiftUI
import Agentation

@main
struct AgentationExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SwiftUIDemoView()
            }
            .frame(minWidth: 400, minHeight: 600)
        }
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
    }
}
