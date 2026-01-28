import SwiftUI

struct SettingsScreenView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Output Format") {
                    Picker("Format", selection: Bindable(Agentation.shared).outputFormat) {
                        Text("Markdown").tag(Agentation.OutputFormat.markdown)
                        Text("JSON").tag(Agentation.OutputFormat.json)
                    }
                }

                Section("Capture Options") {
                    Toggle("Include hidden elements", isOn: Bindable(Agentation.shared).includeHiddenElements)
                    Toggle("Include system views", isOn: Bindable(Agentation.shared).includeSystemViews)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
