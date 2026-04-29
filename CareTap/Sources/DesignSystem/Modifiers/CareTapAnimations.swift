import SwiftUI

/// Reusable modifier: content enters with a short fade on appear.
struct CareTapStaggeredEntry: ViewModifier {
    let index: Int
    let baseDelay: TimeInterval

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 6)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(
                    .easeOut(duration: 0.22)
                    .delay(baseDelay + Double(index) * 0.04)
                ) {
                    hasAppeared = true
                }
            }
    }
}

/// Reusable modifier: content fades in on appear.
struct CareTapCardEntrance: ViewModifier {
    let delay: TimeInterval

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(.easeOut(duration: 0.2).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

/// Subtle emphasis for items needing attention.
struct CareTapAttentionPulse: ViewModifier {
    let isActive: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive && pulsing ? 0.82 : 1)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Applies a staggered fade-up entrance animation.
    func careTapStaggeredEntry(index: Int, baseDelay: TimeInterval = 0.1) -> some View {
        modifier(CareTapStaggeredEntry(index: index, baseDelay: baseDelay))
    }

    /// Applies a subtle scale-up card entrance animation.
    func careTapCardEntrance(delay: TimeInterval = 0) -> some View {
        modifier(CareTapCardEntrance(delay: delay))
    }

    /// Applies a pulsing attention glow when active.
    func careTapAttentionPulse(_ isActive: Bool) -> some View {
        modifier(CareTapAttentionPulse(isActive: isActive))
    }
}
