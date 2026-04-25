import SwiftUI

struct PatientSetupCompletionView: View {
    let state: SetupCompletionViewState
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: () -> Void = {}

    var body: some View {
        CareTapFlowScaffold(
            leadingSystemImage: nil
        ) {
            VStack(spacing: 32) {
                CareTapSetupProgressHeader(stepText: "Step 3 of 3", title: "Setup")

                celebrationHero
                summaryChecklist
                nextStepHint
            }
        } footer: {
            CareTapFooterActionBar(
                secondaryTitle: "Review",
                primaryTitle: state.primaryActionTitle,
                primarySystemImage: "house.fill",
                secondaryAction: onSecondaryAction,
                primaryAction: onPrimaryAction
            )
        }
    }

    // MARK: - Celebration

    private var celebrationHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CareTapTheme.success.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(CareTapTheme.success.opacity(0.12), lineWidth: 1)
                    .frame(width: 124, height: 124)

                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(CareTapTheme.success)
            }

            VStack(spacing: 8) {
                Text(state.title)
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(state.message)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Summary

    private var summaryChecklist: some View {
        VStack(spacing: 8) {
            ForEach(state.summaryItems, id: \.self) { item in
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(CareTapTheme.sageStrong)

                    Text(item)
                        .font(CareTapTypography.body)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(14)
                .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.03), cornerRadius: 16)
                .careTapGlassStroke(cornerRadius: 16, opacity: 0.18)
            }
        }
    }

    // MARK: - Hint

    private var nextStepHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CareTapTheme.sageStrong)
                .frame(width: 32, height: 32)
                .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Tap the tag or use the manual button on Home when it's time.")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.15)
    }
}
