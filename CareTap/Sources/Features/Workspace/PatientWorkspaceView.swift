import SwiftUI

struct PatientWorkspaceView: View {
    let selectedSection: PatientWorkspaceSection
    let medications: [PatientMedicationRowState]
    let historyRows: [PatientHistoryRowState]
    let premiumStatus: CareTapPremiumStatusState
    var onSectionSelected: (PatientWorkspaceSection) -> Void = { _ in }
    var onAddMedication: () -> Void = {}
    var onOpenPremium: () -> Void = {}
    var onSelectMedication: (PatientMedicationRowState) -> Void = { _ in }
    var onUndoHistoryRow: (PatientHistoryRowState) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summaryCard

                CareTapSegmentedControl(
                    items: PatientWorkspaceSection.allCases.map {
                        CareTapSegmentedItem(
                            id: $0,
                            title: $0.title,
                            subtitle: $0 == .items ? "Active and later today" : "Recent check-ins"
                        )
                    },
                    selectedID: selectedSection,
                    onSelect: onSectionSelected
                )

                switch selectedSection {
                case .items:
                    PatientScheduleView(
                        medications: medications,
                        premiumStatus: premiumStatus,
                        showsHeader: false,
                        onAddMedication: onAddMedication,
                        onOpenPremium: onOpenPremium,
                        onSelectMedication: onSelectMedication
                    )
                case .history:
                    PatientHistoryView(
                        rows: historyRows,
                        premiumStatus: premiumStatus,
                        context: .patient,
                        showsHeader: false,
                        onUndoRow: onUndoHistoryRow,
                        onOpenPremium: onOpenPremium
                    )
                }
            }
            .padding(.horizontal, CareTapSpacing.screenPadding)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .background(CareTapTheme.canvas)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedSection == .items ? "Routine" : "History")
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(
                    selectedSection == .items
                        ? "Medication, supplement, and refill details in one quieter place."
                        : "Recent check-ins, skips, corrections, and unresolved moments."
                )
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            if selectedSection == .items {
                Button(action: onAddMedication) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CareTapTheme.sageStrong)
                        .frame(width: 44, height: 44)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.sage.opacity(0.08),
                            cornerRadius: 22,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 22, opacity: 0.34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add item")
            }
        }
    }

    private var summaryCard: some View {
        CareTapInsightsDashboard(
            adherenceFraction: adherenceFraction,
            adherenceLabel: selectedSection == .items ? "At a glance" : "Recent patterns",
            adherenceCaption: adherenceCaption,
            primaryStat: .init(
                label: "Adherence",
                value: adherencePercentText,
                accent: .sage,
                progress: adherenceFraction
            ),
            secondaryStats: secondaryStats,
            trend: trendPoints,
            trendSubtitle: "Last 7 days"
        )
    }

    private var adherenceFraction: Double {
        let values = medications.compactMap(\.adherencePercent).map { Double($0) / 100.0 }
        guard !values.isEmpty else { return 0 }
        return (values.reduce(0, +) / Double(values.count)).clampedFraction
    }

    private var adherencePercentText: String {
        if let averaged = averageAdherencePercent {
            return "\(averaged)%"
        }
        return "—"
    }

    private var adherenceCaption: String {
        switch selectedSection {
        case .items:
            if medications.isEmpty {
                return "Add your first item to start tracking a routine."
            }
            return "\(activeMedicationCount) active \(activeMedicationCount == 1 ? "item" : "items") and \(openDoseCount) open now."
        case .history:
            if historyRows.isEmpty {
                return "Logs will appear here as soon as you confirm a dose."
            }
            return "\(loggedTodayCount) logged today · \(reviewCount) to review."
        }
    }

    private var secondaryStats: [CareTapInsightsDashboard.StatValue] {
        switch selectedSection {
        case .items:
            return [
                .init(
                    id: "open",
                    label: "Open now",
                    value: "\(openDoseCount)",
                    accent: openDoseCount > 0 ? .alert : .sage,
                    progress: medications.isEmpty ? nil : Double(openDoseCount) / Double(max(medications.count, 1))
                ),
                .init(
                    id: "supply",
                    label: "Supply watch",
                    value: "\(refillRiskCount)",
                    accent: refillRiskCount > 0 ? .warm : .sage,
                    progress: medications.isEmpty ? nil : Double(refillRiskCount) / Double(max(medications.count, 1))
                ),
                .init(
                    id: "paired",
                    label: "Tap ready",
                    value: "\(pairedCount)",
                    accent: .sage,
                    progress: medications.isEmpty ? nil : Double(pairedCount) / Double(max(medications.count, 1))
                )
            ]
        case .history:
            return [
                .init(
                    id: "logged",
                    label: "Logged",
                    value: "\(loggedCount)",
                    accent: .sage,
                    progress: totalHistoryCount > 0 ? Double(loggedCount) / Double(totalHistoryCount) : nil
                ),
                .init(
                    id: "review",
                    label: "Review",
                    value: "\(reviewCount)",
                    accent: reviewCount > 0 ? .warm : .sage,
                    progress: totalHistoryCount > 0 ? Double(reviewCount) / Double(totalHistoryCount) : nil
                ),
                .init(
                    id: "corrections",
                    label: "Corrections",
                    value: "\(correctionCount)",
                    accent: correctionCount > 0 ? .alert : .sage,
                    progress: totalHistoryCount > 0 ? Double(correctionCount) / Double(totalHistoryCount) : nil
                )
            ]
        }
    }

    private var averageAdherencePercent: Int? {
        let values = medications.compactMap(\.adherencePercent)
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    private var totalHistoryCount: Int { historyRows.count }

    private var loggedCount: Int { historyRows.filter { $0.loggedAt != nil }.count }

    private var loggedTodayCount: Int {
        let calendar = Calendar.current
        return historyRows.filter { row in
            guard let logged = row.loggedAt else { return false }
            return calendar.isDateInToday(logged)
        }.count
    }

    private var pairedCount: Int {
        medications.filter(\.isTagPaired).count
    }

    private var trendPoints: [CareTapInsightsDashboard.DailyTrendPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }

        let loggedByDay: [Date: Int] = historyRows
            .compactMap { row -> (Date, Int)? in
                guard let logged = row.loggedAt else { return nil }
                let startOfDay = calendar.startOfDay(for: logged)
                return (startOfDay, 1)
            }
            .reduce(into: [:]) { result, entry in
                result[entry.0, default: 0] += entry.1
            }

        let scheduledByDay: [Date: Int] = historyRows
            .reduce(into: [:]) { result, row in
                let startOfDay = calendar.startOfDay(for: row.scheduledAt)
                result[startOfDay, default: 0] += 1
            }

        return days.map { day in
            CareTapInsightsDashboard.DailyTrendPoint(
                date: day,
                loggedCount: loggedByDay[day] ?? 0,
                scheduledCount: scheduledByDay[day] ?? 0
            )
        }
    }

    private var activeMedicationCount: Int {
        selectedSection == .items
            ? medications.filter(\.isActive).count
            : historyRows.filter { $0.loggedAt != nil }.count
    }

    private var refillRiskCount: Int {
        selectedSection == .items
            ? medications.filter(\.hasRefillRisk).count
            : historyRows.filter { $0.tone == .alert || $0.tone == .warm }.count
    }

    private var openDoseCount: Int {
        medications.filter(\.hasCurrentOpenDose).count
    }

    private var reviewCount: Int {
        historyRows.filter { $0.tone == .alert || $0.tone == .warm }.count
    }

    private var correctionCount: Int {
        historyRows.filter(\.isCorrection).count
    }
}

private extension Double {
    var clampedFraction: Double {
        Swift.min(Swift.max(self, 0), 1)
    }
}
