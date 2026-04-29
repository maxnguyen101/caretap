import SwiftUI

struct CareTapScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            CareTapTheme.canvas

            LinearGradient(
                colors: [
                    CareTapTheme.backgroundLavender.opacity(topWashOpacity * 0.64),
                    CareTapTheme.backgroundRose.opacity(topWashOpacity * 0.56),
                    CareTapTheme.backgroundApricot.opacity(topWashOpacity * 0.58),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.72, y: 0.82)
            )

            RadialGradient(
                colors: [
                    CareTapTheme.backgroundLavender.opacity(bloomOpacity),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 430
            )

            RadialGradient(
                colors: [
                    CareTapTheme.backgroundRose.opacity(bloomOpacity * 0.92),
                    Color.clear
                ],
                center: UnitPoint(x: 0.54, y: 0.02),
                startRadius: 18,
                endRadius: 380
            )

            RadialGradient(
                colors: [
                    CareTapTheme.backgroundApricot.opacity(bloomOpacity),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 420
            )

            RadialGradient(
                colors: [
                    CareTapTheme.backgroundMint.opacity(mintOpacity),
                    Color.clear
                ],
                center: UnitPoint(x: 0.98, y: 0.24),
                startRadius: 24,
                endRadius: 420
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(centerLiftOpacity),
                    CareTapTheme.canvas.opacity(0)
                ],
                startPoint: UnitPoint(x: 0.42, y: 0.34),
                endPoint: .bottom
            )

            Image("GlassTexture")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(textureOpacity)
                .blendMode(.softLight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var topWashOpacity: Double {
        isDarkMode ? 0.18 : 0.46
    }

    private var bloomOpacity: Double {
        isDarkMode ? 0.24 : 0.58
    }

    private var mintOpacity: Double {
        isDarkMode ? 0.18 : 0.42
    }

    private var centerLiftOpacity: Double {
        isDarkMode ? 0.02 : 0.38
    }

    private var textureOpacity: Double {
        isDarkMode ? 0.025 : 0.035
    }
}
