#if os(iOS) || targetEnvironment(macCatalyst) || os(macOS)
import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif os(macOS)
import AppKit
#endif

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
        copyToClipboard(markdown)

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

    private func copyToClipboard(_ string: String) {
        #if os(iOS) || targetEnvironment(macCatalyst)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
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
                    #if os(iOS) || targetEnvironment(macCatalyst)
                    .listStyle(.insetGrouped)
                    #endif
                }
            }
            .navigationTitle("Feedback Preview")
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    private func handleCopy() {
        let markdown = session.feedback.toMarkdown()
        #if os(iOS) || targetEnvironment(macCatalyst)
        UIPasteboard.general.string = markdown
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        #endif
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
        #if os(iOS) || targetEnvironment(macCatalyst)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        #endif
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
            #if os(iOS) || targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 250)
        #endif
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
#Preview("Control Bar") {
    ControlBarView(session: AgentationSession())
        .padding()
        .background(Color.gray.opacity(0.3))
}
#endif

#endif
