import SwiftUI

struct CareTapSectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CareTapTheme.textSecondary)
            }

            Text(title)
                .font(CareTapTypography.section)
                .foregroundStyle(CareTapTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(CareTapTypography.footnote.weight(.medium))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
