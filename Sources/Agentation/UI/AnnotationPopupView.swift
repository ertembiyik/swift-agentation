#if os(iOS) || targetEnvironment(macCatalyst) || os(macOS)
import SwiftUI

extension View {
    @ViewBuilder
    func universalGlassButtonStyle() -> some View {
        #if os(iOS) || targetEnvironment(macCatalyst)
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
        #elseif os(macOS)
        self.buttonStyle(.borderedProminent)
        #endif
    }
}

@MainActor
struct AnnotationPopupView: View {
    let element: ElementInfo
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var feedbackText: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        #if os(iOS) || targetEnvironment(macCatalyst)
        NavigationStack {
            popupContent
                .navigationTitle("Add Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if #available(iOS 26.0, macCatalyst 26.0, *) {
                            Button(role: .close, action: handleCancel)
                        } else {
                            Button(action: handleCancel) {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
        }
        .presentationDetents([.medium])
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            isFocused = true
        }
        #elseif os(macOS)
        VStack(spacing: 0) {
            HStack {
                Text("Add Feedback")
                    .font(.headline)
                Spacer()
                Button(action: handleCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            popupContent
        }
        .frame(width: 400, height: 300)
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            isFocused = true
        }
        #endif
    }

    private var popupContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(element.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("•")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text(element.shortType)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("What should change?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $feedbackText)
                        .font(.body)
                        .frame(minHeight: 100, maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .focused($isFocused)

                    Text("Describe the change...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                        .opacity(feedbackText.isEmpty ? 1 : 0)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button(action: handleSubmit) {
                Text("Add Feedback")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
            }
            .universalGlassButtonStyle()
            .disabled(trimmedFeedback.isEmpty)
            .padding(.horizontal, 20)
            #if os(iOS) || targetEnvironment(macCatalyst)
            .containerRelativeFrame(.horizontal, alignment: .center) { len, _ in
                len
            }
            #endif
        }
        .padding(.vertical, 20)
    }

    private func handleSubmit() {
        guard !trimmedFeedback.isEmpty else { return }
        dismiss()
        onSubmit(trimmedFeedback)
    }

    private func handleCancel() {
        dismiss()
        onCancel()
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
#Preview("Annotation Popup") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AnnotationPopupView(
                element: ElementInfo(
                    accessibilityLabel: "Profile byline",
                    accessibilityIdentifier: "profileByline",
                    typeName: "UILabel",
                    frame: CGRect(x: 100, y: 200, width: 200, height: 44),
                    path: ".Profile > .Header > #profileByline"
                ),
                onSubmit: { _ in },
                onCancel: {}
            )
        }
}
#endif

#endif
