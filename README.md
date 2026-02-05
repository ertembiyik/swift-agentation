# swift-agentation

<p align="center">
  <video src="https://github.com/user-attachments/assets/f6b5cc0a-5e77-4400-baa5-6e9b41921229" autoplay loop muted playsinline></video>
</p>

<h3 align="center">Visual feedback for AI coding agents on iOS</h3>

<p align="center">
Tap elements in your app, add notes, and copy structured output that helps AI coding agents find the exact views you're referring to. Based on the original <a href="https://github.com/benjitaylor/agentation">agentation</a> web implementation.
</p>

---

- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Data Sources](#data-sources)
    - [Accessibility](#accessibility)
    - [View Hierarchy](#view-hierarchy)
  - [Options](#options)
- [Acknowledgments](#acknowledgments)

## Installation

Add the package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ertembiyik/swift-agentation.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

**Requirements:** iOS 17.0+, Swift 5.9+

## Usage

Call `install()` once at app launch to add the floating toolbar:

```swift
#if DEBUG
import Agentation
#endif

@main
struct MyApp: App {
    init() {
    #if DEBUG
        Agentation.shared.install()
    #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

You can also install into a specific `UIWindowScene`:

```swift
Agentation.shared.install(in: scene)
```

### Session programmatic control

Agentation uses an overlay window with visual controlls to manage the capture session and configure it but if you want to update the default values or control it programmatically you can do it using `Agentation` class:

```swift
await Agentation.shared.start()     // Begin a capture session
Agentation.shared.pause()           // Pause element detection
await Agentation.shared.resume()    // Resume detection with a fresh snapshot
Agentation.shared.stop()            // End the session

Agentation.shared.copyFeedback()    // Copy annotations to clipboard
Agentation.shared.clearFeedback()   // Clear all annotations

Agentation.shared.showToolbar()
Agentation.shared.hideToolbar()
```

### Output formats

Feedback can be copied as Markdown (default) or JSON:

```swift
Agentation.shared.outputFormat = .markdown // or .json
```

## Configuration

### Data Sources

Agentation supports two strategies for discovering elements on screen. Data sources are types conforming to the `HierarchyDataSource` protocol — you can implement your own if needed.

The default data source is `AccessibilityHierarchyDataSource`, you can change it both through settings screen on Agentation toolbar or set the default one via:

```swift
Agentation.shared.selectedDataSourceType = .accessibility 
```

#### Accessibility

The accessibility data source uses the iOS accessibility tree. It captures elements that have `isAccessibilityElement = true` and extracts their `accessibilityLabel`, `accessibilityValue`, `accessibilityHint`, and traits.

This is the recommended source for both SwiftUI and UIKit. Use standard accessibility modifiers to tag your elements.

**SwiftUI:**

```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .accessibilityLabel("Profile picture")

            Text("Jane Doe")

            Button("Edit Profile") { }
        }
    }
}
```

**UIKit:**

```swift
class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.accessibilityLabel = "Profile picture"
        avatarImageView.isAccessibilityElement = true

        editButton.accessibilityLabel = "Edit Profile"
    }
}
```

**Example output:**

```markdown
**Viewport:** 390×844

## ProfileViewController

### 1. image "Profile picture"
**Location:** ProfileViewController > "Profile picture"
**Frame:** x:165 y:120 w:60 h:60
**Feedback:** Make the avatar larger

### 2. statictext "Jane Doe"
**Location:** ProfileViewController > "Jane Doe"
**Frame:** x:140 y:190 w:110 h:20
**Feedback:** Use bold font

### 3. button "Edit Profile"
**Location:** ProfileViewController > "Edit Profile"
**Frame:** x:100 y:230 w:190 h:44
**Feedback:** Add a loading state
```

#### View Hierarchy

The view hierarchy data source walks the `UIView` tree directly. It captures every leaf view regardless of accessibility settings, making it useful when you need full coverage of views that aren't exposed to VoiceOver.

This source works best with **UIKit** because it can traverse the entire view tree. For **SwiftUI**, views don't expose their backing `UIView`s directly for majority of views, so the source cannot identify them without help. Use the `.agentationTag()` modifier to register SwiftUI views — it creates a frame-based mapping that Agentation looks up during capture.

**UIKit:**

```swift
class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        avatarImageView.accessibilityIdentifier = "avatarImage"
        nameLabel.accessibilityLabel = "Jane Doe"
        editButton.accessibilityIdentifier = "editProfileButton"
    }
}
```

**SwiftUI (requires `.agentationTag()`):**

```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .agentationTag("Avatar")

            Text("Jane Doe")
                .agentationTag("UserName")

            Button("Edit Profile") { }
                .agentationTag("EditButton")
        }
    }
}
```

Paths use `[tag]` for `.agentationTag()`, `#id` for `accessibilityIdentifier`, and `"label"` for `accessibilityLabel`:

**Example output:**

```markdown
**Viewport:** 390×844

## ProfileViewController

### 1. image "avatarImage"
**Location:** ProfileViewController > #avatarImage
**Frame:** x:165 y:120 w:60 h:60
**Feedback:** Make the avatar larger

### 2. text "Jane Doe"
**Location:** ProfileViewController > "Jane Doe"
**Frame:** x:140 y:190 w:110 h:20
**Feedback:** Use bold font

### 3. button "editProfileButton"
**Location:** ProfileViewController > #editProfileButton
**Frame:** x:100 y:230 w:190 h:44
**Feedback:** Add a loading state
```

For the SwiftUI example with `.agentationTag()`:

```markdown
### 1. image "Avatar"
**Location:** ProfileViewController > [Avatar]
...
```

### Options

These properties on `Agentation.shared` control capture behavior:

| Property | Default | Description |
|----------|---------|-------------|
| `selectedDataSourceType` | `.accessibility` | Which data source to use (`.accessibility` or `.viewHierarchy`). |
| `outputFormat` | `.markdown` | Output format when copying feedback (`.markdown` or `.json`). |
| `includeHiddenElements` | `false` | When enabled, elements with very low alpha or zero size are included in the snapshot. |
| `includeSystemViews` | `false` | When enabled, system-provided views (keyboard, status bar internals) are included. |
| `experimentalFrameTracking` | `false` | Enables `CADisplayLink`-based tracking so highlights follow elements that move or animate. |

## Acknowledgments

- [agentation](https://github.com/benjitaylor/agentation) — the original TypeScript/React implementation
- [UniversalGlass](https://github.com/Aeastr/UniversalGlass) — cross-version glass material effects used for the toolbar UI

## License

[MIT License](LICENSE)
