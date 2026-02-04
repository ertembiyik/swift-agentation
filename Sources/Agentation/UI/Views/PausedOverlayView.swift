import SwiftUI

struct PausedOverlayView: View {

    let session: CaptureSession

    var body: some View {
        Canvas { context, _ in
            for item in session.feedbackItems {
                let badgeSize: CGFloat = 18
                let rect = CGRect(
                    x: item.elementFrame.maxX - badgeSize / 2,
                    y: item.elementFrame.minY - badgeSize / 2,
                    width: badgeSize,
                    height: badgeSize
                )
                context.fill(Circle().path(in: rect), with: .color(.green))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
