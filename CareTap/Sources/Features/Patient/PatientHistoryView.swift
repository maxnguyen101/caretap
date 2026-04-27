import SwiftUI

enum CareTapHistoryContext {
    case patient
    case caregiver
}

struct PatientHistoryView: View {
    let rows: [PatientHistoryRowState]
    let premiumStatus: CareTapPremiumStatusState
    var context: CareTapHistoryContext = .patient
    var showsHeader: Bool = true
    var onUndoRow: ((PatientHistoryRowState) -> Void)? = nil
    var onOpenPremium: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if showsHeader {
                header
            }

            if rows.isEmpty {
                emptyState
            } else {
                insightsDashboard
                recentSection
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(context == .patient ? "History" : "Recent activity")
                .font(CareTapTypography.title)
                .foregroundStyle(CareTapTheme.textPrimary)

            Text(
                context == .patient
                    ? "Recent check-ins, skips, and anything that still needs attention."
                    : "A calmer view of recent shared check-ins, misses, and updated entries."
            )
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
        }
    }

    private var insightsDashboard: some View {
        CareTapInsightsDashboard(
            adherenceFraction: adherenceFraction,
            adherenceLabel: context == .patient ? "Recent" : "Check-ins",
            adherenceCaption: adherenceCaption,
            primaryStat: .init(
                label: "Done",
                value: "\(confirmedCount)",
                accent: .sage,
                progress: adherenceFraction
            ),
            secondaryStats: [
                .init(
                    id: "attention",
                    label: "Attention",
                    value: "\(attentionCount)",
                    accent: attentionCount > 0 ? .alert : .sage,
                    progress: rows.isEmpty ? nil : Double(attentionCount) / Double(max(rows.count, 1))
                ),
                .init(
                    id: "corrections",
                    label: "Corrections",
                    value: "\(correctionCount)",
                    accent: correctionCount > 0 ? .warm : .sage,
                    progress: rows.isEmpty ? nil : Double(correctionCount) / Double(max(rows.count, 1))
                ),
                .init(
                    id: "tap",
                    label: "Tap logs",
                    value: "\(tapConfirmedCount)",
                    accent: .sage,
                    progress: rows.isEmpty ? nil : Double(tapConfirmedCount) / Double(max(rows.count, 1))
                )
            ],
            trend: trendPoints,
            trendSubtitle: "Last 7 days"
        )
    }

    private var adherenceFraction: Double {
        let total = rows.count
        guard total > 0 else { return 0 }
        return min(max(Double(confirmedCount) / Double(total), 0), 1)
    }

    private var adherenceCaption: String {
        if attentionCount == 0 && correctionCount == 0 {
            return "Everything recent is in good shape."
        }
        var parts: [String] = []
        if attentionCount > 0 {
            parts.append("\(attentionCount) need\(attentionCount == 1 ? "s" : "") review")
        }
        if correctionCount > 0 {
            parts.append("\(correctionCount) corrected")
        }
        return parts.joined(separator: " · ")
    }

    private var trendPoints: [CareTapInsightsDashboard.DailyTrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }

        let loggedByDay: [Date: Int] = rows
            .compactMap { row -> (Date, Int)? in
                guard let logged = row.loggedAt else { return nil }
                return (calendar.startOfDay(for: logged), 1)
            }
            .reduce(into: [:]) { partial, entry in partial[entry.0, default: 0] += entry.1 }

        let scheduledByDay: [Date: Int] = rows.reduce(into: [:]) { partial, row in
            partial[calendar.startOfDay(for: row.scheduledAt), default: 0] += 1
        }

        return days.map { day in
            CareTapInsightsDashboard.DailyTrendPoint(
                date: day,
                loggedCount: loggedByDay[day] ?? 0,
                scheduledCount: scheduledByDay[day] ?? 0
            )
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedRows, id: \.title) { group in
                CareTapGlassSection(title: group.title) {
                    VStack(spacing: 10) {
                        ForEach(group.rows) { row in
                            HistoryRowCard(row: row, onUndo: onUndoRow == nil || !canUndo(row) ? nil : {
                                onUndoRow?(row)
                            })
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        CareTapEmptyState(
            icon: "chart.bar",
            title: context == .patient ? "Nothing logged yet" : "Nothing shared yet",
            message: context == .patient
                ? "Check-ins, misses, and corrections will appear here."
                : "Recent linked routine activity will appear here once check-ins are shared."
        )
    }

    private var confirmedCount: Int {
        rows.filter { ["Taken", "Late", "Resolved"].contains($0.statusText) }.count
    }

    private var attentionCount: Int {
        rows.filter { ["Missed", "Overdue", "Skipped"].contains($0.statusText) }.count
    }

    private var correctionCount: Int {
        rows.filter(\.isCorrection).count
    }

    private var tapConfirmedCount: Int {
        rows.filter { $0.sourceText.localizedCaseInsensitiveContains("tap") }.count
    }

    private var groupedRows: [HistoryDayGroup] {
        let grouped = Dictionary(grouping: rows) { row in
            Calendar.current.startOfDay(for: row.scheduledAt)
        }

        return grouped
            .map { date, rows in
                HistoryDayGroup(
                    title: date.formatted(date: .abbreviated, time: .omitted),
                    rows: rows.sorted { $0.scheduledAt > $1.scheduledAt }
                )
            }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.rows.first?.scheduledAt, let rhsDate = rhs.rows.first?.scheduledAt else {
                    return lhs.title > rhs.title
                }
                return lhsDate > rhsDate
            }
    }

    private func canUndo(_ row: PatientHistoryRowState) -> Bool {
        guard row.loggedAt != nil, !row.isCorrection else {
            return false
        }

        switch row.statusText {
        case "Taken", "Late", "Skipped", "Resolved":
            return true
        default:
            return false
        }
    }

}

private struct HistoryDayGroup: Hashable {
    let title: String
    let rows: [PatientHistoryRowState]
}

private struct HistoryRowCard: View {
    let row: PatientHistoryRowState
    var onUndo: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(row.tone.color.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(row.tone.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                ViewThatFits(in: .vertical) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(row.detail)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        CareTapStatusBadge(text: row.statusText, tone: row.tone)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(row.detail)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        CareTapStatusBadge(text: row.statusText, tone: row.tone)
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: 6) {
                        Text(row.sourceText)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textTertiary)

                        if !row.confidenceText.isEmpty {
                            Circle()
                                .fill(CareTapTheme.textTertiary.opacity(0.7))
                                .frame(width: 3, height: 3)

                            Text(row.confidenceText)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textTertiary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.sourceText)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !row.confidenceText.isEmpty {
                            Text(row.confidenceText)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !row.secondaryDetail.isEmpty {
                    Text(row.secondaryDetail)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let resolutionReason = row.resolutionReason, !resolutionReason.isEmpty {
                    Text(resolutionReason)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let onUndo {
                    Button("Undo last check-in") {
                        onUndo()
                    }
                    .buttonStyle(.plain)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.sageStrong)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: row.tone.color.opacity(0.02), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.18)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch row.statusText {
        case "Taken", "Late", "Resolved": return "checkmark"
        case "Missed", "Overdue": return "exclamationmark"
        case "Skipped": return "arrow.uturn.right"
        default: return "circle.fill"
        }
    }
}
