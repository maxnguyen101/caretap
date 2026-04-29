import SwiftUI

enum CareTapCardStyle: Equatable {
    case elevated
    case muted
    case completed
    case transparent

    var topColor: Color {
        switch self {
        case .elevated:
            return CareTapTheme.surface
        case .muted:
            return CareTapTheme.surfaceMuted
        case .completed:
            return CareTapTheme.successSurface
        case .transparent:
            return .clear
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .elevated:
            return 0.42
        case .muted:
            return 0.32
        case .completed:
            return 1
        case .transparent:
            return 0
        }
    }

    var tint: Color {
        switch self {
        case .elevated:
            return CareTapTheme.glassTint.opacity(0.05)
        case .muted:
            return CareTapTheme.glassTint.opacity(0.025)
        case .completed:
            return .clear
        case .transparent:
            return .clear
        }
    }

    var usesLiquidGlass: Bool {
        switch self {
        case .completed, .transparent:
            return false
        case .elevated, .muted:
            return true
        }
    }

    var fillOpacity: Double {
        switch self {
        case .elevated:
            return 0.82
        case .muted:
            return 0.82
        case .completed:
            return 1
        case .transparent:
            return 0
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
        if style == .transparent {
            Color.clear
        } else if style.usesLiquidGlass {
            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                .fill(style.topColor.opacity(style.fillOpacity))
                .careTapLiquidGlass(
                    tint: style.tint,
                    cornerRadius: CareTapSpacing.cornerRadiusCard
                )
                .overlay {
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                        .stroke(CareTapTheme.stroke.opacity(style.strokeOpacity), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                .fill(style.topColor)
                .overlay {
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                        .stroke(completedStrokeColor, lineWidth: 1)
                }
        }
    }

    private var completedStrokeColor: Color {
        style == .completed ? CareTapTheme.successStroke : CareTapTheme.stroke.opacity(style.strokeOpacity)
    }
}
