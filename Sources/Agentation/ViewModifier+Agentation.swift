import SwiftUI

public struct AgentationTagModifier: ViewModifier {

    let tag: String

    public func body(content: Content) -> some View {
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

public extension View {
    func agentationTag(_ tag: String) -> some View {
        modifier(AgentationTagModifier(tag: tag))
    }
}

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
