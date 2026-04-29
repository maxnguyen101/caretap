import SwiftUI

struct CareTapProgressRing: View {
    let fraction: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 6

    @State private var animatedFraction: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(CareTapTheme.surfaceMuted, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedFraction.clamped(to: 0...1))
                .stroke(
                    CareTapTheme.sageStrong,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textPrimary)
                .contentTransition(.numericText(value: fraction))
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.easeOut(duration: 0.25)) {
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
