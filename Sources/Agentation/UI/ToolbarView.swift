import SwiftUI
import UIKit
import UniversalGlass

var toolbarFrame: CGRect = .zero

struct ToolbarView: View, HitTestable {

    private struct GeometryInfo: Equatable {
        let rect: CGRect
        let safeAreaInsets: EdgeInsets
    }

    private struct ToolbarFrameHolder {
        let toolbarFrame: CGRect
    }

    private enum DragState: Equatable {
        case idle
        case dragging(startPosition: CGPoint)
    }

    private static let size: CGFloat = 44

    @State private var position: CGPoint = .zero
    @State private var dragState = DragState.idle
    @State private var showingSettings = false
    @State private var showingPreview = false
    @State private var copiedFeedback = false
    @State private var geometryInfo = GeometryInfo(rect: .zero, safeAreaInsets: .init())

    @Namespace private var morphNamespace

    var body: some View {
        toolbarContent
            .position(computePosition(in: geometryInfo))
            .gesture(dragGesture(in: geometryInfo))
            .onGeometryChange(for: GeometryInfo.self, of: { proxy in
                GeometryInfo(rect: proxy.frame(in: .global), safeAreaInsets: proxy.safeAreaInsets)
            }, action: { newValue in
                geometryInfo = newValue
            })
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: Agentation.shared.isCapturing)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragState)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: Agentation.shared.isToolbarVisible)
            .sheet(isPresented: $showingPreview) {
                PreviewScreenView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsScreenView()
            }
    }

    private var toolbarContent: some View {
        UniversalGlassEffectContainer {
            if Agentation.shared.isCapturing {
                expanded
                    .universalGlassEffect(.regular.interactive(), in: .capsule)
                    .universalGlassEffectUnion(id: "agentationToolbar", namespace: morphNamespace)
            } else {
                collapsed
                    .buttonStyle(.universalGlassProminent())
                    .universalGlassEffectUnion(id: "agentationToolbar", namespace: morphNamespace)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            toolbarFrame = newValue
        }
    }

    private var collapsed: some View {
        Button {
            Agentation.shared.start()
        } label: {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .tint(.purple)
        .overlay(alignment: .topTrailing) {
            if Agentation.shared.annotationCount > 0 {
                BadgeView(count: Agentation.shared.annotationCount)
                    .offset(x: 8, y: -8)
            }
        }
        .accessibilityLabel("Start Agentation")
    }

    private var expanded: some View {
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

    // MARK: - HitTestable

    func contains(_ point: CGPoint) -> Bool {
        toolbarFrame.contains(point)
    }

    private func computePosition(in geometryInfo: GeometryInfo) -> CGPoint {
        guard geometryInfo.rect != .zero else {
            return .zero
        }

        guard position != .zero else {
            return defaultPosition(in: geometryInfo)
        }

        // Center horizontally when expanded
        if Agentation.shared.isCapturing {
            return CGPoint(
                x: geometryInfo.rect.size.width / 2,
                y: position.y
            )
        }

        return position
    }

    private func defaultPosition(in geometryInfo: GeometryInfo) -> CGPoint {
        let safeArea = geometryInfo.safeAreaInsets
        let margin: CGFloat = 16

        return CGPoint(
            x: geometryInfo.rect.size.width - safeArea.trailing - Self.size / 2 - margin,
            y: geometryInfo.rect.size.height - safeArea.bottom - Self.size / 2 - margin
        )
    }

    private func clamp(_ point: CGPoint, in geometryInfo: GeometryInfo) -> CGPoint {
        let safeArea = geometryInfo.safeAreaInsets
        let margin: CGFloat = 8

        let effectiveWidth = Agentation.shared.isCapturing ? 300 : Self.size
        let halfWidth = effectiveWidth / 2
        let halfHeight = Self.size / 2

        let minX = safeArea.leading + halfWidth + margin
        let maxX = geometryInfo.rect.size.width - safeArea.trailing - halfWidth - margin
        let minY = safeArea.top + halfHeight + margin
        let maxY = geometryInfo.rect.size.height - safeArea.bottom - halfHeight - margin

        return CGPoint(
            x: max(minX, min(maxX, point.x)),
            y: max(minY, min(maxY, point.y))
        )
    }

    private func snapToEdge(_ point: CGPoint, in geometryInfo: GeometryInfo) -> CGPoint {
        let safeArea = geometryInfo.safeAreaInsets
        let margin: CGFloat = 16
        let effectiveWidth = Agentation.shared.isCapturing ? 300 : Self.size
        let halfWidth = effectiveWidth / 2

        let leftEdge = safeArea.leading + halfWidth + margin
        let rightEdge = geometryInfo.rect.size.width - safeArea.trailing - halfWidth - margin

        let newX = point.x < geometryInfo.rect.size.width / 2 ? leftEdge : rightEdge
        return CGPoint(x: newX, y: point.y)
    }

    private func dragGesture(in geometryInfo: GeometryInfo) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let dragStartPosition: CGPoint

                switch dragState {
                case .idle:
                    dragState = .dragging(startPosition: position)
                    dragStartPosition = position
                case .dragging(startPosition: let startPosition):
                    dragStartPosition = startPosition
                }

                let newPosition = CGPoint(
                    x: dragStartPosition.x + value.translation.width,
                    y: dragStartPosition.y + value.translation.height
                )

                position = clamp(newPosition, in: geometryInfo)
            }
            .onEnded { _ in
                dragState = .idle

                let snapped = snapToEdge(position, in: geometryInfo)

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    position = snapped
                }
            }
    }

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

private struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.2))
            .frame(width: 1, height: 20)
            .padding(.horizontal, 2)
    }
}


#Preview("Toolbar - Collapsed") {
    ToolbarView()
        .background(.gray.opacity(0.3))
}
