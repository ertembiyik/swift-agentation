import SwiftUI

struct PausedOverlayView: View {

    let session: CaptureSession

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(session.feedbackItems) { item in
                let frame = session.liveFrame(for: item)
                Rectangle()
                    .fill(Color.green.opacity(0.1))
                    .overlay(Rectangle().stroke(Color.green, lineWidth: 2))
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

}
