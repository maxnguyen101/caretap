import SwiftUI

struct CareTapDoseActivityView: View {
    enum Presentation {
        case lockScreen
        case island
    }

    let state: CareTapDoseActivityViewState
    var presentation: Presentation = .lockScreen

    var body: some View {
        switch presentation {
        case .lockScreen:
            lockScreenLayout
        case .island:
            islandLayout
        }
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

    private var lockScreenLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            statusIcon(size: 34, symbolSize: 15)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(state.statusText)
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .foregroundStyle(accentColor)
                        .lineLimit(1)

                    Text("Due \(state.dueTimeText)")
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Text(state.medicationName)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(state.dosage)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 6)

            actionPill
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var islandLayout: some View {
        HStack(alignment: .center, spacing: 10) {
            statusIcon(size: 28, symbolSize: 13)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.medicationName)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("\(state.dosage) · \(state.dueTimeText)")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 4)

            Text(state.primaryActionLabel)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }

    private var actionPill: some View {
        Text(state.primaryActionLabel)
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func statusIcon(size: CGFloat, symbolSize: CGFloat) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: symbolSize, weight: .semibold))
            .foregroundStyle(accentColor)
            .frame(width: size, height: size)
            .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var symbolName: String {
        switch state.statusTone {
        case .alert:
            return "exclamationmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warm:
            return "hand.tap.fill"
        case .mist:
            return "moon.zzz.fill"
        default:
            return "pills.fill"
        }
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
