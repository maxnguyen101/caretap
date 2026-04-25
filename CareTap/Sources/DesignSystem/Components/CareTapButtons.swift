import SwiftUI

struct CareTapPrimaryActionButton: View {
    let title: String
    let systemImage: String
    var isEnabled: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button {
            CareTapHaptics.confirm()
            CareTapInteraction.dismissKeyboard()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [CareTapTheme.sageStrong, CareTapTheme.sage],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(
                        color: CareTapTheme.sageStrong.opacity(0.28),
                        radius: 14,
                        x: 0,
                        y: 6
                    )
            }
        }
        .buttonStyle(CareTapPressableButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel(title)
    }
}

struct CareTapSecondaryPillButton: View {
    let title: String
    let tone: CareTapTone
    var action: () -> Void = {}

    var body: some View {
        Button {
            CareTapHaptics.tap()
            CareTapInteraction.dismissKeyboard()
            action()
        } label: {
            Text(title)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(textColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 46)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .careTapLiquidGlass(
                    tint: backgroundColor.opacity(0.24),
                    cornerRadius: 14,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.42)
        }
        .buttonStyle(CareTapPressableButtonStyle())
        .accessibilityLabel(title)
    }

    private var backgroundColor: Color {
        switch tone {
        case .mist: CareTapTheme.surface
        case .neutral: CareTapTheme.surface.opacity(0.74)
        default: tone.color.opacity(0.12)
        }
    }

    private var textColor: Color {
        switch tone {
        case .sage: CareTapTheme.sageStrong
        case .mist: CareTapTheme.textSecondary
        case .neutral: CareTapTheme.textPrimary
        default: tone.color
        }
    }
}

struct CareTapQuickActionButton: View {
    let title: String
    let systemImage: String
    let tone: CareTapTone
    var action: () -> Void = {}

    var body: some View {
        Button {
            CareTapHaptics.tap()
            CareTapInteraction.dismissKeyboard()
            action()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 34, height: 34)
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)
                            .careTapLiquidGlass(
                                tint: tone == .sage ? Color.white.opacity(0.08) : CareTapTheme.glassTint.opacity(0.06),
                                cornerRadius: 16,
                                interactive: true
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.42), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(CareTapPressableButtonStyle())
        .accessibilityLabel(title)
    }

    private var backgroundColor: Color {
        tone == .sage ? CareTapTheme.sageStrong : CareTapTheme.surface
    }

    private var foregroundColor: Color {
        tone == .sage ? .white : CareTapTheme.textPrimary
    }

    private var iconBackground: Color {
        tone == .sage ? Color.white.opacity(0.18) : CareTapTheme.sage.opacity(0.12)
    }
}

/// Shared button style that adds a subtle press animation across CareTap buttons.
/// Keeps feedback consistent and signals interactivity clearly.
struct CareTapPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(duration: 0.18, bounce: 0.18), value: configuration.isPressed)
    }
}
