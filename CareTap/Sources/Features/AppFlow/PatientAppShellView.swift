import SwiftUI

struct PatientAppShellView: View {
    let selectedDestination: CareTapDestination
    let selectedWorkspaceSection: PatientWorkspaceSection
    let homeState: PatientHomeState
    let notificationCount: Int
    let medicationRows: [PatientMedicationRowState]
    let historyRows: [PatientHistoryRowState]
    let premiumStatus: CareTapPremiumStatusState
    let settingsState: SettingsViewState
    var onDestinationSelected: (CareTapDestination) -> Void = { _ in }
    var onWorkspaceSectionSelected: (PatientWorkspaceSection) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: (SecondaryActionState) -> Void = { _ in }
    var onUndoHistoryRow: (PatientHistoryRowState) -> Void = { _ in }
    var onSettingsRowTap: (SettingsRowState) -> Void = { _ in }
    var onSettingsToggle: (SettingsRowState, Bool) -> Void = { _, _ in }
    var onAddMedication: () -> Void = {}
    var onOpenPremium: () -> Void = {}
    @State private var selectedMedication: PatientMedicationRowState?

    var body: some View {
        NavigationStack {
            ZStack {
                CareTapScreenBackground()

                VStack(spacing: 0) {
                    tabContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.smooth(duration: 0.25), value: selectedDestination)

                    CareTapBottomBar(selected: selectedDestination, onSelect: onDestinationSelected)
                }
            }
            .navigationDestination(item: $selectedMedication) { medication in
                PatientMedicationDetailView(medication: medication)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedDestination {
        case .home:
            PatientHomeView(
                state: homeState,
                notificationCount: notificationCount,
                onPrimaryAction: onPrimaryAction,
                onSecondaryAction: onSecondaryAction,
                onDestinationSelected: onDestinationSelected,
                onNotificationsTap: onNotificationsTap
            )
        case .workspace:
            CareTapTabScreenContainer(
                unreadNoticeCount: notificationCount,
                onNotificationsTap: onNotificationsTap
            ) {
                PatientWorkspaceView(
                    selectedSection: selectedWorkspaceSection,
                    medications: medicationRows,
                    historyRows: historyRows,
                    premiumStatus: premiumStatus,
                    onSectionSelected: onWorkspaceSectionSelected,
                    onAddMedication: onAddMedication,
                    onOpenPremium: onOpenPremium,
                    onSelectMedication: { selectedMedication = $0 },
                    onUndoHistoryRow: onUndoHistoryRow
                )
            }
        case .settings:
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
}
