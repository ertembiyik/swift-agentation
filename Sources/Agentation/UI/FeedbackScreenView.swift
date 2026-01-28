import SwiftUI
import UniversalGlass

struct FeedbackScreenView: View {

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
        .task {
            isFocused = true
        }
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
            .containerRelativeFrame(.horizontal, alignment: .center) { len, _ in
                len
            }
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
