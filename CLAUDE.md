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

## Important points

1. Aim for the most simplest solution, think huristially before going for changes
2. Use Observation, never use @Published and ObservedObject
3. Never write comments
4. Aim for enums with assoicated values instead of multiple values that represent one state
5. Try to use .onGeometryChange and .containerRelativeFrame instead of GeometryReader when possible
6. Use UniversalGlass library instead of checking if iOS 26 is available
7. to build the Example, use:

```bash
tuist xcodebuild -workspace Example/AgentationExample.xcworkspace \
  -scheme AgentationExample \
  -sdk iphonesimulator \
  -configuration Debug \
  build
```
