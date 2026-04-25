import SwiftUI

struct TodaySnapshotWidgetView: View {
    let snapshot: TodaySnapshotWidgetState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TapCare Today")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .textCase(.uppercase)

                    Text(snapshot.title)
                        .font(CareTapTypography.section)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(CareTapTheme.surface.opacity(0.78))
                    CareTapProgressRing(fraction: snapshot.progressFraction)
                        .padding(8)
                }
                .frame(width: 52, height: 52)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(CareTapTheme.stroke.opacity(0.16), lineWidth: 1)
                }
            }

            HStack(spacing: 10) {
                widgetDetailCard(
                    title: "Status",
                    detail: snapshot.adherenceText,
                    symbolName: "checkmark.circle.fill",
                    accent: CareTapTheme.success
                )

                widgetDetailCard(
                    title: "Next Up",
                    detail: snapshot.nextDoseText,
                    symbolName: "clock.fill",
                    accent: CareTapTheme.warm
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(18)
        .background(widgetSurface)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            Image("GlassTexture")
                .resizable()
                .scaledToFill()
                .opacity(0.12)
                .blendMode(.softLight)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.14), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func widgetDetailCard(
        title: String,
        detail: String,
        symbolName: String,
        accent: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .textCase(.uppercase)

                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    CareTapTheme.surface.opacity(0.84),
                    CareTapTheme.canvasWarm.opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.14), lineWidth: 1)
        }
    }

    private var widgetSurface: some ShapeStyle {
        LinearGradient(
            colors: [
                CareTapTheme.surface.opacity(0.98),
                CareTapTheme.canvasWarm.opacity(0.96),
                CareTapTheme.canvas.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
