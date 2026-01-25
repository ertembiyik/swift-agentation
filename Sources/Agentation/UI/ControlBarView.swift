import SwiftUI
import UIKit

@MainActor
struct MorphingControlBar: View {
    @Bindable var session: AgentationSession
    let sourceFrame: CGRect
    let containerSize: CGSize

    @State private var isExpanded = false
    @State private var showingSettings = false
    @State private var showingPreview = false
    @State private var copiedFeedback = false

    @Namespace private var morphNamespace

    private let fabSize: CGFloat = 56
    private let controlBarHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isExpanded {
                    expandedView
                        .position(expandedPosition(in: geometry))
                } else {
                    collapsedView
                        .position(collapsedPosition(in: geometry))
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            PreviewSheet(session: session)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(session: session)
        }
    }

    private var collapsedView: some View {
        Image(systemName: "hand.tap.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: fabSize, height: fabSize)
            .background(.ultraThinMaterial, in: Circle())
            .matchedGeometryEffect(id: "controlShape", in: morphNamespace)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var expandedView: some View {
        HStack(spacing: 0) {
            ControlButton(
                icon: session.isPaused ? "play.fill" : "pause.fill",
                action: { session.togglePause() }
            )

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "eye",
                action: { showingPreview = true }
            )

            ControlButton(
                icon: copiedFeedback ? "checkmark" : "doc.on.doc",
                action: { copyFeedback() }
            )

            ControlButton(
                icon: "trash",
                action: { session.clearFeedback() }
            )
            .disabled(session.feedback.items.isEmpty)

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "gearshape",
                action: { showingSettings = true }
            )

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "xmark",
                action: { session.stop() }
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .matchedGeometryEffect(id: "controlShape", in: morphNamespace)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    private func collapsedPosition(in geometry: GeometryProxy) -> CGPoint {
        CGPoint(
            x: sourceFrame.midX,
            y: sourceFrame.midY
        )
    }

    private func expandedPosition(in geometry: GeometryProxy) -> CGPoint {
        let safeAreaBottom: CGFloat = 34
        return CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height - controlBarHeight / 2 - safeAreaBottom - 20
        )
    }

    private func copyFeedback() {
        let markdown = session.feedback.toMarkdown()
        UIPasteboard.general.string = markdown

        withAnimation {
            copiedFeedback = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation {
                copiedFeedback = false
            }
        }
    }
}

@MainActor
struct ControlBarView: View {
    @Bindable var session: AgentationSession

    @State private var showingSettings = false
    @State private var showingPreview = false
    @State private var copiedFeedback = false

    var body: some View {
        HStack(spacing: 0) {
            ControlButton(
                icon: session.isPaused ? "play.fill" : "pause.fill",
                action: { session.togglePause() }
            )

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "eye",
                action: { showingPreview = true }
            )

            ControlButton(
                icon: copiedFeedback ? "checkmark" : "doc.on.doc",
                action: { copyFeedback() }
            )

            ControlButton(
                icon: "trash",
                action: { session.clearFeedback() }
            )
            .disabled(session.feedback.items.isEmpty)

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "gearshape",
                action: { showingSettings = true }
            )

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.2))

            ControlButton(
                icon: "xmark",
                action: { session.stop() }
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showingPreview) {
            PreviewSheet(session: session)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(session: session)
        }
    }

    private func copyFeedback() {
        let markdown = session.feedback.toMarkdown()
        UIPasteboard.general.string = markdown

        withAnimation {
            copiedFeedback = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation {
                copiedFeedback = false
            }
        }
    }
}

private struct ControlButton: View {
    let icon: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PreviewSheet: View {
    @Bindable var session: AgentationSession
    @Environment(\.dismiss) private var dismiss

    private var hasFeedback: Bool {
        !session.feedback.items.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasFeedback {
                    ContentUnavailableView(
                        "No Feedback Yet",
                        systemImage: "doc.text",
                        description: Text("Click on elements to add feedback")
                    )
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screen: \(session.feedback.pageName)")
                                    .font(.headline)
                                Text("Frame: \(Int(session.feedback.viewportSize.width))×\(Int(session.feedback.viewportSize.height))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            ForEach(Array(session.feedback.items.enumerated()), id: \.element.id) { index, item in
                                FeedbackItemRow(index: index + 1, item: item) {
                                    session.removeFeedback(item)
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
                    Button("Copy", systemImage: "doc.on.doc", action: handleCopy)
                        .disabled(!hasFeedback)
                }
            }
        }
    }

    private func handleCopy() {
        let markdown = session.feedback.toMarkdown()
        UIPasteboard.general.string = markdown
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
            Button(role: .destructive) {
                onDelete()
            } label: {
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

private struct SettingsSheet: View {
    @Bindable var session: AgentationSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Output Format") {
                    Picker("Format", selection: $session.outputFormat) {
                        Text("Markdown").tag(AgentationSession.OutputFormat.markdown)
                        Text("JSON").tag(AgentationSession.OutputFormat.json)
                    }
                }

                Section("Capture Options") {
                    Toggle("Include hidden elements", isOn: $session.includeHiddenElements)
                    Toggle("Include system views", isOn: $session.includeSystemViews)
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

#Preview("Control Bar") {
    ControlBarView(session: AgentationSession())
        .padding()
        .background(Color.gray.opacity(0.3))
}
