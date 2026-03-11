import SwiftUI
import UniversalGlass

struct FeedbackScreenView: View {

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditing: Bool {
        existingFeedback != nil
    }

    @State private var feedbackText: String

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    let element: SnapshotElement

    let existingFeedback: String?

    let onSubmit: (String) -> Void

    let onCancel: () -> Void

    init(element: SnapshotElement,
         existingFeedback: String? = nil,
         onSubmit: @escaping (String) -> Void,
         onCancel: @escaping () -> Void) {
        self.element = element
        self.existingFeedback = existingFeedback
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self._feedbackText = State(initialValue: existingFeedback ?? "")
    }

    var body: some View {
        NavigationStack {
            popupContent
                .navigationTitle(isEditing ? "Edit Feedback" : "Add Feedback")
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
                Text(isEditing ? "Save Changes" : "Add Feedback")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
            }
            .universalGlassEffect(.regular.tint(.purple).interactive())
            .disabled(trimmedFeedback.isEmpty)
            .opacity(trimmedFeedback.isEmpty ? 0.7 : 1)
            .padding(.horizontal, 20)
            .containerRelativeFrame(.horizontal, alignment: .center) { len, _ in
                len
            }
        }
        .padding(.vertical, 20)
    }

    private func handleSubmit() {
        guard !trimmedFeedback.isEmpty else {
            return
        }
        onSubmit(trimmedFeedback)
        dismiss()
    }

    private func handleCancel() {
        dismiss()
        onCancel()
    }

}
