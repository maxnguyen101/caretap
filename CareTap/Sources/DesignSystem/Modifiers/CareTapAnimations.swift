import SwiftUI

/// Reusable modifier: content enters with a staggered fade-up on appear.
struct CareTapStaggeredEntry: ViewModifier {
    let index: Int
    let baseDelay: TimeInterval

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 16)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(
                    .spring(duration: 0.55, bounce: 0.12)
                    .delay(baseDelay + Double(index) * 0.08)
                ) {
                    hasAppeared = true
                }
            }
    }
}

/// Reusable modifier: content scales up from 0.95 with a fade on appear.
struct CareTapCardEntrance: ViewModifier {
    let delay: TimeInterval

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.96)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(.spring(duration: 0.5, bounce: 0.1).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

/// Pulse-glow effect for items needing attention (overdue badges, etc.)
struct CareTapAttentionPulse: ViewModifier {
    let isActive: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? CareTapTheme.alert.opacity(pulsing ? 0.35 : 0.1) : .clear,
                radius: pulsing ? 12 : 4
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
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
