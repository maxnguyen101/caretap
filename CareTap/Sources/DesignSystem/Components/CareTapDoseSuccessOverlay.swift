import SwiftUI

/// A calm success confirmation shown after logging a dose.
struct CareTapDoseSuccessOverlay: View {
    @Binding var isPresented: Bool
    var medicationName: String = ""
    var source: String = "Logged"
    var onDismiss: () -> Void = {}

    @State private var checkScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(backgroundOpacity * 0.18)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(CareTapTheme.sageStrong)
                            .frame(width: 72, height: 72)
                            .scaleEffect(checkScale)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.white)
                                    .scaleEffect(checkScale)
                            }
                    }

                    VStack(spacing: 6) {
                        Text("Dose logged")
                            .font(CareTapTypography.section)
                            .foregroundStyle(CareTapTheme.textPrimary)

                        if !medicationName.isEmpty {
                            Text("\(medicationName) · \(source)")
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                        }
                    }
                    .opacity(textOpacity)
                }
                .padding(24)
                .frame(maxWidth: 260)
                .careTapLiquidGlass(
                    tint: CareTapTheme.glassTint.opacity(0.05),
                    cornerRadius: CareTapSpacing.cornerRadiusLarge
                )
                .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusLarge, opacity: 0.26)
            }
            .onAppear { playAnimation() }
        }
    }

    private func playAnimation() {
        CareTapHaptics.confirm()

        withAnimation(.spring(duration: 0.34, bounce: 0.18)) {
            checkScale = 1
            backgroundOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.24).delay(0.1)) {
            textOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.25)) {
            checkScale = 0.8
            textOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            onDismiss()
        }
    }
}
