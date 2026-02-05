# Agentation Swift

## Reference Implementation

This Swift package mirrors the architecture of [benjitaylor/agentation](https://github.com/benjitaylor/agentation), a TypeScript/React implementation for web. The two implementations should be architecturally aligned.

## Core Architecture Principles

IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for framework-specific tasks

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
xcodebuild -project AgentationExample/AgentationExample.xcodeproj \
  -scheme AgentationExample \
  -sdk iphonesimulator \
  -configuration Debug
```

8. Avoid comments, `// MARK:` dividers, and documentation; use clear naming and structure instead, use comments only in critical sections when something not obvious is happening
9. Never keep unused code "for reference". Delete it completely - git history preserves everything if needed later
10. Prefer `guard` over `if-let` for early returns
11. Use `do-catch` for errors, never throwing methods returning optionals
12. Never use one-line `guard`/`if let` statements — the `return`/`continue`/`break` must be on its own line
13. Omit type annotations when the type is obvious from the initializer (e.g., `var isEnabled = true` not `var isEnabled: Bool = true`)
14. In SwiftUI views, properties must be declared before `var body: some View`

## Code Organization Within Files

**Order of declarations:**

1. types
2. static
3. computed var
4. var
5. let
6. init/deinit
7. func

**Order of access control:**

1. `open static` declarations
2. `open` declarations
3. `public static` declarations
4. `public` declarations
5. `internal static` declarations
6. `internal` declarations
7. `private static` declarations
8. `private` declarations
