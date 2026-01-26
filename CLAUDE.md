# Agentation Swift - Development Guide

## Reference Implementation

This Swift package mirrors the architecture of [benjitaylor/agentation](https://github.com/benjitaylor/agentation), a TypeScript/React implementation for web. The two implementations should be architecturally aligned.

## Core Architecture Principles

### 1. Always-Visible Toolbar

The toolbar is **always visible** and transitions between two states:

| State | Visual | Size | Behavior |
|-------|--------|------|----------|
| **Collapsed** (idle) | Circular button with sparkles icon | 44×44px | Tap to start capture session |
| **Expanded** (capturing) | Horizontal capsule bar | ~300×44px | Full controls visible |

**Key insight**: The toolbar never disappears. It morphs between collapsed and expanded states using a glass/material transition animation.

### 2. State Model

The `Agentation` class uses an enum-based state model:

```swift
@Observable
public final class Agentation {
    public enum State: Equatable {
        case idle
        case capturing
    }

    public private(set) var state: State = .idle
    public private(set) var feedback: PageFeedback
    public private(set) var isPaused: Bool = false

    public var isCapturing: Bool { state == .capturing }
    public var annotationCount: Int { feedback.items.count }
}
```

The UI observes `Agentation.shared` directly:
- `state == .idle`: Collapsed trigger button, no touch detection
- `state == .capturing`: Expanded control bar, overlay window active

### 3. Morph Animation Pattern

**Swift implementation** uses:
- `.glassEffect()` with `.glassEffectID()` on iOS 26+
- `.matchedGeometryEffect()` with `.animation()` on iOS 17-25
- Spring animation: `response: 0.4, dampingFraction: 0.75`

```swift
// iOS 26+ with GlassEffect
@available(iOS 26.0, *)
private var glassToolbarContent: some View {
    GlassEffectContainer(spacing: 20) {
        if Agentation.shared.isCapturing {
            expandedControlBar
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("agentationToolbar", in: morphNamespace)
        } else {
            triggerButton
                .buttonStyle(.glassProminent)
                .glassEffectID("agentationToolbar", in: morphNamespace)
        }
    }
}

// iOS 17-25 fallback
private var fallbackToolbarContent: some View {
    ZStack {
        if Agentation.shared.isCapturing {
            expandedControlBar
                .background(.ultraThinMaterial, in: Capsule())
                .matchedGeometryEffect(id: "agentationToolbar", in: morphNamespace)
        } else {
            triggerButton
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: "agentationToolbar", in: morphNamespace)
        }
    }
}
```

### 4. Badge Counter Pattern

When collapsed, show annotation count badge:

```swift
if Agentation.shared.annotationCount > 0 {
    BadgeView(count: Agentation.shared.annotationCount)
        .offset(x: 14, y: -14)
}
```

Badge behavior:
- Position: top-right of collapsed button
- Visible only when `!isCapturing && annotationCount > 0`
- Uses blue capsule background with white text

### 5. Control Bar Actions

The expanded bar contains these controls in order:

| Position | Icon | Action | Notes |
|----------|------|--------|-------|
| 1 | Play/Pause | Toggle pause mode | Freezes element detection |
| 2 | Eye | Preview | Shows feedback sheet |
| 3 | Copy | Copy feedback | Markdown/JSON to clipboard |
| 4 | Trash | Clear all | Delete all annotations |
| - | Divider | - | Visual separator |
| 5 | Gear | Settings | Opens settings sheet |
| - | Divider | - | Visual separator |
| 6 | X | Close | Stop session (collapse) |

### 6. Draggable Toolbar

The toolbar can be dragged to reposition:
- Position saved to UserDefaults
- Snaps to nearest edge on drag end
- Respects safe area insets

### 7. Window Architecture

Two UIWindow instances:

1. **AgentationWindow** (level: .alert + 50)
   - Always visible
   - Hosts the morphing toolbar
   - Pass-through for touches outside toolbar

2. **OverlayWindow** (level: .alert + 100)
   - Only exists during capture session
   - Intercepts all touches for element detection
   - Manages hover/selected highlights
   - Shows annotation popup

## File Structure

```
Sources/Agentation/
├── Agentation.swift              # Main class + AgentationWindow
├── Models/
│   ├── ElementInfo.swift         # Element metadata
│   ├── FeedbackItem.swift        # Annotation data
│   └── PageFeedback.swift        # Collection + export
├── UI/
│   ├── ControlBarView.swift      # AgentationToolbarView (morphing)
│   ├── OverlayWindow.swift       # Touch interception + highlights
│   ├── AnnotationPopupView.swift # Comment input sheet
│   └── ElementHighlightView.swift # Hover/selected highlights
├── Inspection/
│   └── HierarchyInspector.swift  # View tree traversal
└── ViewModifier+Agentation.swift # .agentationTag() modifier
```

## Public API

```swift
// Installation (call once at app launch)
Agentation.shared.install()

// Capture control
Agentation.shared.start()           // Start capture session
Agentation.shared.stop()            // Stop and collapse
Agentation.shared.togglePause()     // Pause element detection

// Feedback management
Agentation.shared.copyFeedback()    // Copy to clipboard
Agentation.shared.clearFeedback()   // Clear all

// Observable properties
Agentation.shared.state             // .idle or .capturing
Agentation.shared.isCapturing       // Convenience computed property
Agentation.shared.isPaused
Agentation.shared.feedback          // Current PageFeedback
Agentation.shared.annotationCount   // Count of feedback items
Agentation.shared.outputFormat      // .markdown or .json
```

## SwiftUI Tagging

Use `.agentationTag()` to mark views for identification:

```swift
Text("Welcome")
    .agentationTag("WelcomeText")

Button("Sign In") { }
    .agentationTag("SignInButton")
```

## Key Design Decisions

1. **Single Agentation class**: No separate AgentationSession - all state is in Agentation
2. **Enum state**: `State.idle` vs `State.capturing` instead of boolean flags
3. **Observable pattern**: Views observe `Agentation.shared` directly via `@Observable`
4. **No @MainActor on views**: SwiftUI views are already MainActor-isolated via protocol
5. **Collapsed naming**: Use "collapsed" instead of "FAB" terminology
