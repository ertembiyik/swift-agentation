#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformBezierPath = UIBezierPath
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformBezierPath = NSBezierPath
#endif

@MainActor
internal final class ElementHighlightView: PlatformView {

    enum Style {
        case hover
        case selected
    }

    var elementInfo: ElementInfo?

    private let style: Style
    private let borderLayer = CAShapeLayer()

    #if os(iOS)
    private let labelView = UILabel()
    #elseif os(macOS)
    private var labelView: NSTextField?
    #endif

    private weak var observedView: PlatformView?
    private var frameUpdateLink: CADisplayLink?
    private var wasInHierarchy = false

    private static let hoverColor = PlatformColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
    private static let selectedColor = PlatformColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
    private static let hoverBackgroundColor = PlatformColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.1)
    private static let selectedBackgroundColor = PlatformColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.1)

    init(frame: CGRect, style: Style) {
        self.style = style
        super.init(frame: frame)
        #if os(macOS)
        wantsLayer = true
        #endif
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        frameUpdateLink?.invalidate()
        frameUpdateLink = nil
        observedView = nil
    }

    private func setupView() {
        #if os(iOS)
        isUserInteractionEnabled = false
        #endif

        let color: PlatformColor
        let bgColor: PlatformColor
        let borderWidth: CGFloat

        switch style {
        case .hover:
            color = Self.hoverColor
            bgColor = Self.hoverBackgroundColor
            borderWidth = 2.0
        case .selected:
            color = Self.selectedColor
            bgColor = Self.selectedBackgroundColor
            borderWidth = 2.5
        }

        #if os(iOS)
        backgroundColor = bgColor
        layer.addSublayer(borderLayer)
        #elseif os(macOS)
        layer?.backgroundColor = bgColor.cgColor
        layer?.addSublayer(borderLayer)
        #endif

        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = PlatformColor.clear.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.lineDashPattern = style == .hover ? nil : [6, 3]

        if style == .hover {
            #if os(iOS)
            labelView.font = .systemFont(ofSize: 11, weight: .medium)
            labelView.textColor = .white
            labelView.backgroundColor = color
            labelView.textAlignment = .center
            labelView.layer.cornerRadius = 3
            labelView.layer.masksToBounds = true
            labelView.alpha = 0
            addSubview(labelView)
            #elseif os(macOS)
            let label = NSTextField(labelWithString: "")
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = .white
            label.backgroundColor = color
            label.drawsBackground = true
            label.alignment = .center
            label.wantsLayer = true
            label.layer?.cornerRadius = 3
            label.layer?.masksToBounds = true
            label.alphaValue = 0
            addSubview(label)
            labelView = label
            #endif
        }

        #if os(iOS)
        alpha = 0
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
        }
        #elseif os(macOS)
        alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            self.animator().alphaValue = 1
        }
        #endif
    }

    #if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBorderAndLabel()
    }
    #elseif os(macOS)
    override func layout() {
        super.layout()
        layoutBorderAndLabel()
    }
    #endif

    private func layoutBorderAndLabel() {
        let rect = bounds.insetBy(dx: borderLayer.lineWidth / 2, dy: borderLayer.lineWidth / 2)

        #if os(iOS)
        borderLayer.path = PlatformBezierPath(roundedRect: rect, cornerRadius: 4).cgPath
        #elseif os(macOS)
        borderLayer.path = PlatformBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).cgPath
        #endif

        borderLayer.frame = bounds

        guard style == .hover, let info = elementInfo else { return }

        let text = "  \(info.displayName)  "

        #if os(iOS)
        labelView.text = text
        labelView.sizeToFit()

        let labelFrame = CGRect(
            x: 4,
            y: 4,
            width: min(labelView.bounds.width, bounds.width - 8),
            height: labelView.bounds.height + 4
        )
        labelView.frame = labelFrame

        UIView.animate(withDuration: 0.1) {
            self.labelView.alpha = 1
        }
        #elseif os(macOS)
        guard let label = labelView else { return }
        label.stringValue = text
        label.sizeToFit()

        let labelFrame = CGRect(
            x: 4,
            y: bounds.height - label.bounds.height - 8,
            width: min(label.bounds.width, bounds.width - 8),
            height: label.bounds.height + 4
        )
        label.frame = labelFrame

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            label.animator().alphaValue = 1
        }
        #endif
    }

    func observeView(_ view: PlatformView) {
        stopObserving()

        observedView = view
        wasInHierarchy = view.window != nil

        #if os(iOS)
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        #elseif os(macOS)
        let link = displayLink(target: self, selector: #selector(displayLinkFired))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        #endif
        frameUpdateLink = link
    }

    func stopObserving() {
        frameUpdateLink?.invalidate()
        frameUpdateLink = nil
        observedView = nil
        wasInHierarchy = false
    }

    @objc private func displayLinkFired() {
        updateFrameFromObservedView()
    }

    private func updateFrameFromObservedView() {
        guard let view = observedView else { return }

        let isInHierarchy = view.window != nil

        if wasInHierarchy && !isInHierarchy {
            wasInHierarchy = false
            isHidden = true
            return
        }

        if !wasInHierarchy && isInHierarchy {
            isHidden = false
        }

        wasInHierarchy = isInHierarchy

        guard isInHierarchy else { return }

        #if os(iOS)
        let newFrame = view.convert(view.bounds, to: nil)
        if layer.frame != newFrame {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.frame = newFrame
            CATransaction.commit()
        }
        #elseif os(macOS)
        guard let viewWindow = view.window,
              let overlayWindow = self.window,
              let layer = self.layer else { return }

        let viewFrameInWindow = view.convert(view.bounds, to: nil)
        let viewWindowFrame = viewWindow.frame

        let screenX = viewWindowFrame.origin.x + viewFrameInWindow.origin.x
        let screenY = viewWindowFrame.origin.y + viewFrameInWindow.origin.y

        let overlayFrame = overlayWindow.frame
        let newFrame = CGRect(
            x: screenX - overlayFrame.origin.x,
            y: screenY - overlayFrame.origin.y,
            width: viewFrameInWindow.width,
            height: viewFrameInWindow.height
        )

        if layer.frame != newFrame {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.frame = newFrame
            CATransaction.commit()
        }
        #endif
    }

    func updateFrame(_ newFrame: CGRect) {
        #if os(iOS)
        UIView.animate(withDuration: 0.1) {
            self.frame = newFrame
        }
        #elseif os(macOS)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().frame = newFrame
        }
        #endif
    }
}

#if os(macOS)
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)

        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }

        return path
    }
}
#endif
