#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
import SwiftUI

@MainActor
internal final class OverlayWindow: AgentationOverlayWindow {

    weak var session: AgentationSession?

    private var hoverHighlightView: ElementHighlightView?
    private var selectedHighlightViews: [UUID: ElementHighlightView] = [:]

    private var controlBarHostingController: UIHostingController<ControlBarView>?
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
            if controlBarView.bounds.contains(pointInControlBar) {
                return super.hitTest(point, with: event)
            }
        }

        if session.isPaused {
            return nil
        }

        return super.hitTest(point, with: event)
    }

    private func setupRootViewController() {
        let rootVC = OverlayViewController()
        rootVC.overlay = self
        self.rootViewController = rootVC
        self.overlayViewController = rootVC
    }

    private func setupControlBar() {
        guard let session else { return }

        let controlBar = ControlBarView(session: session)
        let hostingController = UIHostingController(rootView: controlBar)
        hostingController.view.backgroundColor = .clear

        controlBarHostingController = hostingController

        guard let rootVC = rootViewController else { return }
        rootVC.addChild(hostingController)
        rootVC.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: rootVC)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: rootVC.view.centerXAnchor),
            hostingController.view.bottomAnchor.constraint(
                equalTo: rootVC.view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            )
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

#elseif os(macOS)
import AppKit
import SwiftUI

@MainActor
internal final class OverlayPanel: AgentationOverlayPanel {

    weak var session: AgentationSession?

    private var hoverHighlightView: ElementHighlightView?
    private var selectedHighlightViews: [UUID: ElementHighlightView] = [:]

    private var controlBarHostingView: NSHostingView<ControlBarView>?
    private var overlayContentView: OverlayContentView?

    private var cachedHierarchy: [ElementInfo] = []
    private var hoveredElement: ElementInfo?
    private var trackingArea: NSTrackingArea?
    private var currentPopover: NSPopover?

    init(session: AgentationSession, contentRect: NSRect) {
        self.session = session

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .popUpMenu
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false

        setupContentView()
        setupControlBar()
    }

    private func setupContentView() {
        let content = OverlayContentView(frame: contentView?.bounds ?? .zero)
        content.overlay = self
        content.autoresizingMask = [.width, .height]
        contentView?.addSubview(content)
        overlayContentView = content
    }

    private func setupControlBar() {
        guard let session else { return }

        let controlBar = ControlBarView(session: session)
        let hostingView = NSHostingView(rootView: controlBar)

        controlBarHostingView = hostingView

        guard let container = contentView else { return }
        container.addSubview(hostingView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -40)
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

        currentPopover?.close()
        currentPopover = nil

        let popupView = AnnotationPopupView(
            element: element,
            onSubmit: { [weak self] feedback in
                self?.currentPopover?.close()
                self?.currentPopover = nil
                session.addFeedback(feedback, for: element)
                self?.clearHoverHighlight()
            },
            onCancel: { [weak self] in
                self?.currentPopover?.close()
                self?.currentPopover = nil
                self?.clearHoverHighlight()
            }
        )

        let hostingController = NSHostingController(rootView: popupView)
        hostingController.preferredContentSize = NSSize(width: 400, height: 300)

        let popover = NSPopover()
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true

        currentPopover = popover

        if let highlight = hoverHighlightView, highlight.superview != nil {
            popover.show(relativeTo: highlight.bounds, of: highlight, preferredEdge: .maxY)
        } else if let content = overlayContentView {
            let centerRect = NSRect(
                x: content.bounds.midX - 100,
                y: content.bounds.midY,
                width: 200,
                height: 1
            )
            popover.show(relativeTo: centerRect, of: content, preferredEdge: .maxY)
        }
    }

    func updateHoverHighlight(at point: CGPoint) {
        guard let content = overlayContentView else { return }

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

        let windowFrame = frame
        let highlightFrame = CGRect(
            x: element.frame.origin.x - windowFrame.origin.x,
            y: element.frame.origin.y - windowFrame.origin.y,
            width: element.frame.width,
            height: element.frame.height
        )

        let highlight = ElementHighlightView(frame: highlightFrame, style: .hover)
        highlight.elementInfo = element
        content.addSubview(highlight, positioned: .below, relativeTo: controlBarHostingView)
        hoverHighlightView = highlight
    }

    func clearHoverHighlight() {
        hoveredElement = nil
        hoverHighlightView?.removeFromSuperview()
        hoverHighlightView = nil
    }

    func addSelectedHighlight(for element: ElementInfo) {
        guard let content = overlayContentView else { return }

        if selectedHighlightViews[element.id] != nil { return }

        let windowFrame = frame
        let highlightFrame = CGRect(
            x: element.frame.origin.x - windowFrame.origin.x,
            y: element.frame.origin.y - windowFrame.origin.y,
            width: element.frame.width,
            height: element.frame.height
        )

        let highlight = ElementHighlightView(frame: highlightFrame, style: .selected)
        highlight.elementInfo = element

        if let observedView = HierarchyInspector.shared.view(for: element.id) {
            highlight.observeView(observedView)
        }

        content.addSubview(highlight, positioned: .below, relativeTo: controlBarHostingView)
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
        currentPopover?.close()
        currentPopover = nil

        controlBarHostingView?.removeFromSuperview()
        controlBarHostingView = nil

        clearAllHighlights()

        overlayContentView?.removeFromSuperview()
        overlayContentView = nil
    }

    func handleClick(at point: CGPoint) {
        guard let session, !session.isPaused else { return }

        if let element = hoveredElement {
            showAnnotationPopup(for: element)
        }
    }

    func isPointInControlBar(_ point: NSPoint, from view: NSView) -> Bool {
        guard let controlBar = controlBarHostingView else { return false }
        let pointInControlBar = controlBar.convert(point, from: view)
        return controlBar.bounds.contains(pointInControlBar)
    }
}

@MainActor
private final class OverlayContentView: NSView {
    weak var overlay: OverlayPanel?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        overlay?.refreshHierarchy()
    }

    override func mouseDown(with event: NSEvent) {
        overlay?.refreshHierarchy()
        let point = convert(event.locationInWindow, from: nil)
        overlay?.updateHoverHighlight(at: convertToScreen(point))
        overlay?.handleClick(at: convertToScreen(point))
    }

    override func mouseEntered(with event: NSEvent) {
        overlay?.refreshHierarchy()
    }

    override func mouseMoved(with event: NSEvent) {
        guard let session = overlay?.session, !session.isPaused else { return }
        let point = convert(event.locationInWindow, from: nil)
        overlay?.updateHoverHighlight(at: convertToScreen(point))
    }

    override func mouseExited(with event: NSEvent) {
        overlay?.clearHoverHighlight()
    }

    private func convertToScreen(_ point: CGPoint) -> CGPoint {
        guard let window = overlay else { return point }
        let windowFrame = window.frame
        return CGPoint(
            x: windowFrame.origin.x + point.x,
            y: windowFrame.origin.y + point.y
        )
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let session = overlay?.session else { return nil }

        if overlay?.isPointInControlBar(point, from: self) == true {
            return super.hitTest(point)
        }

        if session.isPaused {
            return nil
        }

        return super.hitTest(point)
    }
}

#endif
