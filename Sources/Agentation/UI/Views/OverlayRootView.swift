import SwiftUI

struct OverlayRootView: View, HitTestable {

    func contains(_ point: CGPoint) -> Bool {
        guard let session = Agentation.shared.activeSession else {
            return Agentation.shared.toolbarFrame.contains(point)
        }

        return !session.isPaused
    }

    var body: some View {
        ZStack {
            if let session = Agentation.shared.activeSession {
                if session.isPaused {
                    PausedOverlayView(session: session)
                } else {
                    CaptureOverlayView(session: session)
                }
            }

            ToolbarView()
        }
    }

}
