import Charts
import SwiftUI

/// Quiet metrics surface for the Workspace tab.
struct CareTapInsightsDashboard: View {
    let adherenceFraction: Double
    let adherenceLabel: String
    let adherenceCaption: String
    let primaryStat: StatValue
    let secondaryStats: [StatValue]
    let trend: [DailyTrendPoint]
    let trendSubtitle: String

    struct StatValue: Identifiable, Hashable {
        let id: String
        let label: String
        let value: String
        let accent: Accent
        let progress: Double?

        init(
            id: String = UUID().uuidString,
            label: String,
            value: String,
            accent: Accent,
            progress: Double? = nil
        ) {
            self.id = id
            self.label = label
            self.value = value
            self.accent = accent
            self.progress = progress
        }

        enum Accent: Hashable {
            case sage
            case warm
            case alert
            case neutral

            var color: Color {
                switch self {
                case .sage: CareTapTheme.sageStrong
                case .warm: CareTapTheme.warm
                case .alert: CareTapTheme.alert
                case .neutral: CareTapTheme.textSecondary
                }
            }

            var fill: Color {
                switch self {
                case .sage: CareTapTheme.sage.opacity(0.16)
                case .warm: CareTapTheme.warm.opacity(0.16)
                case .alert: CareTapTheme.alert.opacity(0.16)
                case .neutral: CareTapTheme.surfaceMuted
                }
            }
        }
    }

    struct DailyTrendPoint: Identifiable, Hashable {
        let id: UUID
        let date: Date
        let loggedCount: Int
        let scheduledCount: Int

        init(id: UUID = UUID(), date: Date, loggedCount: Int, scheduledCount: Int) {
            self.id = id
            self.date = date
            self.loggedCount = loggedCount
            self.scheduledCount = scheduledCount
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroRow
            if !secondaryStats.isEmpty {
                metricsRow
            }
            if !trend.isEmpty {
                trendSection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.62)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.25)
    }

    private var heroRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(adherenceLabel)
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(primaryStat.value)
                        .font(.system(size: 34, weight: .semibold, design: .default))
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .contentTransition(.numericText())

                    Text(primaryStat.label)
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Text(adherenceCaption)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            progressBar
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CareTapTheme.surfaceMuted)
                Capsule()
                    .fill(CareTapTheme.sageStrong)
                    .frame(width: max(8, proxy.size.width * adherenceFraction.clamped(0, 1)))
                    .animation(.easeOut(duration: 0.28), value: adherenceFraction)
            }
        }
        .frame(height: 6)
    }

    private var metricsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(secondaryStats.enumerated()), id: \.element.id) { index, stat in
                    metricChip(stat)
                    if index < secondaryStats.count - 1 {
                        Divider()
                            .overlay(CareTapTheme.separator.opacity(0.45))
                            .padding(.vertical, 4)
                    }
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(secondaryStats.enumerated()), id: \.element.id) { index, stat in
                    metricChip(stat)
                    if index < secondaryStats.count - 1 {
                        Divider()
                            .overlay(CareTapTheme.separator.opacity(0.45))
                    }
                }
            }
        }
    }

    private func metricChip(_ stat: StatValue) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(stat.value)
                .font(.system(size: 19, weight: .semibold, design: .default))
                .foregroundStyle(stat.accent.color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .contentTransition(.numericText())

            Text(stat.label)
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Recent trend")
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textSecondary)

                Spacer()

                Text(trendSubtitle)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Chart(trend) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Logged", point.loggedCount)
                )
                .cornerRadius(4)
                .foregroundStyle(CareTapTheme.sageStrong.opacity(0.74))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(Self.dayFormatter.string(from: date))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(CareTapTheme.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartPlotStyle { plot in
                plot.frame(height: 90)
            }
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter
    }()
}

private extension Double {
    func clamped(_ lower: Double, _ upper: Double) -> Double {
        Swift.min(Swift.max(self, lower), upper)
    }
}
