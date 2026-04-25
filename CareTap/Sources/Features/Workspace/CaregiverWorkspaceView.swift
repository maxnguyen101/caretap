import SwiftUI

struct CaregiverWorkspaceView: View {
    let selectedSection: CaregiverWorkspaceSection
    let relationships: [CaregiverRelationshipRowState]
    let invitations: [CaregiverInvitationRowState]
    let medicationRows: [PatientMedicationRowState]
    let historyRows: [PatientHistoryRowState]
    let premiumStatus: CareTapPremiumStatusState
    let inviteCode: String
    var onSectionSelected: (CaregiverWorkspaceSection) -> Void = { _ in }
    var onInviteCodeChanged: (String) -> Void = { _ in }
    var onAcceptInvite: () -> Void = {}
    var onDeclineInvite: () -> Void = {}
    var onSelectCareProfile: (UUID) -> Void = { _ in }
    var onOpenPersonDetail: (CaregiverRelationshipRowState) -> Void = { _ in }
    var onRevokeInvitation: (UUID) -> Void = { _ in }
    var onRevokeRelationship: (UUID) -> Void = { _ in }
    var onMissedDoseAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onRefillAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onOpenPremium: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summaryCard

                CareTapSegmentedControl(
                    items: CaregiverWorkspaceSection.allCases.map {
                        CareTapSegmentedItem(
                            id: $0,
                            title: $0.title,
                            subtitle: $0 == .people ? "Sharing and alerts" : "Recent monitoring"
                        )
                    },
                    selectedID: selectedSection,
                    onSelect: onSectionSelected
                )

                switch selectedSection {
                case .people:
                    CaregiverSupportView(
                        relationships: relationships,
                        invitations: invitations,
                        medicationRows: medicationRows,
                        premiumStatus: premiumStatus,
                        inviteCode: inviteCode,
                        showsHeader: false,
                        onInviteCodeChanged: onInviteCodeChanged,
                        onAcceptInvite: onAcceptInvite,
                        onDeclineInvite: onDeclineInvite,
                        onSelectCareProfile: onSelectCareProfile,
                        onOpenPersonDetail: onOpenPersonDetail,
                        onRevokeInvitation: onRevokeInvitation,
                        onRevokeRelationship: onRevokeRelationship,
                        onMissedDoseAlertsChanged: onMissedDoseAlertsChanged,
                        onRefillAlertsChanged: onRefillAlertsChanged,
                        onOpenPremium: onOpenPremium
                    )
                case .history:
                    PatientHistoryView(
                        rows: historyRows,
                        premiumStatus: premiumStatus,
                        context: .caregiver,
                        showsHeader: false,
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace")
                .font(CareTapTypography.title)
                .foregroundStyle(CareTapTheme.textPrimary)

            Text(
                selectedSection == .people
                    ? "People, invites, and alert settings in one place."
                    : "A short recent timeline for the routines you follow."
            )
            .font(CareTapTypography.callout)
            .foregroundStyle(CareTapTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selectedRelationship {
                ViewThatFits(in: .vertical) {
                    HStack(alignment: .top, spacing: 12) {
                        relationshipSummaryText(relationship: selectedRelationship)

                        Spacer()

                        statusBadge(for: selectedRelationship)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        relationshipSummaryText(relationship: selectedRelationship)
                        statusBadge(for: selectedRelationship)
                    }
                }
            }

            CareTapInsightsDashboard(
                adherenceFraction: adherenceFraction,
                adherenceLabel: selectedSection == .people ? "Care circle" : "Monitoring",
                adherenceCaption: adherenceCaption,
                primaryStat: .init(
                    label: "People",
                    value: "\(relationships.count)",
                    accent: .sage,
                    progress: adherenceFraction
                ),
                secondaryStats: [
                    .init(
                        id: "alerts",
                        label: "Alerts",
                        value: "\(attentionCount)",
                        accent: attentionCount > 0 ? .warm : .sage,
                        progress: relationships.isEmpty ? nil : min(Double(attentionCount) / Double(max(relationships.count, 1)), 1)
                    ),
                    .init(
                        id: "invites",
                        label: "Pending",
                        value: "\(invitations.count)",
                        accent: invitations.isEmpty ? .sage : .neutral,
                        progress: nil
                    ),
                    .init(
                        id: "paired",
                        label: "Tap-ready",
                        value: "\(pairedCount)",
                        accent: .sage,
                        progress: medicationRows.isEmpty ? nil : Double(pairedCount) / Double(max(medicationRows.count, 1))
                    )
                ],
                trend: [],
                trendSubtitle: ""
            )
        }
    }

    private var pairedCount: Int {
        medicationRows.filter(\.isTagPaired).count
    }

    private var adherenceFraction: Double {
        guard !relationships.isEmpty else { return 0 }
        let onTrack = Double(relationships.count - attentionCount)
        return max(0, min(onTrack / Double(relationships.count), 1))
    }

    private var adherenceCaption: String {
        if relationships.isEmpty {
            return "Connect someone with a shared code to start monitoring."
        }
        if attentionCount == 0 {
            return "Everyone you follow looks on track."
        }
        return "\(attentionCount) linked \(attentionCount == 1 ? "person" : "people") need a closer look."
    }

    private func relationshipSummaryText(relationship: CaregiverRelationshipRowState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(relationship.lovedOneName)
                .font(CareTapTypography.bodyStrong)
                .foregroundStyle(CareTapTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(relationship.statusText)
                .font(CareTapTypography.footnote)
                .foregroundStyle(relationship.showsAttention ? CareTapTheme.alert : CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    @ViewBuilder
    private func statusBadge(for relationship: CaregiverRelationshipRowState) -> some View {
        if relationship.showsAttention {
            CareTapStatusBadge(text: "Attention", tone: .warm)
        } else {
            CareTapStatusBadge(text: "On track", tone: .sage)
        }
    }

    private var selectedRelationship: CaregiverRelationshipRowState? {
        relationships.first(where: \.isSelected) ?? relationships.first
    }

    private var attentionCount: Int {
        selectedSection == .people
            ? relationships.filter(\.showsAttention).count
            : historyRows.filter { $0.tone == .alert || $0.tone == .warm }.count
    }
}
