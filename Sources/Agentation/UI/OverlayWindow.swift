import UIKit
import SwiftUI

final class OverlayWindow: AgentationOverlayWindow {

    private var hoverHighlightView: ElementHighlightView?
    private var selectedHighlightViews: [UUID: ElementHighlightView] = [:]

    private var overlayViewController: OverlayViewController
    private var toolbarHostingView: PassThroughHostingView<ToolbarView>

    private var cachedHierarchy: [ElementInfo] = []
    private var hoveredElement: ElementInfo?

    init(scene: UIWindowScene) {
        let rootVC = OverlayViewController()
        self.overlayViewController = rootVC

        let toolbarView = ToolbarView()
        let toolbarHostingView = PassThroughHostingView(rootView: toolbarView)
        rootVC.view.addSubview(toolbarHostingView)
        self.toolbarHostingView = toolbarHostingView

        super.init(frame: scene.screen.bounds)

        self.rootViewController = rootVC
        self.windowScene = scene
        self.windowLevel = .alert + 100
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true

        rootVC.overlay = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        toolbarHostingView.frame = overlayViewController.view.bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let toolbarHit = toolbarHostingView.hitTest(convert(point, to: toolbarHostingView), with: event) {
            return toolbarHit
        }

        guard Agentation.shared.isCapturing, !Agentation.shared.isPaused else {
            return nil
        }

        return super.hitTest(point, with: event)
    }

    private func setupRootViewController() {

    }

    func refreshHierarchy() {
        cachedHierarchy = HierarchyInspector.shared.captureHierarchy()
        updateSelectedHighlights(for: Agentation.shared.feedback.items)
    }

    func showAnnotationPopup(for element: ElementInfo) {
        overlayViewController.presentAnnotationPopup(
            for: element,
            onSubmit: { [weak self] feedback in
                Agentation.shared.addFeedback(feedback, for: element)

                self?.clearHoverHighlight()
            },
            onCancel: { [weak self] in
                self?.clearHoverHighlight()
            }
        )
    }

    func updateHoverHighlight(at point: CGPoint) {
        guard let rootVC = rootViewController else { return }

        var foundElement: ElementInfo?
        for root in cachedHierarchy {
            if let element = root.elementAt(point: point) {
                foundElement = element
            }
        }

        if foundElement?.id == hoveredElement?.id {
            return
        }

        hoveredElement = foundElement

        hoverHighlightView?.removeFromSuperview()
        hoverHighlightView = nil

        guard let element = foundElement else { return }

        let highlight = ElementHighlightView(frame: element.frame, style: .hover)
        highlight.elementInfo = element
        rootVC.view.insertSubview(highlight, at: 0)
        hoverHighlightView = highlight
    }

    func clearHoverHighlight() {
        hoveredElement = nil
        hoverHighlightView?.removeFromSuperview()
        hoverHighlightView = nil
    }

    func addSelectedHighlight(for element: ElementInfo) {
        guard let rootVC = rootViewController else { return }

        if selectedHighlightViews[element.id] != nil { return }

        let highlight = ElementHighlightView(frame: element.frame, style: .selected)
        highlight.elementInfo = element

        if let observedView = HierarchyInspector.shared.view(for: element.id) {
            highlight.observeView(observedView)
        }

        rootVC.view.insertSubview(highlight, at: 0)
        selectedHighlightViews[element.id] = highlight
    }

    func removeSelectedHighlight(for elementId: UUID) {
        selectedHighlightViews[elementId]?.stopObserving()
        selectedHighlightViews[elementId]?.removeFromSuperview()
        selectedHighlightViews.removeValue(forKey: elementId)
    }

    func clearAllHighlights() {
        hoverHighlightView?.removeFromSuperview()
        hoverHighlightView = nil
        hoveredElement = nil

        for (_, view) in selectedHighlightViews {
            view.stopObserving()
            view.removeFromSuperview()
        }
        selectedHighlightViews.removeAll()
    }

    func updateSelectedHighlights(for feedbackItems: [FeedbackItem]) {
        let currentIds = Set(feedbackItems.map { $0.element.id })
        let toRemove = selectedHighlightViews.keys.filter { !currentIds.contains($0) }
        for id in toRemove {
            removeSelectedHighlight(for: id)
        }

        for item in feedbackItems {
            addSelectedHighlight(for: item.element)
        }
    }

    func handleTap(at point: CGPoint) {
        guard Agentation.shared.isCapturing, !Agentation.shared.isPaused else { return }

        if let element = hoveredElement {
            showAnnotationPopup(for: element)
        }
    }
}

private final class OverlayViewController: UIViewController {
    weak var overlay: OverlayWindow?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard Agentation.shared.isCapturing, let overlay else {
            return
        }

        overlay.refreshHierarchy()
        if let touch = touches.first {
            overlay.updateHoverHighlight(at: touch.location(in: view))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard Agentation.shared.isCapturing, let overlay else {
            return
        }

        if let touch = touches.first {
            overlay.updateHoverHighlight(at: touch.location(in: view))
        }
    }

    func presentAnnotationPopup(for element: ElementInfo,
                                onSubmit: @escaping (String) -> Void,
                                onCancel: @escaping () -> Void) {
        if presentedViewController != nil {
            return
        }

        let popupView = FeedbackScreenView(
            element: element,
            onSubmit: onSubmit,
            onCancel: onCancel
        )

        let hostingController = UIHostingController(rootView: popupView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }

        present(hostingController, animated: true)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard Agentation.shared.isCapturing, let overlay else {
            return
        }

        overlay.refreshHierarchy()

        let point = gesture.location(in: view)
        overlay.updateHoverHighlight(at: point)
        overlay.handleTap(at: point)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard Agentation.shared.isCapturing, let overlay else {
            return
        }

        let point = gesture.location(in: view)

        switch gesture.state {
        case .began:
            overlay.refreshHierarchy()
            overlay.updateHoverHighlight(at: point)
        case .changed:
            overlay.updateHoverHighlight(at: point)
        default:
            break
        }
    }

}
