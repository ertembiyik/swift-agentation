#if os(iOS) || targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

public struct AgentationTagModifier: ViewModifier {
    let tag: String

    public func body(content: Content) -> some View {
        content
            .background(AgentationTagHelper(tag: tag))
    }
}

private struct AgentationTagHelper: UIViewRepresentable {
    let tag: String

    func makeUIView(context: Context) -> AgentationTagView {
        let view = AgentationTagView()
        view.agentationTag = tag
        return view
    }

    func updateUIView(_ uiView: AgentationTagView, context: Context) {
        uiView.agentationTag = tag
    }
}

@MainActor
internal final class AgentationTagView: UIView {
    var agentationTag: String? {
        didSet {
            updateTagRegistration()
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateTagRegistration()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            if let parent = findTaggableParent() {
                AgentationTagRegistry.shared.removeTag(for: parent)
            }
        }
    }

    private func updateTagRegistration() {
        guard let tag = agentationTag, !tag.isEmpty else { return }

        if let parent = findTaggableParent() {
            AgentationTagRegistry.shared.setTag(tag, for: parent)
        }
    }

    private func findTaggableParent() -> UIView? {
        var current: UIView? = self.superview

        while let view = current {
            let typeName = String(describing: type(of: view))

            if !typeName.hasPrefix("_") &&
               !typeName.contains("BackgroundView") &&
               !typeName.contains("ModifiedContent") {
                return view
            }

            current = view.superview
        }

        return self.superview
    }
}

public extension View {
    func agentationTag(_ tag: String) -> some View {
        modifier(AgentationTagModifier(tag: tag))
    }
}

public protocol AgentationScreenNaming {
    var agentationScreenName: String { get }
}

#elseif os(macOS)
import SwiftUI
import AppKit

public struct AgentationTagModifier: ViewModifier {
    let tag: String

    public func body(content: Content) -> some View {
        content
            .background(AgentationTagHelper(tag: tag))
    }
}

private struct AgentationTagHelper: NSViewRepresentable {
    let tag: String

    func makeNSView(context: Context) -> AgentationTagView {
        let view = AgentationTagView()
        view.agentationTag = tag
        return view
    }

    func updateNSView(_ nsView: AgentationTagView, context: Context) {
        nsView.agentationTag = tag
    }
}

@MainActor
internal final class AgentationTagView: NSView {
    var agentationTag: String? {
        didSet {
            updateTagRegistration()
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview == nil {
            if let parent = findTaggableParent() {
                AgentationTagRegistry.shared.removeTag(for: parent)
            }
        } else {
            updateTagRegistration()
        }
    }

    private func updateTagRegistration() {
        guard let tag = agentationTag, !tag.isEmpty else { return }

        if let parent = findTaggableParent() {
            AgentationTagRegistry.shared.setTag(tag, for: parent)
        }
    }

    private func findTaggableParent() -> NSView? {
        var current: NSView? = self.superview

        while let view = current {
            let typeName = String(describing: type(of: view))

            if !typeName.hasPrefix("_") &&
               !typeName.contains("BackgroundView") &&
               !typeName.contains("ModifiedContent") {
                return view
            }

            current = view.superview
        }

        return self.superview
    }
}

public extension View {
    func agentationTag(_ tag: String) -> some View {
        modifier(AgentationTagModifier(tag: tag))
    }
}

public protocol AgentationScreenNaming {
    var agentationScreenName: String { get }
}

#endif
