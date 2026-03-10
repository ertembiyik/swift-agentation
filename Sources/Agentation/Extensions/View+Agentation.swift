//
//  View+Agentation.swift
//  Agentation
//
//  Created by Ertem Biyik on 2025.
//

import SwiftUI

extension View {

    /// Registers a SwiftUI view with Agentation's view hierarchy data source.
    ///
    /// The view hierarchy data source walks `UIView` trees directly, which means SwiftUI views
    /// aren't discoverable without help. This modifier creates a frame-based mapping so the
    /// data source can identify and name the view during capture.
    ///
    /// ```swift
    /// struct ProfileView: View {
    ///     var body: some View {
    ///         VStack {
    ///             Image(systemName: "person.circle")
    ///                 .agentationTag("Avatar")
    ///
    ///             Text("Jane Doe")
    ///                 .agentationTag("UserName")
    ///
    ///             Button("Edit Profile") { }
    ///                 .agentationTag("EditButton")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Tagged views appear in the output with bracketed names:
    /// ```
    /// ProfileViewController > [Avatar]
    /// ```
    ///
    /// > Important: This modifier is only needed when using the `.viewHierarchy` data source.
    /// > The accessibility data source discovers elements through the accessibility tree instead.
    public func agentationTag(_ tag: String) -> some View {
        modifier(AgentationTagModifier(tag: tag))
    }

}

internal struct AgentationTagModifier: ViewModifier {

    let tag: String

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                AgentationTagRegistry.shared.set(tag: tag, frame: frame)
            }
            .onDisappear {
                AgentationTagRegistry.shared.remove(tag: tag)
            }
    }

}

/// Tracks the screen frames of views registered via `.agentationTag()`.
@MainActor
public final class AgentationTagRegistry {

    public static let shared = AgentationTagRegistry()

    private(set) var entries: [String: CGRect] = [:]

    private init() {}

    func set(tag: String, frame: CGRect) {
        entries[tag] = frame
    }

    func remove(tag: String) {
        entries.removeValue(forKey: tag)
    }

    func tag(for frame: CGRect, tolerance: CGFloat = 2) -> String? {
        for (tag, tagFrame) in entries {
            guard abs(tagFrame.origin.x - frame.origin.x) < tolerance,
                  abs(tagFrame.origin.y - frame.origin.y) < tolerance,
                  abs(tagFrame.width - frame.width) < tolerance,
                  abs(tagFrame.height - frame.height) < tolerance
            else {
                continue
            }
            return tag
        }
        return nil
    }

    func clearAll() {
        entries.removeAll()
    }

}
