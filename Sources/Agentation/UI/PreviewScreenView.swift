import SwiftUI

struct PreviewScreenView: View {

    @Environment(\.dismiss) private var dismiss

    private var session: CaptureSession? {
        Agentation.shared.activeSession ?? Agentation.shared.lastSession
    }

    private var hasFeedback: Bool {
        guard let session else { return false }
        return !session.feedbackItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session, hasFeedback {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screen: \(session.snapshot.pageName)")
                                    .font(.headline)
                                Text("Frame: \(Int(session.snapshot.viewportSize.width))x\(Int(session.snapshot.viewportSize.height))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            ForEach(Array(session.feedbackItems.enumerated()), id: \.element.id) { index, item in
                                FeedbackItemRow(index: index + 1, item: item) {
                                    session.removeFeedback(item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    ContentUnavailableView(
                        "No Feedback Yet",
                        systemImage: "doc.text",
                        description: Text("Tap on elements to add feedback")
                    )
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
                Text("\(index). \(item.elementShortType)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text(item.elementDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()
            }

            Text(item.elementPath)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(item.text)
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
