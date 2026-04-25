import SwiftUI

struct PatientMedicationDetailView: View {
    private enum DetailSection: String, CaseIterable, Hashable {
        case overview
        case routine
        case refill
        case recent

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .routine: return "Routine"
            case .refill: return "Refill"
            case .recent: return "Recent"
            }
        }
    }

    let medication: PatientMedicationRowState
    @State private var selectedSection: DetailSection = .overview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerHero
                sectionPicker
                selectedSectionContent
            }
            .padding(.horizontal, CareTapSpacing.screenPadding)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(CareTapTheme.canvas)
        .navigationTitle(medication.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerHero: some View {
        CareTapCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    CareTapMedicationPhotoView(
                        photoPath: medication.bottlePhotoLocalPath,
                        title: medication.title,
                        size: CGSize(width: 84, height: 104)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(medication.title)
                            .font(CareTapTypography.title)
                            .foregroundStyle(CareTapTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(medication.dosage)
                            .font(CareTapTypography.callout)
                            .foregroundStyle(CareTapTheme.textSecondary)

                        Text(medication.scheduleSummary)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        metadataChipLayout
                    }
                    .layoutPriority(1)

                    Spacer()
                }

                if !medication.bottleLabel.isEmpty {
                    detailBanner(
                        icon: "tag.fill",
                        title: "Label",
                        detail: medication.bottleLabel,
                        tint: CareTapTheme.mist
                    )
                }

                metricStrip
            }
        }
    }

    private var metadataChips: some View {
        Group {
            CareTapMiniChip(text: medication.category.title, tint: categoryTint)
            CareTapMiniChip(text: medication.containerKind.title, tint: CareTapTheme.mist)

            if medication.isTagPaired {
                CareTapMiniChip(text: "NFC paired", tint: CareTapTheme.sage)
            }

            if medication.hasRefillRisk {
                CareTapMiniChip(text: medication.refillLabel, tint: CareTapTheme.warm)
            }
        }
    }

    private var metadataChipLayout: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 6) {
                metadataChips
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    CareTapMiniChip(text: medication.category.title, tint: categoryTint)
                    CareTapMiniChip(text: medication.containerKind.title, tint: CareTapTheme.mist)
                }

                HStack(spacing: 6) {
                    if medication.isTagPaired {
                        CareTapMiniChip(text: "NFC paired", tint: CareTapTheme.sage)
                    }

                    if medication.hasRefillRisk {
                        CareTapMiniChip(text: medication.refillLabel, tint: CareTapTheme.warm)
                    }
                }
            }
        }
    }

    private var metricStrip: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 10) {
                metricTile(title: "Current", value: medication.currentDoseText, tint: CareTapTheme.sageStrong)
                metricTile(title: "Next", value: medication.upcomingDoseText, tint: CareTapTheme.textPrimary)
                metricTile(title: "Consistency", value: adherenceValue, tint: CareTapTheme.success)
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    metricTile(title: "Current", value: medication.currentDoseText, tint: CareTapTheme.sageStrong)
                    metricTile(title: "Next", value: medication.upcomingDoseText, tint: CareTapTheme.textPrimary)
                }

                metricTile(title: "Consistency", value: adherenceValue, tint: CareTapTheme.success)
            }
        }
    }

    private var sectionPicker: some View {
        CareTapSegmentedControl(
            items: DetailSection.allCases.map {
                CareTapSegmentedItem(id: $0, title: $0.title)
            },
            selectedID: selectedSection
        ) { selected in
            selectedSection = selected
        }
    }

    @ViewBuilder
    private var selectedSectionContent: some View {
        switch selectedSection {
        case .overview:
            VStack(alignment: .leading, spacing: 24) {
                statusSection
                detailsSection
            }
        case .routine:
            VStack(alignment: .leading, spacing: 24) {
                scheduleSection
                routineFactsSection
            }
        case .refill:
            if let refillStatus = medication.refillStatus {
                refillSection(refillStatus)
            } else {
                emptySection(
                    title: "No supply watch yet",
                    detail: "Add a supply count during setup to see when this routine is getting low.",
                    icon: "shippingbox"
                )
            }
        case .recent:
            activitySection
        }
    }

    private var statusSection: some View {
        CareTapGlassSection(title: "Today") {
            VStack(spacing: 10) {
                detailRow(label: "Current", value: medication.currentDoseText, tint: CareTapTheme.sageStrong)
                detailRow(label: "Next", value: medication.upcomingDoseText, tint: CareTapTheme.textPrimary)
                detailRow(label: "Consistency", value: medication.adherenceSummary, tint: CareTapTheme.success)
            }
        }
    }

    private func refillSection(_ refill: PatientRefillStatusState) -> some View {
        CareTapGlassSection(title: "Supply") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "pills.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(refill.tone.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(refill.headline)
                            .font(CareTapTypography.bodyStrong)
                            .foregroundStyle(CareTapTheme.textPrimary)
                        Text(refill.detail)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    CareTapStatusBadge(text: refill.quantityText, tone: refill.tone)
                }

                if !refill.thresholdText.isEmpty {
                    Text(refill.thresholdText)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var scheduleSection: some View {
        CareTapGlassSection(title: "Routine") {
            if medication.scheduleItems.isEmpty {
                emptySection(
                    title: "No routine yet",
                    detail: "This item has not been given a repeating schedule yet.",
                    icon: "calendar"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(medication.scheduleItems) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(CareTapTypography.bodyStrong)
                                    .foregroundStyle(CareTapTheme.textPrimary)
                                Text(item.detail)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                            }
                            Spacer()
                            CareTapStatusBadge(text: item.statusText, tone: item.tone)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
                        .careTapGlassStroke(cornerRadius: 14, opacity: 0.16)
                    }
                }
            }
        }
    }

    private var routineFactsSection: some View {
        CareTapGlassSection(title: "Setup") {
            VStack(alignment: .leading, spacing: 14) {
                labeledValue(title: "Form", value: medication.formText)
                labeledValue(title: "Food", value: medication.foodSummary)
                labeledValue(title: "Sharing", value: medication.ownershipSummary)
                labeledValue(title: "Tag", value: medication.nfcLabel)
            }
        }
    }

    private var activitySection: some View {
        CareTapGlassSection(title: "Recent Activity") {
            if medication.historyItems.isEmpty {
                emptySection(
                    title: "Nothing recent yet",
                    detail: "The latest confirmations and corrections will appear here.",
                    icon: "clock.arrow.circlepath"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(medication.historyItems) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.statusText)
                                        .font(CareTapTypography.bodyStrong)
                                        .foregroundStyle(CareTapTheme.textPrimary)
                                    Text(row.detail)
                                        .font(CareTapTypography.footnote)
                                        .foregroundStyle(CareTapTheme.textSecondary)
                                    if !row.secondaryDetail.isEmpty {
                                        Text(row.secondaryDetail)
                                            .font(CareTapTypography.footnote)
                                            .foregroundStyle(CareTapTheme.textTertiary)
                                    }
                                }
                                Spacer()
                                if !row.confidenceText.isEmpty {
                                    CareTapStatusBadge(text: row.confidenceText, tone: row.tone)
                                }
                            }

                            Text(row.sourceText)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)

                            if let resolutionReason = row.resolutionReason, !resolutionReason.isEmpty {
                                Text(resolutionReason)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
                        .careTapGlassStroke(cornerRadius: 14, opacity: 0.16)
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        CareTapGlassSection(title: "Overview") {
            VStack(alignment: .leading, spacing: 12) {
                labeledValue(title: "Category", value: medication.category.title)
                labeledValue(title: "Container", value: medication.containerKind.title)
                labeledValue(title: "Notes", value: medication.noteSummary)
            }
        }
    }

    private func detailRow(label: String, value: String, tint: Color) -> some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 12) {
                Text(label)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .frame(width: 72, alignment: .leading)

                Text(value)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)

                Text(value)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.16)
    }

    private func labeledValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
            Text(value)
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func metricTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.textTertiary)

            Text(value)
                .font(CareTapTypography.bodyStrong)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .careTapLiquidGlass(tint: tint.opacity(0.04), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.18)
    }

    private func detailBanner(icon: String, title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: tint.opacity(0.04), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.18)
    }

    private func emptySection(title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    private var adherenceValue: String {
        if let adherencePercent = medication.adherencePercent {
            return "\(adherencePercent)%"
        }

        return medication.adherenceSummary
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

#Preview {
    NavigationStack {
        PatientMedicationDetailView(
            medication: CareTapStateBuilder.patientMedicationRows(
                medications: [CareTapPhaseThreePreviewScenarios.medication],
                occurrences: [
                    CareTapPhaseThreePreviewScenarios.dueNowOccurrence,
                    CareTapPhaseThreePreviewScenarios.completedOccurrence
                ],
                refillStates: [CareTapPhaseThreePreviewScenarios.medication.id: CareTapPhaseThreePreviewScenarios.refillState],
                logsByOccurrenceID: [CareTapPhaseThreePreviewScenarios.completedOccurrence.id: [CareTapPhaseThreePreviewScenarios.acceptedDoseLog]],
                relationships: [CareTapPhaseThreePreviewScenarios.careRelationship]
            ).first!
        )
    }
}
