# Agentation

Agentation is an agent-agnostic visual feedback tool for iOS. Tap elements in your app, add notes, and copy structured output that helps AI coding agents find the exact code you're referring to.

Works with both **SwiftUI** and **UIKit**.

## Install

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/agentation-ios.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → enter the repository URL.

## Usage

### SwiftUI

```swift
import SwiftUI
import Agentation

@main
struct MyApp: App {
    init() {
        // Install the Agentation toolbar (auto-installs when scene is available)
        Agentation.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome")
                .agentationTag("WelcomeText")

            Button("Sign In") { }
                .agentationTag("SignInButton")
        }
    }
}
```

The floating toolbar appears automatically. Tap the button to start a capture session.

### UIKit

```swift
import UIKit
import Agentation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Install the Agentation toolbar
        Agentation.shared.install()
        return true
    }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        button.accessibilityLabel = "Sign In"
        button.accessibilityIdentifier = "signInButton"
    }
}
```

The floating toolbar appears automatically. Tap the collapsed button to start capturing, then tap any element to annotate it.

## Features

- **Tap to annotate** – Tap any element with automatic identification
- **SwiftUI tags** – Mark views with `.agentationTag("name")` for precise targeting
- **UIKit accessibility** – Uses existing `accessibilityLabel` and `accessibilityIdentifier`
- **Hierarchical paths** – Generates paths like `.Profile > .Header > #loginButton`
- **Real-time tracking** – Highlights follow elements even when they move
- **Structured output** – Copy as Markdown or JSON with paths, frames, and context
- **Shake to start** – Enable `Agentation.shared.enableShakeToStart()` in debug builds
- **Zero dependencies** – Pure UIKit overlay, no third-party libraries

## How it works

Agentation creates a transparent overlay window above your app that intercepts all touches. When you tap an element, it traverses the entire view hierarchy to find what's underneath.

### Architecture

```
┌─────────────────────────────────────┐
│  Your App Window                    │
│  ┌──────────────────────────────┐   │
│  │  UIViewController            │   │
│  │  └─ Views with accessibility │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
           ↑ inspects
┌─────────────────────────────────────┐
│  Overlay Window (level: alert+100)  │
│  ├─ Touch interception              │
│  ├─ Highlight views (blue/green)    │
│  └─ Control bar + annotation popup  │
└─────────────────────────────────────┘
```

### Element identification

When you tap, Agentation captures the complete view hierarchy and performs a hit test to find the deepest element containing that point. For each element, it extracts:

| Property | Source | Path format |
|----------|--------|-------------|
| `accessibilityIdentifier` | UIKit | `#identifier` |
| `accessibilityLabel` | UIKit | `"label"` |
| `.agentationTag()` | SwiftUI modifier | `[tag]` |
| Type name | Fallback | `UILabel` |

These combine into hierarchical paths that AI agents can grep for:

```
.ProfileView > .Header > #signInButton
```

### SwiftUI tag registration

SwiftUI views don't expose their backing UIViews directly. The `.agentationTag()` modifier works around this by injecting an invisible helper view that registers a mapping when it appears:

```swift
Text("Hello")
    .agentationTag("Greeting")  // Creates: ObjectIdentifier(UIView) → "Greeting"
```

During hierarchy inspection, Agentation looks up each UIView in this registry to retrieve your custom tag.

### Real-time highlight tracking

Selected elements show a green dashed border that follows the view even if it moves or animates. This uses `CADisplayLink` running at 60fps to query the view's current screen position and update the highlight frame.

```swift
// Simplified tracking loop
displayLink.add(to: .main, forMode: .common)
// Each frame:
if let currentFrame = trackedView?.convert(bounds, to: nil) {
    highlightView.frame = currentFrame
}
```

### Output generation

Captured feedback exports as Markdown (for humans and agents) or JSON (for tooling):

**Markdown**
```markdown
## Screen Feedback: ProfileViewController
**Frame:** 390×844

### 1. button "Sign In"
**Location:** .ProfileView > .Header > #signInButton
**Frame:** x:20 y:150 w:350 h:44
**Feedback:** Make the button larger and add a loading state
```

**JSON**
```json
{
  "screen": "ProfileViewController",
  "frame": { "width": 390, "height": 844 },
  "items": [{
    "type": "button",
    "label": "Sign In",
    "identifier": "signInButton",
    "path": ".ProfileView > .Header > #signInButton",
    "frame": { "x": 20, "y": 150, "width": 350, "height": 44 },
    "feedback": "Make the button larger and add a loading state"
  }]
}
```

## Control bar

| Icon | Action |
|------|--------|
| ⏸/▶ | Pause/resume element detection |
| 👁 | Preview all collected feedback |
| 📋 | Copy to clipboard |
| 🗑 | Clear all feedback |
| ⚙ | Settings (output format) |
| ✕ | Exit capture mode |

## API

```swift
// Installation (call once at app launch)
Agentation.shared.install()         // Auto-installs when scene is available
Agentation.shared.install(in: scene) // Install in specific scene

// Toolbar visibility
Agentation.shared.showToolbar()     // Show if hidden
Agentation.shared.hideToolbar()     // Hide temporarily

// Session control
Agentation.shared.start()           // Start capture session
Agentation.shared.start { feedback in /* ... */ } // With completion
Agentation.shared.stop()            // Stop capture session
Agentation.shared.togglePause()     // Pause/resume detection
Agentation.shared.clearFeedback()   // Clear all annotations
Agentation.shared.copyFeedback()    // Copy to clipboard

// Inspect hierarchy without UI
let elements = Agentation.shared.captureHierarchy()
let debug = Agentation.shared.debugHierarchy()

// Session properties
Agentation.shared.currentSession?.outputFormat = .json
Agentation.shared.isActive
Agentation.shared.currentSession?.isPaused
```

## Requirements

- iOS 17.0+
- macOS 14.0+ (Mac Catalyst)
- Swift 5.9+

## License

MIT License
