import SwiftUI

struct CareTapProgressRing: View {
    let fraction: Double

    @State private var animatedFraction: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(CareTapTheme.surfaceMuted, lineWidth: 6)

            Circle()
                .trim(from: 0, to: animatedFraction.clamped(to: 0...1))
                .stroke(
                    AngularGradient(
                        colors: [CareTapTheme.sage, CareTapTheme.sageStrong],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow dot at the end of the arc
            if animatedFraction > 0.05 {
                Circle()
                    .fill(CareTapTheme.sageStrong)
                    .frame(width: 8, height: 8)
                    .shadow(color: CareTapTheme.sage.opacity(0.5), radius: 4)
                    .offset(y: -25)
                    .rotationEffect(.degrees(360 * animatedFraction - 90))
            }

            Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textPrimary)
                .contentTransition(.numericText(value: fraction))
        }
        .frame(width: 56, height: 56)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.spring(duration: 1.2, bounce: 0.15).delay(0.3)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
                animatedFraction = newValue
            }
        }
        .accessibilityLabel("Daily progress \(fraction.formatted(.percent.precision(.fractionLength(0))))")
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
