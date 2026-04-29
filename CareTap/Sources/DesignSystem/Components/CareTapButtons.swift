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
            .frame(minHeight: 48)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                    .fill(CareTapTheme.sageStrong)
                    .overlay {
                        RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    }
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
                .frame(minHeight: 42)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .careTapLiquidGlass(
                    tint: backgroundColor.opacity(0.12),
                    cornerRadius: 10,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: 10, opacity: 0.36)
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
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                    .fill(backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                            .fill(Color.clear)
                            .careTapLiquidGlass(
                                tint: tone == .sage ? Color.white.opacity(0.05) : CareTapTheme.glassTint.opacity(0.04),
                                cornerRadius: CareTapSpacing.cornerRadiusCompact,
                                interactive: true
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.36), lineWidth: 1)
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

    private var iconColor: Color {
        tone == .sage ? .white.opacity(0.95) : tone.color
    }
}

/// Shared button style that adds a subtle press animation across CareTap buttons.
/// Keeps feedback consistent and signals interactivity clearly.
struct CareTapPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.992 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
