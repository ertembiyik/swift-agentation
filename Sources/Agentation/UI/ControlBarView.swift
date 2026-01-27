import SwiftUI
import UIKit
import UniversalGlass

// MARK: - Agentation Toolbar View

/// The main toolbar view that morphs between collapsed and expanded states.
struct AgentationToolbarView: View {
    private let collapsedSize: CGFloat = 44
    private let controlBarHeight: CGFloat = 44

    @State private var position: CGPoint = .zero
    @State private var dragStartPosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var isInitialized = false
    @State private var showingSettings = false
    @State private var showingPreview = false
    @State private var copiedFeedback = false

    @Namespace private var morphNamespace

    var body: some View {
        GeometryReader { geometry in
            toolbarContent(in: geometry)
                .position(computePosition(in: geometry))
                .opacity(isInitialized && Agentation.shared.isToolbarVisible ? 1 : 0)
                .scaleEffect(Agentation.shared.isToolbarVisible ? 1 : 0.5)
                .gesture(dragGesture(in: geometry))
                .onAppear {
                    guard !isInitialized else { return }
                    position = loadOrDefaultPosition(in: geometry)
                    withAnimation(.easeOut(duration: 0.2)) {
                        isInitialized = true
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: Agentation.shared.isCapturing)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: Agentation.shared.isToolbarVisible)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingPreview) {
            PreviewSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }

    // MARK: - Toolbar Content

    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy) -> some View {
        UniversalGlassEffectContainer {
            if Agentation.shared.isCapturing {
                expandedControlBar
                    .universalGlassEffect(.regular.interactive(), in: .capsule)
                    .universalGlassEffectUnion(id: "agentationToolbar", namespace: morphNamespace)
            } else {
                triggerButton
                    .buttonStyle(.universalGlassProminent())
                    .universalGlassEffectUnion(id: "agentationToolbar", namespace: morphNamespace)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    // MARK: - Trigger Button (Collapsed State)

    private var triggerButton: some View {
        Button {
            Agentation.shared.start()
        } label: {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .overlay(alignment: .topTrailing) {
            if Agentation.shared.annotationCount > 0 {
                BadgeView(count: Agentation.shared.annotationCount)
                    .offset(x: 8, y: -8)
            }
        }
        .accessibilityLabel("Start Agentation")
    }

    // MARK: - Expanded Control Bar

    private var expandedControlBar: some View {
        HStack(spacing: 0) {
            ToolbarButton(
                icon: Agentation.shared.isPaused ? "play.fill" : "pause.fill",
                label: Agentation.shared.isPaused ? "Resume" : "Pause"
            ) {
                Agentation.shared.togglePause()
            }

            ToolbarDivider()

            ToolbarButton(icon: "eye", label: "Preview") {
                showingPreview = true
            }

            ToolbarButton(
                icon: copiedFeedback ? "checkmark" : "doc.on.doc",
                label: "Copy"
            ) {
                copyFeedback()
            }
            .disabled(Agentation.shared.annotationCount == 0)

            ToolbarButton(icon: "trash", label: "Clear") {
                Agentation.shared.clearFeedback()
            }
            .disabled(Agentation.shared.annotationCount == 0)

            ToolbarDivider()

            ToolbarButton(icon: "gearshape", label: "Settings") {
                showingSettings = true
            }

            ToolbarDivider()

            ToolbarButton(icon: "xmark", label: "Close") {
                Agentation.shared.stop()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Position Management

    private func computePosition(in geometry: GeometryProxy) -> CGPoint {
        guard isInitialized else {
            return defaultPosition(in: geometry)
        }

        // Center horizontally when expanded
        if Agentation.shared.isCapturing {
            return CGPoint(
                x: geometry.size.width / 2,
                y: position.y
            )
        }

        return position
    }

    private func defaultPosition(in geometry: GeometryProxy) -> CGPoint {
        let safeArea = geometry.safeAreaInsets
        let margin: CGFloat = 16

        return CGPoint(
            x: geometry.size.width - safeArea.trailing - collapsedSize / 2 - margin,
            y: geometry.size.height - safeArea.bottom - collapsedSize / 2 - margin
        )
    }

    private func loadOrDefaultPosition(in geometry: GeometryProxy) -> CGPoint {
        if let data = UserDefaults.standard.data(forKey: "AgentationToolbarPosition"),
           let saved = try? JSONDecoder().decode(CGPoint.self, from: data),
           saved != .zero {
            return clamp(saved, in: geometry)
        }
        return defaultPosition(in: geometry)
    }

    private func savePosition(_ point: CGPoint) {
        if let data = try? JSONEncoder().encode(point) {
            UserDefaults.standard.set(data, forKey: "AgentationToolbarPosition")
        }
    }

    private func clamp(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let safeArea = geometry.safeAreaInsets
        let margin: CGFloat = 8

        let effectiveWidth = Agentation.shared.isCapturing ? 300 : collapsedSize
        let halfWidth = effectiveWidth / 2
        let halfHeight = controlBarHeight / 2

        let minX = safeArea.leading + halfWidth + margin
        let maxX = geometry.size.width - safeArea.trailing - halfWidth - margin
        let minY = safeArea.top + halfHeight + margin
        let maxY = geometry.size.height - safeArea.bottom - halfHeight - margin

        return CGPoint(
            x: max(minX, min(maxX, point.x)),
            y: max(minY, min(maxY, point.y))
        )
    }

    private func snapToEdge(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let safeArea = geometry.safeAreaInsets
        let margin: CGFloat = 16
        let effectiveWidth = Agentation.shared.isCapturing ? 300 : collapsedSize
        let halfWidth = effectiveWidth / 2

        let leftEdge = safeArea.leading + halfWidth + margin
        let rightEdge = geometry.size.width - safeArea.trailing - halfWidth - margin

        let newX = point.x < geometry.size.width / 2 ? leftEdge : rightEdge
        return CGPoint(x: newX, y: point.y)
    }

    // MARK: - Drag Gesture

    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragStartPosition = position
                }
                let newPosition = CGPoint(
                    x: dragStartPosition.x + value.translation.width,
                    y: dragStartPosition.y + value.translation.height
                )
                position = clamp(newPosition, in: geometry)
            }
            .onEnded { _ in
                isDragging = false
                let snapped = snapToEdge(position, in: geometry)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    position = snapped
                }
                savePosition(snapped)
            }
    }

    // MARK: - Actions

    private func copyFeedback() {
        Agentation.shared.copyFeedback()

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

// MARK: - Badge View

private struct BadgeView: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(Color.blue, in: Capsule())
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Toolbar Divider

private struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.2))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 2)
    }
}

// MARK: - Preview Sheet

private struct PreviewSheet: View {
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

// MARK: - Feedback Item Row

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

// MARK: - Settings Sheet

private struct SettingsSheet: View {
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

// MARK: - Previews

#Preview("Toolbar - Collapsed") {
    AgentationToolbarView()
        .background(.gray.opacity(0.3))
}

#Preview("Toolbar - Active") {
    AgentationToolbarView()
        .background(.gray.opacity(0.3))
        .onAppear {
            Agentation.shared.start()
        }
}
