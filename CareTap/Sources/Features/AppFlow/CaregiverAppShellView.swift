import SwiftUI

struct CaregiverAppShellView: View {
    let selectedDestination: CareTapDestination
    let selectedWorkspaceSection: CaregiverWorkspaceSection
    let homeState: CaregiverHomeState?
    let notificationCount: Int
    let medicationRows: [PatientMedicationRowState]
    let historyRows: [PatientHistoryRowState]
    let premiumStatus: CareTapPremiumStatusState
    let relationshipRows: [CaregiverRelationshipRowState]
    let invitationRows: [CaregiverInvitationRowState]
    let inviteCode: String
    let settingsState: SettingsViewState
    var onDestinationSelected: (CareTapDestination) -> Void = { _ in }
    var onWorkspaceSectionSelected: (CaregiverWorkspaceSection) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}
    var onQuickAction: (QuickActionState) -> Void = { _ in }
    var onSelectCareProfile: (UUID) -> Void = { _ in }
    var onInviteCodeChanged: (String) -> Void = { _ in }
    var onAcceptInvite: () -> Void = {}
    var onDeclineInvite: () -> Void = {}
    var onRevokeInvitation: (UUID) -> Void = { _ in }
    var onRevokeRelationship: (UUID) -> Void = { _ in }
    var onMissedDoseAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onRefillAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onSettingsRowTap: (SettingsRowState) -> Void = { _ in }
    var onSettingsToggle: (SettingsRowState, Bool) -> Void = { _, _ in }
    var onOpenPremium: () -> Void = {}
    @State private var selectedRelationship: CaregiverRelationshipRowState?

    var body: some View {
        NavigationStack {
            ZStack {
                CareTapScreenBackground()

                tabContent
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .animation(.smooth(duration: 0.25), value: selectedDestination)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CareTapBottomBar(selected: selectedDestination, onSelect: onDestinationSelected)
            }
            .navigationDestination(item: $selectedRelationship) { relationship in
                CaregiverPersonDetailView(
                    relationship: relationship,
                    medications: medicationRows,
                    historyRows: historyRows
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedDestination {
        case .home:
            if let homeState {
                CaregiverHomeView(
                    state: homeState,
                    notificationCount: notificationCount,
                    onQuickAction: onQuickAction,
                    onLinkedPersonSelected: onSelectCareProfile,
                    onDestinationSelected: onDestinationSelected,
                    onNotificationsTap: onNotificationsTap
                )
            } else {
                workspaceContent
            }
        case .workspace:
            workspaceContent
        case .settings:
            settingsContent
        }
    }

    private var workspaceContent: some View {
        CareTapTabScreenContainer(
            unreadNoticeCount: notificationCount,
            onNotificationsTap: onNotificationsTap
        ) {
            CaregiverWorkspaceView(
                selectedSection: selectedWorkspaceSection,
                relationships: relationshipRows,
                invitations: invitationRows,
                medicationRows: medicationRows,
                historyRows: historyRows,
                premiumStatus: premiumStatus,
                inviteCode: inviteCode,
                onSectionSelected: onWorkspaceSectionSelected,
                onInviteCodeChanged: onInviteCodeChanged,
                onAcceptInvite: onAcceptInvite,
                onDeclineInvite: onDeclineInvite,
                onSelectCareProfile: onSelectCareProfile,
                onOpenPersonDetail: { selectedRelationship = $0 },
                onRevokeInvitation: onRevokeInvitation,
                onRevokeRelationship: onRevokeRelationship,
                onMissedDoseAlertsChanged: onMissedDoseAlertsChanged,
                onRefillAlertsChanged: onRefillAlertsChanged,
                onOpenPremium: onOpenPremium
            )
        }
    }

    private var settingsContent: some View {
        CareTapTabScreenContainer(
            unreadNoticeCount: notificationCount,
            onNotificationsTap: onNotificationsTap
        ) {
            SettingsView(
                state: settingsState,
                showsBackButton: false,
                onRowTap: onSettingsRowTap,
                onToggle: onSettingsToggle
            )
        }
    }
}
