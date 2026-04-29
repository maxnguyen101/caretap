import SwiftUI

struct CaregiverPersonDetailView: View {
    let relationship: CaregiverRelationshipRowState
    let medications: [PatientMedicationRowState]
    let historyRows: [PatientHistoryRowState]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroCard
                itemsSection
                historySection
            }
            .padding(.horizontal, CareTapSpacing.screenPadding)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .background(CareTapTheme.canvas)
        .navigationTitle(relationship.lovedOneName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        CareTapCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(relationship.lovedOneName)
                            .font(CareTapTypography.title)
                            .foregroundStyle(CareTapTheme.textPrimary)

                        Text(relationship.accessLevelTitle)
                            .font(CareTapTypography.callout)
                            .foregroundStyle(CareTapTheme.textSecondary)
                    }

                    Spacer()

                    CareTapStatusBadge(
                        text: relationship.showsAttention ? "Needs attention" : "On track",
                        tone: relationship.showsAttention ? .alert : .success
                    )
                }

                if !relationship.permissionTags.isEmpty {
                    CaregiverDetailTagRow(tags: relationship.permissionTags)
                }

                Text(relationship.alertPreferencesText)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var itemsSection: some View {
        CareTapGlassSection(title: "Tracked items") {
            if medications.isEmpty {
                emptyRow(icon: "square.stack.3d.up", text: "No active items are visible right now.")
            } else {
                VStack(spacing: 10) {
                    ForEach(medications.prefix(4)) { medication in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(medication.title)
                                    .font(CareTapTypography.bodyStrong)
                                    .foregroundStyle(CareTapTheme.textPrimary)
                                Text(medication.hasCurrentOpenDose ? medication.currentDoseText : medication.upcomingDoseText)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            if medication.hasRefillRisk {
                                CareTapStatusBadge(text: "Refill", tone: .warm)
                            } else if medication.hasCurrentOpenDose {
                                CareTapStatusBadge(text: "Open", tone: .alert)
                            } else {
                                CareTapStatusBadge(text: "Scheduled", tone: .mist)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: 14)
                        .careTapGlassStroke(cornerRadius: 14, opacity: 0.18)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        CareTapGlassSection(title: "Recent activity") {
            if historyRows.isEmpty {
                emptyRow(icon: "clock.arrow.circlepath", text: "Recent shared check-ins will show up here.")
            } else {
                VStack(spacing: 10) {
                    ForEach(historyRows.prefix(5)) { row in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(row.tone.color.opacity(0.18))
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Circle()
                                        .fill(row.tone.color)
                                        .frame(width: 6, height: 6)
                                }
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(row.statusText)
                                        .font(CareTapTypography.bodyStrong)
                                        .foregroundStyle(CareTapTheme.textPrimary)
                                    Spacer()
                                    Text(row.detail)
                                        .font(CareTapTypography.micro)
                                        .foregroundStyle(CareTapTheme.textTertiary)
                                }

                                Text(row.sourceText)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)

                                if !row.secondaryDetail.isEmpty {
                                    Text(row.secondaryDetail)
                                        .font(CareTapTypography.micro)
                                        .foregroundStyle(CareTapTheme.textTertiary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: 14)
                        .careTapGlassStroke(cornerRadius: 14, opacity: 0.18)
                    }
                }
            }
        }
    }

    private func emptyRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)

            Text(text)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct CaregiverDetailTagRow: View {
    let tags: [String]

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }
            }
        }
    }

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(CareTapTypography.micro.weight(.semibold))
            .foregroundStyle(CareTapTheme.sageStrong)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
