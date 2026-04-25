import Charts
import SwiftUI

/// Apple-style metrics surface for the Workspace tab. Replaces the flat number
/// tiles with a primary adherence ring, a soft 7-day logged-doses chart, and a
/// row of sage-tinted metric chips that scale gracefully with Dynamic Type.
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
        VStack(alignment: .leading, spacing: 18) {
            heroRow
            if !secondaryStats.isEmpty {
                metricsRow
            }
            if !trend.isEmpty {
                trendSection
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.55)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.04), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.24)
    }

    // MARK: - Hero

    private var heroRow: some View {
        HStack(alignment: .top, spacing: 16) {
            adherenceRing

            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)

                Text(adherenceLabel)
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(adherenceCaption)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var adherenceRing: some View {
        ZStack {
            Circle()
                .stroke(CareTapTheme.surfaceMuted, lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(adherenceFraction.clamped(0, 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            CareTapTheme.sage,
                            CareTapTheme.sageStrong,
                            CareTapTheme.sage
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8, bounce: 0.15), value: adherenceFraction)

            VStack(spacing: 0) {
                Text(primaryStat.value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                Text(primaryStat.label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)
                    .textCase(.uppercase)
            }
            .padding(8)
        }
        .frame(width: 96, height: 96)
    }

    // MARK: - Metric row

    private var metricsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                ForEach(secondaryStats) { stat in
                    metricChip(stat)
                }
            }

            VStack(spacing: 10) {
                ForEach(secondaryStats) { stat in
                    metricChip(stat)
                }
            }
        }
    }

    private func metricChip(_ stat: StatValue) -> some View {
        HStack(alignment: .center, spacing: 12) {
            miniRing(color: stat.accent.color, progress: stat.progress)

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .contentTransition(.numericText())
                Text(stat.label)
                    .font(CareTapTypography.footnote.weight(.medium))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(stat.accent.fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(stat.accent.color.opacity(0.18), lineWidth: 1)
        }
    }

    private func miniRing(color: Color, progress: Double?) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: 4)
            if let progress {
                Circle()
                    .trim(from: 0, to: CGFloat(progress.clamped(0, 1)))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6, bounce: 0.1), value: progress)
            } else {
                Circle()
                    .fill(color.opacity(0.12))
                    .padding(4)
            }
        }
        .frame(width: 34, height: 34)
    }

    // MARK: - Trend

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Recent trend")
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)

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
                .cornerRadius(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [CareTapTheme.sage, CareTapTheme.sageStrong],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .annotation(position: .top, alignment: .center, spacing: 2) {
                    if point.loggedCount > 0 {
                        Text("\(point.loggedCount)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(CareTapTheme.sageStrong)
                    }
                }
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
