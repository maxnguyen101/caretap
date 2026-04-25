import SwiftUI

struct CareTapStateCard: View {
    let icon: String
    let tone: CareTapTone
    let title: String
    let message: String
    var showsProgress: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tone.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                if showsProgress {
                    ProgressView()
                        .tint(tone.color)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tone.color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text(message)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.5)
        .careTapLiquidGlass(tint: tone.color.opacity(0.03), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.25)
        .accessibilityElement(children: .combine)
    }
}

struct CareTapInlineBanner: View {
    let icon: String
    let tone: CareTapTone
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tone.color)
                .frame(width: 32, height: 32)
                .background(tone.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(tone.color)
                Text(message)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.color.opacity(0.03))
        .careTapLiquidGlass(tint: tone.color.opacity(0.04), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.25)
        .accessibilityElement(children: .combine)
    }
}
