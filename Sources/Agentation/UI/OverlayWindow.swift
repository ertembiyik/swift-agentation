import UIKit
import SwiftUI

@MainActor
internal final class OverlayWindow: AgentationOverlayWindow {

    weak var session: AgentationSession?

    private var hoverHighlightView: ElementHighlightView?
    private var selectedHighlightViews: [UUID: ElementHighlightView] = [:]

    private var controlBarHostingController: UIHostingController<MorphingControlBar>?
    private var overlayViewController: OverlayViewController?

    private var cachedHierarchy: [ElementInfo] = []
    private var hoveredElement: ElementInfo?

    init(session: AgentationSession) {
        self.session = session

        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first

        super.init(frame: UIScreen.main.bounds)

        if let windowScene {
            self.windowScene = windowScene
        }

        self.windowLevel = .alert + 100
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true

        setupRootViewController()
        setupControlBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let session else { return nil }

        if let controlBarView = controlBarHostingController?.view {
            let pointInControlBar = controlBarView.convert(point, from: self)
            if let hitView = controlBarView.hitTest(pointInControlBar, with: event),
               isInteractiveView(hitView) {
                return super.hitTest(point, with: event)
            }
        }

        if session.isPaused {
            return nil
        }

        return super.hitTest(point, with: event)
    }

    private func isInteractiveView(_ view: UIView) -> Bool {
        var current: UIView? = view
        while let v = current {
            let typeName = String(describing: type(of: v))
            if typeName.contains("Button") || v.gestureRecognizers?.isEmpty == false {
                return true
            }
            current = v.superview
        }
        return false
    }

    private func setupRootViewController() {
        let rootVC = OverlayViewController()
        rootVC.overlay = self
        self.rootViewController = rootVC
        self.overlayViewController = rootVC
    }

    private func setupControlBar() {
        guard let session else { return }

        let screenBounds = UIScreen.main.bounds
        let sourceFrame = session.sourceFrame ?? CGRect(
            x: screenBounds.width - 56 - 16,
            y: screenBounds.height - 56 - 50,
            width: 56,
            height: 56
        )

        let controlBar = MorphingControlBar(
            session: session,
            sourceFrame: sourceFrame,
            containerSize: screenBounds.size
        )
        let hostingController = UIHostingController(rootView: controlBar)
        hostingController.view.backgroundColor = .clear

        controlBarHostingController = hostingController

        guard let rootVC = rootViewController else { return }
        rootVC.addChild(hostingController)
        rootVC.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: rootVC)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: rootVC.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: rootVC.view.bottomAnchor)
        ])
    }

    func refreshHierarchy() {
        cachedHierarchy = HierarchyInspector.shared.captureHierarchy()
        if let feedbackItems = session?.feedback.items {
            updateSelectedHighlights(for: feedbackItems)
        }
    }

    func showAnnotationPopup(for element: ElementInfo) {
        guard let session else { return }

        overlayViewController?.presentAnnotationPopup(
            for: element,
            onSubmit: { [weak self] feedback in
                session.addFeedback(feedback, for: element)
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

    func prepareForRemoval() {
        rootViewController?.presentedViewController?.dismiss(animated: false)

        controlBarHostingController?.willMove(toParent: nil)
        controlBarHostingController?.view.removeFromSuperview()
        controlBarHostingController?.removeFromParent()
        controlBarHostingController = nil

        clearAllHighlights()

        overlayViewController = nil
        rootViewController = nil
    }

    func handleTap(at point: CGPoint) {
        guard let session, !session.isPaused else { return }

        if let element = hoveredElement {
            showAnnotationPopup(for: element)
        }
    }
}

@MainActor
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

        #if targetEnvironment(macCatalyst)
        let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        view.addGestureRecognizer(hoverGesture)
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overlay?.refreshHierarchy()
    }

    func presentAnnotationPopup(
        for element: ElementInfo,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        if presentedViewController != nil {
            return
        }

        let popupView = AnnotationPopupView(
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
        overlay?.refreshHierarchy()
        let point = gesture.location(in: view)
        overlay?.updateHoverHighlight(at: point)
        overlay?.handleTap(at: point)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: view)

        switch gesture.state {
        case .began:
            overlay?.refreshHierarchy()
            overlay?.updateHoverHighlight(at: point)
        case .changed:
            overlay?.updateHoverHighlight(at: point)
        default:
            break
        }
    }

    #if targetEnvironment(macCatalyst)
    @objc private func handleHover(_ gesture: UIHoverGestureRecognizer) {
        let point = gesture.location(in: view)

        switch gesture.state {
        case .began:
            overlay?.refreshHierarchy()
            overlay?.updateHoverHighlight(at: point)
        case .changed:
            overlay?.updateHoverHighlight(at: point)
        case .ended:
            overlay?.clearHoverHighlight()
        default:
            break
        }
    }
    #endif

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        overlay?.refreshHierarchy()
        if let touch = touches.first {
            overlay?.updateHoverHighlight(at: touch.location(in: view))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let touch = touches.first {
            overlay?.updateHoverHighlight(at: touch.location(in: view))
        }
    }
}
