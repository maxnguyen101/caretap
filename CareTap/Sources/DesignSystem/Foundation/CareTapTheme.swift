import SwiftUI
import UIKit

enum CareTapTheme {
    static let canvas = Color(light: 0xF7F6F2, dark: 0x101213)
    static let canvasWarm = Color(light: 0xF0EFEB, dark: 0x17191A)
    static let canvasMist = Color(light: 0xE9EFEB, dark: 0x19201E)
    static let surface = Color(light: 0xFFFFFF, dark: 0x171A1C)
    static let surfaceMuted = Color(light: 0xF4F3EF, dark: 0x1D2021)
    static let surfaceElevated = Color(light: 0xEEEDEA, dark: 0x232829)
    static let glassTint = Color(light: 0xFFFFFF, dark: 0xF6FBF9)
    static let backgroundLavender = Color(light: 0xCDBDFF, dark: 0x4E4265)
    static let backgroundRose = Color(light: 0xF7B8C7, dark: 0x67404B)
    static let backgroundApricot = Color(light: 0xFFE2A8, dark: 0x705837)
    static let backgroundMint = Color(light: 0xBDEDE5, dark: 0x315C57)
    static let sage = Color(light: 0x587D76, dark: 0x93C3B8)
    static let sageStrong = Color(light: 0x3F665F, dark: 0xB4E2D8)
    static let mist = Color(light: 0x778782, dark: 0x7F9390)
    static let warm = Color(light: 0xB48A65, dark: 0xD8B390)
    static let alert = Color(light: 0xC7675D, dark: 0xF09B90)
    static let success = Color(light: 0x5D8F7A, dark: 0x9CD0BD)
    static let successSurface = Color(light: 0xEDF7F2, dark: 0x1D332C)
    static let successStroke = Color(light: 0xCFE6DA, dark: 0x345A4C)
    static let textPrimary = Color(light: 0x171A1C, dark: 0xF5F7F7)
    static let textSecondary = Color(light: 0x646C69, dark: 0xC6CDCA)
    static let textTertiary = Color(light: 0x919996, dark: 0x8D9794)
    static let stroke = Color(light: 0xE3E1DC, dark: 0x303638)
    static let separator = Color(light: 0xDDDBD6, dark: 0x333A3B)
    static let shadow = Color.black.opacity(0.035)
    static let glassTextureOpacity: Double = 0.06
}

enum CareTapSpacing {
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let elementSpacing: CGFloat = 8
    static let groupSpacing: CGFloat = 14
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusCard: CGFloat = 14
    static let cornerRadiusCompact: CGFloat = 10
}

enum CareTapTypography {
    static let brand = Font.system(.title3, design: .default).weight(.semibold)
    static let hero = Font.system(size: 28, weight: .semibold, design: .default)
    static let title = Font.system(.title2, design: .default).weight(.semibold)
    static let section = Font.system(.headline, design: .default).weight(.semibold)
    static let body = Font.system(.body, design: .default)
    static let bodyStrong = Font.system(.body, design: .default).weight(.semibold)
    static let callout = Font.system(.callout, design: .default)
    static let footnote = Font.system(.subheadline, design: .default)
    static let micro = Font.system(.caption2, design: .default).weight(.medium)
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
        opacity: Double = 0.55
    ) -> some View {
        self.overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(opacity), lineWidth: 1)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(opacity)
                    .blendMode(.softLight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                tint.opacity(0.045)
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
