import SwiftUI

enum CareTapCardStyle: Equatable {
    case elevated
    case muted
    case transparent

    var topColor: Color {
        switch self {
        case .elevated:
            return CareTapTheme.surface
        case .muted:
            return CareTapTheme.surfaceMuted
        case .transparent:
            return .clear
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .elevated:
            return 0.52
        case .muted:
            return 0.42
        case .transparent:
            return 0
        }
    }

    var tint: Color {
        switch self {
        case .elevated:
            return CareTapTheme.glassTint.opacity(0.1)
        case .muted:
            return CareTapTheme.glassTint.opacity(0.05)
        case .transparent:
            return .clear
        }
    }
}

struct CareTapCard<Content: View>: View {
    private let style: CareTapCardStyle
    private let content: Content

    init(style: CareTapCardStyle = .elevated, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CareTapSpacing.cardPadding)
            .background { cardBackground }
            .clipShape(RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous))
            .clipped()
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26, *) {
            // On iOS 26, the glass effect provides the background.
            // No solid fill underneath — that causes visible white boxes.
            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                .fill(Color.clear)
                .careTapLiquidGlass(
                    tint: style.tint,
                    cornerRadius: CareTapSpacing.cornerRadiusCard
                )
                .opacity(style == .transparent ? 0 : 1)
                .overlay {
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                        .stroke(CareTapTheme.stroke.opacity(style.strokeOpacity), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                .fill(style.topColor)
                .overlay {
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                        .fill(Color.clear)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous))
                        .opacity(style == .transparent ? 0 : 1)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                        .stroke(CareTapTheme.stroke.opacity(style.strokeOpacity), lineWidth: 1)
                }
        }
    }
}
