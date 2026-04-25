import SwiftUI
import UIKit

enum CareTapTheme {
    static let canvas = Color(light: 0xF6F5F1, dark: 0x101314)
    static let canvasWarm = Color(light: 0xF1EFE9, dark: 0x171A1B)
    static let canvasMist = Color(light: 0xE7EEEA, dark: 0x16201D)
    static let surface = Color(light: 0xFFFFFF, dark: 0x171A1C)
    static let surfaceMuted = Color(light: 0xF8F7F3, dark: 0x1D2022)
    static let surfaceElevated = Color(light: 0xF0F2EF, dark: 0x24292A)
    static let glassTint = Color(light: 0xFFFFFF, dark: 0xF6FBF9)
    static let sage = Color(light: 0x587D76, dark: 0x93C3B8)
    static let sageStrong = Color(light: 0x426C64, dark: 0xB4E2D8)
    static let mist = Color(light: 0x778782, dark: 0x7F9390)
    static let warm = Color(light: 0xB48A65, dark: 0xD8B390)
    static let alert = Color(light: 0xC7675D, dark: 0xF09B90)
    static let success = Color(light: 0x5D8F7A, dark: 0x9CD0BD)
    static let textPrimary = Color(light: 0x171A1C, dark: 0xF5F7F7)
    static let textSecondary = Color(light: 0x646C69, dark: 0xC6CDCA)
    static let textTertiary = Color(light: 0x919996, dark: 0x8D9794)
    static let stroke = Color(light: 0xE5E5E0, dark: 0x303638)
    static let separator = Color(light: 0xD8DDD8, dark: 0x333A3B)
    static let shadow = Color.black.opacity(0.045)
    static let glassTextureOpacity: Double = 0.16
}

enum CareTapSpacing {
    static let screenPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 22
    static let elementSpacing: CGFloat = 8
    static let groupSpacing: CGFloat = 20
    static let cornerRadiusLarge: CGFloat = 26
    static let cornerRadiusCard: CGFloat = 22
    static let cornerRadiusCompact: CGFloat = 16
}

enum CareTapTypography {
    static let brand = Font.system(.title3, design: .default).weight(.semibold)
    static let hero = Font.system(size: 32, weight: .semibold, design: .default)
    static let title = Font.system(.title2, design: .default).weight(.semibold)
    static let section = Font.system(.headline, design: .default).weight(.semibold)
    static let body = Font.system(.body, design: .default)
    static let bodyStrong = Font.system(.body, design: .default).weight(.semibold)
    static let callout = Font.system(.callout, design: .default)
    static let footnote = Font.system(.subheadline, design: .default)
    static let micro = Font.system(.caption, design: .default).weight(.medium)
}

extension Color {
    fileprivate init(light: UInt, dark: UInt) {
        self.init(
            uiColor: UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}

extension View {
    @ViewBuilder
    func careTapLiquidGlass(
        tint: Color = .clear,
        cornerRadius: CGFloat = CareTapSpacing.cornerRadiusCompact,
        interactive: Bool = false
    ) -> some View {
        Group {
            if #available(iOS 26, *) {
                if interactive {
                    self.glassEffect(
                        .regular
                            .tint(tint)
                            .interactive(),
                        in: .rect(cornerRadius: cornerRadius)
                    )
                } else {
                    self.glassEffect(
                        .regular
                            .tint(tint),
                        in: .rect(cornerRadius: cornerRadius)
                    )
                }
            } else {
                self.background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
            }
        }
        .overlay {
            CareTapFrostedGlassOverlay(
                cornerRadius: cornerRadius,
                tint: tint,
                opacity: CareTapTheme.glassTextureOpacity
            )
        }
    }

    @ViewBuilder
    func careTapGlassFill(
        _ color: Color = CareTapTheme.surface,
        opacity: Double = 0.6
    ) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            self.background(color.opacity(opacity))
        }
    }

    func careTapGlassStroke(
        cornerRadius: CGFloat = CareTapSpacing.cornerRadiusCompact,
        opacity: Double = 0.72
    ) -> some View {
        self.overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(opacity), lineWidth: 1)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
}

private struct CareTapFrostedGlassOverlay: View {
    let cornerRadius: CGFloat
    let tint: Color
    let opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.clear)
            .overlay {
                Image("GlassTexture")
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .blendMode(.softLight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        tint.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .allowsHitTesting(false)
        }
}

enum CareTapInteraction {
    @MainActor
    static func dismissKeyboard() {
    #if canImport(UIKit) && !APP_EXTENSION
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
    }
}

@MainActor
enum CareTapHaptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func tap() {
        lightGenerator.impactOccurred()
    }

    static func confirm() {
        mediumGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }
}

extension CareTapTone {
    var color: Color {
        switch self {
        case .sage: CareTapTheme.sage
        case .neutral: CareTapTheme.textSecondary
        case .mist: CareTapTheme.mist
        case .warm: CareTapTheme.warm
        case .alert: CareTapTheme.alert
        case .success: CareTapTheme.success
        }
    }
}
