import SwiftUI

struct CareTapDoseActivityView: View {
    let state: CareTapDoseActivityViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(accentColor)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("TapCare")
                            .font(CareTapTypography.micro)
                            .foregroundStyle(CareTapTheme.textTertiary)
                            .textCase(.uppercase)

                        Text("Due \(state.dueTimeText)")
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                CareTapStatusBadge(text: state.statusText, tone: state.statusTone)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.medicationName)
                    .font(CareTapTypography.section)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(state.dosage)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: 12) {
                    actionPill
                    Spacer(minLength: 0)
                    Text(state.statusText)
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    actionPill
                    Text(state.statusText)
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            CareTapTheme.surface.opacity(0.88),
                            CareTapTheme.canvasWarm.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                        )
                )
        )
        .overlay {
            Image("GlassTexture")
                .resizable()
                .scaledToFill()
                .opacity(0.12)
                .blendMode(.softLight)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var accentColor: Color {
        switch state.statusTone {
        case .alert:
            return CareTapTheme.alert
        case .warm:
            return CareTapTheme.warm
        case .success:
            return CareTapTheme.success
        case .sage:
            return CareTapTheme.sage
        case .neutral:
            return CareTapTheme.textSecondary
        case .mist:
            return CareTapTheme.mist
        }
    }

    private var actionPill: some View {
        Text(state.primaryActionLabel)
            .font(CareTapTypography.micro.weight(.semibold))
            .foregroundStyle(accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.12), in: Capsule())
    }
}

#Preview("Live Activity · Due Now") {
    CareTapDoseActivityView(
        state: CareTapDoseActivityViewState(contentState: CareTapPhaseThreePreviewScenarios.liveActivityDueNow)
    )
}

#Preview("Live Activity · Overdue") {
    CareTapDoseActivityView(
        state: CareTapDoseActivityViewState(contentState: CareTapPhaseThreePreviewScenarios.liveActivityOverdue)
    )
}

#Preview("Live Activity · Snoozed") {
    CareTapDoseActivityView(
        state: CareTapDoseActivityViewState(contentState: CareTapPhaseThreePreviewScenarios.liveActivitySnoozed)
    )
}

#Preview("Live Activity · Completed") {
    CareTapDoseActivityView(
        state: CareTapDoseActivityViewState(contentState: CareTapPhaseThreePreviewScenarios.liveActivityCompleted)
    )
}
