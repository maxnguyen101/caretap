import SwiftUI

struct PatientScheduleView: View {
    let medications: [PatientMedicationRowState]
    let premiumStatus: CareTapPremiumStatusState
    var showsHeader: Bool = true
    var onAddMedication: () -> Void = {}
    var onOpenPremium: () -> Void = {}
    var onSelectMedication: (PatientMedicationRowState) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if showsHeader {
                header
            }

            if medications.isEmpty {
                emptyState
            } else {
                insightsSection

                if !dueNowItems.isEmpty {
                    medicationSection(title: "Needs Check-In", items: dueNowItems)
                }

                if !upcomingItems.isEmpty {
                    medicationSection(title: "Up Next", items: upcomingItems)
                }

                if !refillWatch.isEmpty {
                    medicationSection(title: "Supply Watch", items: refillWatch)
                }

                if !pausedItems.isEmpty {
                    medicationSection(title: "Paused", items: pausedItems)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Items")
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text("What needs a check-in, what’s coming later, and what may need supply attention.")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

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
                    .careTapGlassStroke(cornerRadius: 22, opacity: 0.4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add item")
        }
    }

    private var insightsSection: some View {
        CareTapInsightsDashboard(
            adherenceFraction: adherenceFraction,
            adherenceLabel: "Today",
            adherenceCaption: adherenceCaption,
            primaryStat: .init(
                label: "Adherence",
                value: averageAdherence.map { "\($0)%" } ?? "—",
                accent: .sage,
                progress: adherenceFraction
            ),
            secondaryStats: [
                .init(
                    id: "open",
                    label: "Open",
                    value: "\(dueNowItems.count)",
                    accent: dueNowItems.isEmpty ? .sage : .alert,
                    progress: medications.isEmpty ? nil : Double(dueNowItems.count) / Double(max(medications.count, 1))
                ),
                .init(
                    id: "supply",
                    label: "Supply",
                    value: "\(refillWatch.count)",
                    accent: refillWatch.isEmpty ? .sage : .warm,
                    progress: medications.isEmpty ? nil : Double(refillWatch.count) / Double(max(medications.count, 1))
                ),
                .init(
                    id: "tap",
                    label: "Tap ready",
                    value: "\(pairedCount)",
                    accent: .sage,
                    progress: medications.isEmpty ? nil : Double(pairedCount) / Double(max(medications.count, 1))
                )
            ],
            trend: [],
            trendSubtitle: ""
        )
    }

    private var adherenceFraction: Double {
        let values = medications.compactMap(\.adherencePercent).map { Double($0) / 100.0 }
        guard !values.isEmpty else { return 0 }
        let averaged = values.reduce(0, +) / Double(values.count)
        return min(max(averaged, 0), 1)
    }

    private var adherenceCaption: String {
        if dueNowItems.isEmpty {
            if refillWatch.isEmpty {
                return "Nothing needs attention right now."
            }
            return "\(refillWatch.count) item\(refillWatch.count == 1 ? "" : "s") to watch for refill."
        }
        return "\(dueNowItems.count) item\(dueNowItems.count == 1 ? "" : "s") open — tap to log as soon as you take them."
    }

    private func medicationSection(title: String, items: [PatientMedicationRowState]) -> some View {
        CareTapGlassSection(title: title) {
            VStack(spacing: 10) {
                ForEach(items) { medication in
                    Button {
                        onSelectMedication(medication)
                    } label: {
                        MedicationRowTile(medication: medication)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            CareTapEmptyState(
                icon: "pills",
                title: "No routine yet",
                message: "Add the first medication, vitamin, or supplement. TapCare will keep the setup short."
            )

            if showsHeader {
                CareTapPrimaryActionButton(
                    title: "Add Your First Item",
                    systemImage: "plus",
                    action: onAddMedication
                )
            }
        }
    }

    private var dueNowItems: [PatientMedicationRowState] {
        medications.filter { $0.isActive && $0.hasCurrentOpenDose }
    }

    private var upcomingItems: [PatientMedicationRowState] {
        medications.filter { $0.isActive && !$0.hasCurrentOpenDose && !$0.hasRefillRisk }
    }

    private var refillWatch: [PatientMedicationRowState] {
        medications.filter { $0.isActive && $0.hasRefillRisk }
    }

    private var pausedItems: [PatientMedicationRowState] {
        medications.filter { !$0.isActive }
    }

    private var pairedCount: Int {
        medications.filter(\.isTagPaired).count
    }

    private var averageAdherence: Int? {
        let values = medications.compactMap(\.adherencePercent)
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

}

private struct MedicationRowTile: View {
    let medication: PatientMedicationRowState

    var body: some View {
        HStack(spacing: 14) {
            CareTapMedicationPhotoView(
                photoPath: medication.bottlePhotoLocalPath,
                title: medication.title,
                size: CGSize(width: 52, height: 64)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(medication.title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(medication.dosage)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .vertical) {
                    HStack(spacing: 6) {
                        CareTapMiniChip(text: medication.category.title, tint: categoryTint)
                        if medication.isTagPaired {
                            CareTapMiniChip(text: "NFC", tint: CareTapTheme.sage)
                        }
                        if medication.hasRefillRisk {
                            CareTapMiniChip(text: "Refill", tint: CareTapTheme.warm)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            CareTapMiniChip(text: medication.category.title, tint: categoryTint)
                            if medication.isTagPaired {
                                CareTapMiniChip(text: "NFC", tint: CareTapTheme.sage)
                            }
                        }
                        if medication.hasRefillRisk {
                            CareTapMiniChip(text: "Refill", tint: CareTapTheme.warm)
                        }
                    }
                }
            }
            .layoutPriority(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(medication.hasCurrentOpenDose ? "Open now" : "Next")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(medication.hasCurrentOpenDose ? CareTapTheme.alert : CareTapTheme.textTertiary)

                Text(medication.hasCurrentOpenDose ? medication.currentDoseText : medication.upcomingDoseText)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let dosesRemainingEstimate = medication.dosesRemainingEstimate {
                    Text("\(dosesRemainingEstimate) left")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(
            tint: medication.hasCurrentOpenDose
                ? CareTapTheme.alert.opacity(0.03)
                : CareTapTheme.glassTint.opacity(0.02),
            cornerRadius: 18
        )
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.22)
        .contentShape(Rectangle())
        .accessibilityLabel("\(medication.title), \(medication.dosage)")
    }

    private var categoryTint: Color {
        switch medication.category {
        case .prescription:
            return CareTapTheme.sage
        case .otc:
            return CareTapTheme.mist
        case .supplement:
            return CareTapTheme.warm
        }
    }
}
