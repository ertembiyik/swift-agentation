import SwiftUI

struct CaptureOverlayView: View {

    let session: CaptureSession

    @State private var feedbackTarget: SnapshotElement?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.01)

            Canvas { context, _ in
                if let selected = session.selectedElement {
                    drawHighlight(selected, color: .blue, lineWidth: 2.5, fillOpacity: 0.15, in: &context)
                }
            }
            .allowsHitTesting(false)

            ForEach(session.feedbackItems) { item in
                if session.selectedElement?.id != item.elementId {
                    let frame = session.liveFrame(for: item)
                    Button {
                        feedbackTarget = SnapshotElement(
                            id: item.elementId,
                            displayName: item.elementDisplayName,
                            shortType: item.elementShortType,
                            frame: frame,
                            path: item.elementPath
                        )
                    } label: {
                        Rectangle()
                            .fill(Color.green.opacity(0.1))
                            .overlay(Rectangle().stroke(Color.green, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                }
            }

            if let selected = session.selectedElement {
                selectedElementLabel(selected)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .global) { location in
            let element = session.hitTest(point: location)
            session.selectedElement = element
            guard let element else {
                return
            }
            feedbackTarget = element
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 3, coordinateSpace: .global)
                .onChanged { value in
                    session.selectedElement = session.hitTest(point: value.location)
                }
        )
        .sheet(item: $feedbackTarget, onDismiss: {
            session.selectedElement = nil
        }) { element in
            FeedbackScreenView(
                element: element,
                existingFeedback: session.feedbackItem(for: element.id)?.text,
                onSubmit: { text in
                    if let existing = session.feedbackItem(for: element.id) {
                        session.updateFeedback(existing, with: text)
                    } else {
                        session.addFeedback(text, for: element)
                    }
                },
                onCancel: {}
            )
            .presentationDetents([.medium])
        }
    }

    private func drawHighlight(_ element: SnapshotElement, color: Color, lineWidth: CGFloat, fillOpacity: Double, in context: inout GraphicsContext) {
        let path = Path(element.frame)
        context.fill(path, with: .color(color.opacity(fillOpacity)))
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    @ViewBuilder
    private func selectedElementLabel(_ element: SnapshotElement) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        Text("  \(element.displayName)  ")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .padding(.vertical, 2)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .position(
                x: max(60, min(element.frame.midX, screenWidth - 60)),
                y: max(20, element.frame.minY - 14)
            )
            .allowsHitTesting(false)
    }
}

