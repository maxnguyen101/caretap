import SwiftUI

struct BestNextStepWidgetView: View {
    let snapshot: BestNextStepSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TapCare")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .textCase(.uppercase)

                    CareTapStatusBadge(text: snapshot.state.chipText, tone: snapshot.state.tone)
                }

                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                CareTapTheme.surface.opacity(0.92),
                                CareTapTheme.canvasWarm.opacity(0.86)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: "wave.3.right.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(snapshotAccent)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.18), lineWidth: 1)
                    }
                    .frame(width: 38, height: 38)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.title)
                    .font(.system(size: 21, weight: .semibold, design: .default))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)

                Text(snapshot.subtitle)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Text(actionLabel)
                    .font(CareTapTypography.micro.weight(.semibold))
                    .foregroundStyle(snapshotAccent)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(snapshotAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CareTapTheme.surface.opacity(0.74))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CareTapTheme.stroke.opacity(0.14), lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(18)
        .background(widgetSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            Image("GlassTexture")
                .resizable()
                .scaledToFill()
                .opacity(0.12)
                .blendMode(.softLight)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.14), lineWidth: 1)
        }
    }

    private var widgetSurface: some ShapeStyle {
        LinearGradient(
            colors: [
                CareTapTheme.surface.opacity(0.95),
                CareTapTheme.canvasWarm.opacity(0.985),
                CareTapTheme.canvasMist.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            return "Log now"
        case .snoozed:
            return "Resume soon"
        case .completed:
            return "View today"
        case .upcoming:
            return "Open home"
        }
    }
}
