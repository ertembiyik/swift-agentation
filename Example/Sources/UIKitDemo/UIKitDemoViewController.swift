import UIKit
import Agentation

final class UIKitDemoViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.accessibilityIdentifier = "mainScrollView"
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.accessibilityIdentifier = "contentStack"
        return stack
    }()

    // Profile Section
    private lazy var profileSection: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "profileSection"
        return view
    }()

    private lazy var avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.accessibilityLabel = "Profile Avatar"
        iv.accessibilityIdentifier = "avatarImage"
        iv.isAccessibilityElement = true
        return iv
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "John Appleseed"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.accessibilityLabel = "User Name"
        label.accessibilityIdentifier = "nameLabel"
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Senior iOS Engineer"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.accessibilityLabel = "Job Title"
        label.accessibilityIdentifier = "titleLabel"
        return label
    }()

    private lazy var bioLabel: UILabel = {
        let label = UILabel()
        label.text = "Building amazing iOS apps with Swift. Passionate about clean architecture and great user experiences."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        label.accessibilityLabel = "Bio"
        label.accessibilityIdentifier = "bioLabel"
        return label
    }()

    // Form Section
    private lazy var formSection: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "formSection"
        return view
    }()

    private lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email address"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.accessibilityLabel = "Email Input"
        tf.accessibilityIdentifier = "emailTextField"
        return tf
    }()

    private lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.accessibilityLabel = "Password Input"
        tf.accessibilityIdentifier = "passwordTextField"
        return tf
    }()

    private lazy var rememberMeSwitch: UISwitch = {
        let sw = UISwitch()
        sw.accessibilityLabel = "Remember Me Toggle"
        sw.accessibilityIdentifier = "rememberMeSwitch"
        return sw
    }()

    private lazy var rememberMeLabel: UILabel = {
        let label = UILabel()
        label.text = "Remember me"
        label.font = .systemFont(ofSize: 14)
        label.accessibilityIdentifier = "rememberMeLabel"
        return label
    }()

    // Buttons Section
    private lazy var primaryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Sign In"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.accessibilityLabel = "Sign In Button"
        button.accessibilityIdentifier = "signInButton"
        return button
    }()

    private lazy var secondaryButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Create Account"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.accessibilityLabel = "Create Account Button"
        button.accessibilityIdentifier = "createAccountButton"
        return button
    }()

    private lazy var linkButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Forgot Password?"
        let button = UIButton(configuration: config)
        button.accessibilityLabel = "Forgot Password Link"
        button.accessibilityIdentifier = "forgotPasswordLink"
        return button
    }()

    // Controls Section
    private lazy var volumeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.accessibilityLabel = "Volume Slider"
        slider.accessibilityIdentifier = "volumeSlider"
        return slider
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Light", "Dark", "System"])
        sc.selectedSegmentIndex = 2
        sc.accessibilityLabel = "Theme Selector"
        sc.accessibilityIdentifier = "themeSegment"
        return sc
    }()

    // Floating Agentation Button
    private lazy var floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        button.setImage(UIImage(systemName: "sparkles", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemPurple
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.systemPurple.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8

        button.accessibilityLabel = "Start Agentation Capture"
        button.accessibilityIdentifier = "agentationFAB"
        button.addTarget(self, action: #selector(startAgentation), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit Demo"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(floatingButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            floatingButton.widthAnchor.constraint(equalToConstant: 56),
            floatingButton.heightAnchor.constraint(equalToConstant: 56),
            floatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            floatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        setupProfileSection()
        setupFormSection()
        setupButtonsSection()
        setupControlsSection()
    }

    private func setupProfileSection() {
        let headerLabel = makeSectionHeader("Profile")

        let profileStack = UIStackView()
        profileStack.axis = .horizontal
        profileStack.spacing = 16
        profileStack.alignment = .top
        profileStack.accessibilityIdentifier = "profileStack"

        let textStack = UIStackView(arrangedSubviews: [nameLabel, titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        profileStack.addArrangedSubview(avatarImageView)
        profileStack.addArrangedSubview(textStack)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80)
        ])

        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(profileStack)
        contentStack.addArrangedSubview(bioLabel)
        contentStack.addArrangedSubview(makeDivider())
    }

    private func setupFormSection() {
        let headerLabel = makeSectionHeader("Form Elements")

        let rememberStack = UIStackView(arrangedSubviews: [rememberMeSwitch, rememberMeLabel, UIView()])
        rememberStack.axis = .horizontal
        rememberStack.spacing = 8
        rememberStack.accessibilityIdentifier = "rememberStack"

        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(emailTextField)
        contentStack.addArrangedSubview(passwordTextField)
        contentStack.addArrangedSubview(rememberStack)
        contentStack.addArrangedSubview(makeDivider())
    }

    private func setupButtonsSection() {
        let headerLabel = makeSectionHeader("Buttons")

        let buttonStack = UIStackView(arrangedSubviews: [primaryButton, secondaryButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.accessibilityIdentifier = "buttonStack"

        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(buttonStack)
        contentStack.addArrangedSubview(linkButton)
        contentStack.addArrangedSubview(makeDivider())
    }

    private func setupControlsSection() {
        let headerLabel = makeSectionHeader("Controls")

        let sliderLabel = UILabel()
        sliderLabel.text = "Volume"
        sliderLabel.font = .systemFont(ofSize: 14)
        sliderLabel.accessibilityIdentifier = "volumeLabel"

        let themeLabel = UILabel()
        themeLabel.text = "Theme"
        themeLabel.font = .systemFont(ofSize: 14)
        themeLabel.accessibilityIdentifier = "themeLabel"

        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(sliderLabel)
        contentStack.addArrangedSubview(volumeSlider)
        contentStack.addArrangedSubview(themeLabel)
        contentStack.addArrangedSubview(segmentedControl)

        // Add spacing at the bottom for the floating button
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 80).isActive = true
        contentStack.addArrangedSubview(spacer)
    }

    // MARK: - Helpers

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.accessibilityTraits = .header
        return label
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    // MARK: - Actions

    @objc private func startAgentation() {
        let buttonFrame = floatingButton.convert(floatingButton.bounds, to: nil)
        Agentation.shared.start(from: buttonFrame) { feedback in
            print("=== Agentation Feedback ===")
            print(feedback.toMarkdown())
            print("===========================")
        }
    }
}
