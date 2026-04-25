import SwiftUI

struct CareTapScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                CareTapTheme.canvas,
                CareTapTheme.canvasWarm,
                CareTapTheme.canvasMist.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(CareTapTheme.sage.opacity(0.05))
                .frame(width: 220, height: 220)
                .blur(radius: 28)
                .offset(x: 90, y: -30)
        }
        .overlay {
            Image("GlassTexture")
                .resizable()
                .scaledToFill()
                .opacity(0.12)
                .blendMode(.softLight)
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(CareTapTheme.canvasMist.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -90, y: 70)
        }
        .ignoresSafeArea()
    }
}
