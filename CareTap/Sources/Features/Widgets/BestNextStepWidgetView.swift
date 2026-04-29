import SwiftUI

struct BestNextStepWidgetView: View {
    let snapshot: BestNextStepSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(snapshotAccent)
                    .frame(width: 24, height: 24)
                    .background(snapshotAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Spacer(minLength: 0)

                Text(snapshot.state.chipText)
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundStyle(snapshotAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(snapshot.subtitle)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text(actionLabel)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(snapshotAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(snapshotAccent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(widgetSurface)
    }

    private var widgetSurface: some ShapeStyle {
        CareTapTheme.surface.opacity(0.92)
    }

    private var snapshotAccent: Color {
        switch snapshot.state {
        case .completed:
            return CareTapTheme.success
        case .upcoming:
            return CareTapTheme.sage
        case .dueNow:
            return CareTapTheme.warm
        case .overdue:
            return CareTapTheme.alert
        case .snoozed:
            return CareTapTheme.mist
        }
    }

    private var actionLabel: String {
        switch snapshot.state {
        case .dueNow, .overdue:
            return "Open to log"
        case .snoozed:
            return "Resume"
        case .completed:
            return "View today"
        case .upcoming:
            return "Open home"
        }
    }

    private var symbolName: String {
        switch snapshot.state {
        case .completed:
            return "checkmark.circle.fill"
        case .upcoming:
            return "clock.fill"
        case .dueNow:
            return "hand.tap.fill"
        case .overdue:
            return "exclamationmark.circle.fill"
        case .snoozed:
            return "moon.zzz.fill"
        }
    }
}
