import SwiftUI

struct IdleBadgesView: View {

    let session: CaptureSession

    var body: some View {
        Canvas { context, _ in
            for item in session.feedbackItems {
                let frame = session.liveFrame(for: item)
                let badgeSize: CGFloat = 18
                let rect = CGRect(
                    x: frame.maxX - badgeSize / 2,
                    y: frame.minY - badgeSize / 2,
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
