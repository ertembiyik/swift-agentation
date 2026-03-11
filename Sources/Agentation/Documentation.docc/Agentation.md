# ``Agentation``

Visual feedback overlay that helps AI coding agents understand your iOS UI.

## Overview

Agentation adds a floating toolbar to your app. Tap any element on screen, leave a note, and copy the result as structured output — Markdown or JSON — that tells an AI agent exactly which view you mean, where it is, and what you want changed.

It works with both SwiftUI and UIKit. No build plugins, no code generation, no extra build phases.

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

## Topics

### Essentials

- ``Agentation``
- ``FeedbackItem``

### Snapshots

- ``HierarchySnapshot``
- ``SnapshotElement``
- ``DataSourceType``

### SwiftUI Integration

- ``AgentationTagRegistry``
