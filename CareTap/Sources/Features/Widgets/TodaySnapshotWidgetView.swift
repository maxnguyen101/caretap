import SwiftUI

struct TodaySnapshotWidgetView: View {
    let snapshot: TodaySnapshotWidgetState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                CareTapProgressRing(
                    fraction: snapshot.progressFraction,
                    size: 44,
                    lineWidth: 5
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.title)
                        .font(.system(size: 19, weight: .semibold, design: .default))
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(snapshot.adherenceText)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 0)
            }

            Divider()
                .overlay(CareTapTheme.separator.opacity(0.5))

            HStack(alignment: .top, spacing: 12) {
                widgetDetail(
                    title: "Status",
                    detail: snapshot.adherenceText,
                    symbolName: "checkmark.circle.fill",
                    accent: CareTapTheme.success
                )

                widgetDetail(
                    title: "Next",
                    detail: snapshot.nextDoseText,
                    symbolName: "clock.fill",
                    accent: CareTapTheme.warm
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(widgetSurface)
    }

    @ViewBuilder
    private func widgetDetail(
        title: String,
        detail: String,
        symbolName: String,
        accent: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)

                Text(detail)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var widgetSurface: some ShapeStyle {
        CareTapTheme.surface.opacity(0.92)
    }
}
