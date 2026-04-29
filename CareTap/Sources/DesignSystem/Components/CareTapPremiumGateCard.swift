import SwiftUI

struct CareTapPremiumGateCard: View {
    let title: String
    let detail: String
    var buttonTitle: String = "See Premium"
    var onAction: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CareTapTheme.warm.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CareTapTheme.warm)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()
            }

            Button(action: onAction) {
                HStack(spacing: 8) {
                    Text(buttonTitle)
                        .font(CareTapTypography.micro.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(CareTapTheme.sageStrong)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .careTapLiquidGlass(
                    tint: CareTapTheme.sage.opacity(0.05),
                    cornerRadius: 10,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: 10, opacity: 0.24)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.58)
        .careTapLiquidGlass(tint: CareTapTheme.warm.opacity(0.02), cornerRadius: CareTapSpacing.cornerRadiusCard)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.22)
    }
}
