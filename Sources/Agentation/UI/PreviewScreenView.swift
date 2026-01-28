import SwiftUI

struct PreviewScreenView: View {

    @Environment(\.dismiss) private var dismiss

    private var hasFeedback: Bool {
        !Agentation.shared.feedback.items.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasFeedback {
                    ContentUnavailableView(
                        "No Feedback Yet",
                        systemImage: "doc.text",
                        description: Text("Tap on elements to add feedback")
                    )
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screen: \(Agentation.shared.feedback.pageName)")
                                    .font(.headline)
                                Text("Frame: \(Int(Agentation.shared.feedback.viewportSize.width))x\(Int(Agentation.shared.feedback.viewportSize.height))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            ForEach(Array(Agentation.shared.feedback.items.enumerated()), id: \.element.id) { index, item in
                                FeedbackItemRow(index: index + 1, item: item) {
                                    Agentation.shared.removeFeedback(item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Feedback Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Copy", systemImage: "doc.on.doc") {
                        Agentation.shared.copyFeedback()
                    }
                    .disabled(!hasFeedback)
                }
            }
        }
    }
}

private struct FeedbackItemRow: View {
    let index: Int
    let item: FeedbackItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index). \(item.element.shortType)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text(item.element.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()
            }

            Text(item.element.path)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(item.feedback)
                .font(.subheadline)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
