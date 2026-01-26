import UIKit

@MainActor
internal final class ElementHighlightView: UIView {

    enum Style {
        case hover
        case selected
    }

    var elementInfo: ElementInfo?

    private let style: Style
    private let borderLayer = CAShapeLayer()
    private let labelView = UILabel()

    private weak var observedView: UIView?
    private var frameUpdateLink: CADisplayLink?
    private var wasInHierarchy = false

    private static let hoverColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
    private static let selectedColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
    private static let hoverBackgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.1)
    private static let selectedBackgroundColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.1)

    init(frame: CGRect, style: Style) {
        self.style = style
        super.init(frame: frame)
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
        isUserInteractionEnabled = false

        let color: UIColor
        let bgColor: UIColor
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

        backgroundColor = bgColor
        layer.addSublayer(borderLayer)

        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.lineDashPattern = style == .hover ? nil : [6, 3]

        if style == .hover {
            labelView.font = .systemFont(ofSize: 11, weight: .medium)
            labelView.textColor = .white
            labelView.backgroundColor = color
            labelView.textAlignment = .center
            labelView.layer.cornerRadius = 3
            labelView.layer.masksToBounds = true
            labelView.alpha = 0
            addSubview(labelView)
        }

        alpha = 0
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBorderAndLabel()
    }

    private func layoutBorderAndLabel() {
        let rect = bounds.insetBy(dx: borderLayer.lineWidth / 2, dy: borderLayer.lineWidth / 2)
        borderLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: 4).cgPath
        borderLayer.frame = bounds

        guard style == .hover, let info = elementInfo else { return }

        let text = "  \(info.displayName)  "

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
    }

    func observeView(_ view: UIView) {
        stopObserving()

        observedView = view
        wasInHierarchy = view.window != nil

        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
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

        let newFrame = view.convert(view.bounds, to: nil)
        if layer.frame != newFrame {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.frame = newFrame
            CATransaction.commit()
        }
    }

    func updateFrame(_ newFrame: CGRect) {
        UIView.animate(withDuration: 0.1) {
            self.frame = newFrame
        }
    }
}
