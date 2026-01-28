# Agentation Swift

## Reference Implementation

This Swift package mirrors the architecture of [benjitaylor/agentation](https://github.com/benjitaylor/agentation), a TypeScript/React implementation for web. The two implementations should be architecturally aligned.

## Core Architecture Principles

The toolbar is **always visible** and transitions between two states:

| State | Visual | Size | Behavior |
|-------|--------|------|----------|
| **Collapsed** (idle) | Circular button with sparkles icon | 44×44px | Tap to start capture session |
| **Expanded** (capturing) | Horizontal capsule bar | ~300×44px | Full controls visible |

**Key insight**: The toolbar never disappears. It morphs between collapsed and expanded states using a glass/material transition animation.

Remember to:

1. Use Observation, never use @Published and ObservedObject
2. Never write comments
3. Aim for enums with assoicated values instead of multiple values that represent one state
4. Try to use .onGeometryChange and .containerRelativeFrame instead of GeometryReader when possible
5. Use UniversalGlass library instead of checking if iOS 26 is available
6. to build the Example, use:

```bash
tuist xcodebuild -workspace Example/AgentationExample.xcworkspace \
  -scheme AgentationExample \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```
