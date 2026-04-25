import SwiftUI

/// A celebratory success animation shown after logging a dose.
/// Features a scaling checkmark with expanding rings, similar to Apple Pay success.
struct CareTapDoseSuccessOverlay: View {
    @Binding var isPresented: Bool
    var medicationName: String = ""
    var source: String = "Logged"
    var onDismiss: () -> Void = {}

    @State private var checkScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.8
    @State private var ring2Opacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0

    var body: some View {
        if isPresented {
            ZStack {
                // Dimmed background
                Color.black.opacity(backgroundOpacity * 0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 24) {
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .stroke(CareTapTheme.sage.opacity(ring2Opacity * 0.3), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(ring2Scale)

                        // Inner pulse ring
                        Circle()
                            .stroke(CareTapTheme.sage.opacity(ringOpacity * 0.5), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringScale)

                        // Checkmark circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [CareTapTheme.sage, CareTapTheme.sageStrong],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: CareTapTheme.sage.opacity(0.4), radius: 20)
                            .scaleEffect(checkScale)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 36, weight: .bold))
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
            }
            .onAppear { playAnimation() }
        }
    }

    private func playAnimation() {
        CareTapHaptics.confirm()

        withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
            checkScale = 1
            backgroundOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            ringScale = 1.4
            ringOpacity = 1
        }

        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            ring2Scale = 1.6
            ring2Opacity = 1
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
            ringOpacity = 0
            ring2Opacity = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1
        }

        // Auto-dismiss after 1.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
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
