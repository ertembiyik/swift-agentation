import SwiftUI

struct OverlayRootView: View, HitTestable {

    var body: some View {
        ZStack {
            if let session = Agentation.shared.activeSession {
                if session.isPaused {
                    PausedOverlayView(session: session)
                } else {
                    CaptureOverlayView(session: session)
                }
            } else if let lastSession = Agentation.shared.lastSession,
                      !lastSession.feedbackItems.isEmpty,
                      !lastSession.isFrameTrackingEnabled {
                IdleBadgesView(session: lastSession)
            }

            ToolbarView()
        }
    }

    func contains(_ point: CGPoint) -> Bool {
        guard let session = Agentation.shared.activeSession else {
            return Agentation.shared.toolbarFrame.contains(point)
        }

        return session.isPaused ? Agentation.shared.toolbarFrame.contains(point) : true
    }

}
