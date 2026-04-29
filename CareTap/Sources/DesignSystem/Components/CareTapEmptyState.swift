import SwiftUI

/// A unified empty state view used throughout CareTap.
/// Provides a large icon, title, message, and an optional call-to-action.
struct CareTapEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var tint: Color = CareTapTheme.sage
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(tint.opacity(0.5))

                Text(title)
                    .font(CareTapTypography.section)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(actionTitle)
                            .font(CareTapTypography.bodyStrong)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .careTapLiquidGlass(
                        tint: CareTapTheme.sage.opacity(0.05),
                        cornerRadius: 10,
                        interactive: true
                    )
                    .careTapGlassStroke(cornerRadius: 10, opacity: 0.26)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
