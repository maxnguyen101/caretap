import SwiftUI

struct CareTapRootView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        CareTapRootContainerView(store: environment.appStore)
            .task {
                await environment.appStore.start()
            }
    }
}

private struct CareTapRootContainerView: View {
    @ObservedObject var store: CareTapAppStore

    var body: some View {
        rootContent
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .top) {
                Group {
                    if let message = store.errorMessage {
                        CareTapNoticeBanner(
                            tone: .alert,
                            title: "Something needs attention",
                            message: message,
                            onDismiss: store.clearError
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else if let message = store.infoMessage {
                        CareTapNoticeBanner(
                            tone: .mist,
                            title: "TapCare",
                            message: message,
                            onDismiss: store.clearInfo
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.4, bounce: 0.15), value: store.errorMessage)
                .animation(.spring(duration: 0.4, bounce: 0.15), value: store.infoMessage)
            }
            .sheet(isPresented: Binding(
                get: { store.exportURL != nil },
                set: { if !$0 { store.clearExportURL() } }
            )) {
                if let exportURL = store.exportURL {
                    CareTapShareSheet(items: [exportURL])
                }
            }
            .sheet(isPresented: $store.isPresentingNotificationCenter) {
                CareTapNotificationCenterView(
                    notices: store.noticeInbox,
                    onClose: store.dismissNotificationCenter,
                    onClear: store.clearNotificationInbox
                )
            }
            .sheet(isPresented: $store.isPresentingProfileEditor) {
                CareTapProfileEditorView(
                    displayName: $store.editableDisplayName,
                    onCancel: store.dismissProfileEditor,
                    onSave: {
                        Task {
                            await store.saveProfileEditor()
                        }
                    }
                )
            }
            .sheet(isPresented: $store.isPresentingPremiumSheet) {
                CareTapPremiumView(
                    state: store.premiumViewState,
                    onClose: store.dismissPremiumPaywall,
                    onPurchase: { plan in
                        Task {
                            await store.purchasePremium(plan)
                        }
                    },
                    onRestore: {
                        Task {
                            await store.restorePremiumPurchases()
                        }
                    }
                )
            }
            .sheet(isPresented: $store.isPresentingTapKitShop) {
                TapKitShopView(
                    state: store.tapKitShopState,
                    onClose: store.dismissTapKitShop,
                    onSelectPack: store.selectTapKitPack,
                    onCheckout: store.startTapKitCheckout,
                    onContactSupport: {
                        if let url = store.tapKitShopState.supportURL {
                            UIApplication.shared.open(url)
                        }
                    },
                    onDismissConfirmation: store.dismissTapKitOrderConfirmation
                )
                .sheet(isPresented: Binding(
                    get: { store.tapKitCheckoutURL != nil },
                    set: { if !$0 { store.dismissTapKitCheckout() } }
                )) {
                    if let checkoutURL = store.tapKitCheckoutURL {
                        TapKitCheckoutSafariView(
                            url: checkoutURL,
                            onFinish: store.dismissTapKitCheckout
                        )
                        .ignoresSafeArea()
                    }
                }
            }
            .sheet(item: $store.tapConfirmation) { confirmation in
                CareTapTapConfirmationSheet(
                    state: confirmation,
                    onDismiss: store.dismissTapConfirmation,
                    onLogAnyway: {
                        Task { await store.logAnywayFromTapConfirmation() }
                    },
                    onLogOutsideWindow: {
                        Task { await store.logOutsideWindowFromTapConfirmation() }
                    },
                    onReviewHistory: store.reviewTapConfirmationHistory,
                    onSetupAutomation: {
                        store.markAutomationConfigured()
                        if let url = URL(string: "shortcuts://create-automation") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
            .alert(
                "Delete Your TapCare Account?",
                isPresented: Binding(
                    get: { store.isPresentingDeleteAccountConfirmation },
                    set: { if !$0 { store.dismissDeleteAccountConfirmation() } }
                )
            ) {
                Button("Delete My Account", role: .destructive) {
                    Task {
                        await store.confirmDeleteAccount()
                    }
                }
                Button("Keep Account", role: .cancel) {
                    store.dismissDeleteAccountConfirmation()
                }
            } message: {
                Text("This permanently removes your TapCare account, routine history, and all synced data. People linked to you will lose access. This cannot be undone.")
            }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
        switch store.route {
        case .launching:
            CareTapLaunchView(selectedRole: store.selectedRole)
        case .onboarding(.roleSelection):
            CareTapRoleSelectionView(
                selectedRole: store.selectedRole,
                authenticatedDisplayName: store.authenticatedDisplayName,
                isBusy: store.isBusy,
                onRoleSelected: store.selectRole,
                onContinueLocally: { role in
                    Task { await store.continueLocally(as: role) }
                },
                onSignedIn: { payload in
                    Task { await store.signIn(with: payload) }
                },
                onEmailSignUp: { email, password, name in
                    Task { await store.signUpWithEmail(email: email, password: password, displayName: name) }
                },
                onEmailSignIn: { email, password in
                    Task { await store.signInWithEmail(email: email, password: password) }
                },
                onSignInFailure: store.presentError
            )
        case .onboarding(.patientSetup(.item)):
            AddMedicationView(
                state: store.addMedicationState,
                onClose: store.returnToRoleSelection,
                onPrimaryAction: store.continueFromMedicationStep,
                onSecondaryAction: store.returnToRoleSelection,
                onCategorySelected: store.updateMedicationCategory,
                onQueryChange: store.updateMedicationQuery,
                onSuggestionSelected: store.selectMedicationSuggestion,
                onTimeSlotSelected: store.toggleTimeSlot
            )
        case .onboarding(.patientSetup(.routine)):
            PatientScheduleSetupView(
                state: store.scheduleSetupState,
                onBack: store.returnToMedicationStep,
                onContinue: {
                    Task {
                        await store.continueFromScheduleStep()
                    }
                },
                onDetailsChanged: store.updateScheduleDetails,
                onStartDateChanged: store.updateScheduleStartDate,
                onTimeChanged: { id, date in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                    store.updateExactTime(
                        id: id,
                        hour: components.hour ?? 8,
                        minute: components.minute ?? 0
                    )
                },
                onAddCustomTime: store.addCustomExactTime,
                onRemoveTime: store.removeExactTime,
                onPhotoDataSelected: store.attachBottlePhoto,
                onFrequencyChanged: store.updateScheduleFrequency,
                onIntervalHoursChanged: store.updateScheduleIntervalHours,
                onWeekdayToggled: store.toggleScheduleWeekday,
                onFoodPreferenceChanged: store.updateFoodPreference,
                onSupplyChanged: store.updateSupplySettings,
                onContainerKindChanged: store.updateContainerKind
            )
        case .onboarding(.patientSetup(.tapSetup)):
            NFCPairingView(
                state: store.nfcPairingState,
                onBack: store.handleNFCPairingBack,
                onOpenTapKitShop: store.presentTapKitShop,
                onSecondaryAction: {
                    Task {
                        await store.handleNFCPairingSecondaryAction()
                    }
                },
                onPrimaryAction: {
                    Task {
                        await store.handleNFCPairingPrimaryAction()
                    }
                }
            )
        case .onboarding(.caregiverWelcome):
            CaregiverWelcomeView(
                state: store.caregiverWelcomeState,
                inviteCode: store.inviteCode,
                onInviteCodeChanged: store.setInviteCode,
                onPrimaryAction: {
                    Task {
                        await store.acceptInviteCode()
                    }
                },
                onSecondaryAction: {
                    Task {
                        await store.handleCaregiverWelcomeSecondaryAction()
                    }
                }
            )
        case .patient:
            PatientAppShellView(
                selectedDestination: store.selectedDestination,
                selectedWorkspaceSection: store.selectedPatientWorkspaceSection,
                homeState: store.patientHomeState,
                notificationCount: store.unreadNoticeCount,
                medicationRows: store.patientMedicationRows,
                historyRows: store.patientHistoryRows,
                premiumStatus: store.premiumViewState.status,
                settingsState: store.settingsState,
                onDestinationSelected: store.selectDestination,
                onWorkspaceSectionSelected: store.selectPatientWorkspaceSection,
                onNotificationsTap: store.presentNotificationCenter,
                onPrimaryAction: {
                    Task {
                        await store.handlePatientPrimaryAction()
                    }
                },
                onSecondaryAction: { action in
                    Task {
                        await store.handlePatientSecondaryAction(action)
                    }
                },
                onUndoHistoryRow: { row in
                    Task {
                        await store.undoLatestDoseLog(for: row.id)
                    }
                },
                onSettingsRowTap: { row in
                    Task {
                        await store.handleSettingsRowTap(row)
                    }
                },
                onSettingsToggle: { row, value in
                    Task {
                        await store.handleSettingsToggle(row, value: value)
                    }
                },
                onAddMedication: store.startPatientAddMedicationFlow,
                onOpenPremium: store.presentPremiumPaywall
            )
        case .caregiver:
            CaregiverAppShellView(
                selectedDestination: store.selectedDestination,
                selectedWorkspaceSection: store.selectedCaregiverWorkspaceSection,
                homeState: store.caregiverHomeState,
                notificationCount: store.unreadNoticeCount,
                medicationRows: store.patientMedicationRows,
                historyRows: store.patientHistoryRows,
                premiumStatus: store.premiumViewState.status,
                relationshipRows: store.caregiverRelationshipRows,
                invitationRows: store.caregiverInvitationRows,
                inviteCode: store.inviteCode,
                settingsState: store.settingsState,
                onDestinationSelected: store.selectDestination,
                onWorkspaceSectionSelected: store.selectCaregiverWorkspaceSection,
                onNotificationsTap: store.presentNotificationCenter,
                onQuickAction: { action in Task { await store.handleCaregiverQuickAction(action) } },
                onSelectCareProfile: { profileID in
                    Task {
                        await store.selectCaregiverProfile(profileID)
                    }
                },
                onInviteCodeChanged: store.setInviteCode,
                onAcceptInvite: {
                    Task {
                        await store.acceptInviteCode()
                    }
                },
                onDeclineInvite: {
                    Task {
                        await store.declineInviteCode()
                    }
                },
                onRevokeInvitation: { invitationID in
                    Task {
                        await store.revokeInvitation(invitationID)
                    }
                },
                onRevokeRelationship: { relationshipID in
                    Task {
                        await store.revokeRelationship(relationshipID)
                    }
                },
                onMissedDoseAlertsChanged: { relationshipID, isEnabled in
                    Task {
                        await store.updateRelationshipAlerts(
                            relationshipID,
                            receivesMissedDoseAlerts: isEnabled,
                            receivesRefillAlerts: nil
                        )
                    }
                },
                onRefillAlertsChanged: { relationshipID, isEnabled in
                    Task {
                        await store.updateRelationshipAlerts(
                            relationshipID,
                            receivesMissedDoseAlerts: nil,
                            receivesRefillAlerts: isEnabled
                        )
                    }
                },
                onSettingsRowTap: { row in
                    Task {
                        await store.handleSettingsRowTap(row)
                    }
                },
                onSettingsToggle: { row, value in
                    Task {
                        await store.handleSettingsToggle(row, value: value)
                    }
                },
                onOpenPremium: store.presentPremiumPaywall
            )
        }
        }
        .animation(.smooth(duration: 0.35), value: store.route)
    }
}

private struct CareTapProfileEditorView: View {
    @Binding var displayName: String
    var onCancel: () -> Void = {}
    var onSave: () -> Void = {}

    var body: some View {
        NavigationStack {
            ZStack {
                CareTapTheme.canvas
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should TapCare call you?")
                            .font(CareTapTypography.title)
                            .foregroundStyle(CareTapTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("This shows on Home, in Settings, and anywhere the app feels personal.")
                            .font(CareTapTypography.callout)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TextField("Your name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .font(CareTapTypography.section)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(CareTapTheme.surface, in: RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                                .stroke(CareTapTheme.stroke.opacity(0.85), lineWidth: 1)
                        }

                    Spacer()
                }
                .padding(.horizontal, CareTapSpacing.screenPadding)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct CareTapNotificationCenterView: View {
    let notices: [CareTapNoticeItem]
    var onClose: () -> Void = {}
    var onClear: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if notices.isEmpty {
                        CareTapStateCard(
                            icon: "bell",
                            tone: .neutral,
                            title: "Nothing new",
                            message: "Updates about tag taps, reminders, and account actions will show up here."
                        )
                    } else {
                        ForEach(notices) { notice in
                            CareTapCard(style: .muted) {
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(noticeToneColor(notice.tone).opacity(0.18))
                                        .frame(width: 12, height: 12)
                                        .overlay {
                                            Circle()
                                                .fill(noticeToneColor(notice.tone))
                                                .frame(width: 6, height: 6)
                                        }
                                        .padding(.top, 5)

                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(notice.title)
                                                .font(CareTapTypography.bodyStrong)
                                                .foregroundStyle(CareTapTheme.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)

                                            if notice.isUnread {
                                                Text("New")
                                                    .font(CareTapTypography.micro.weight(.bold))
                                                    .foregroundStyle(CareTapTheme.alert)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(CareTapTheme.alert.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            }

                                            Spacer()
                                        }

                                        Text(notice.message)
                                            .font(CareTapTypography.callout)
                                            .foregroundStyle(CareTapTheme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(notice.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(CareTapTypography.footnote)
                                            .foregroundStyle(CareTapTheme.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(CareTapTheme.canvas)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: onClose)
                }

                if !notices.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", action: onClear)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func noticeToneColor(_ tone: CareTapTone) -> Color {
        tone == .sage ? CareTapTheme.sageStrong : tone.color
    }
}

private struct CareTapLaunchView: View {
    let selectedRole: CareTapRole?

    var body: some View {
        ZStack {
            CareTapScreenBackground()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                            .fill(CareTapTheme.surface.opacity(0.94))
                            .frame(width: 82, height: 82)

                        RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusLarge, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.45), lineWidth: 1)
                            .frame(width: 94, height: 94)

                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(CareTapTheme.sageStrong)
                    }

                    VStack(spacing: 6) {
                        Text("TapCare")
                            .font(CareTapTypography.title)
                            .foregroundStyle(CareTapTheme.textPrimary)

                        Text(statusMessage)
                            .font(CareTapTypography.callout)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    ProgressView()
                        .tint(CareTapTheme.sage)
                        .scaleEffect(0.95)

                    Text("Opening")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, CareTapSpacing.screenPadding)
                .padding(.bottom, 42)
            }
        }
    }

    private var statusMessage: String {
        switch selectedRole {
        case .patient:
            return "Getting your day ready."
        case .caregiver:
            return "Opening support view."
        case nil:
            return "Getting things ready."
        }
    }
}

private struct CareTapNoticeBanner: View {
    let tone: CareTapTone
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .careTapLiquidGlass(
            tint: accentColor.opacity(0.08),
            cornerRadius: CareTapSpacing.cornerRadiusCompact
        )
        .overlay {
            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.5), lineWidth: 1)
        }
    }

    private var accentColor: Color {
        tone.color
    }

    private var iconName: String {
        tone == .alert ? "exclamationmark.triangle.fill" : "info.circle.fill"
    }
}

#Preview {
    CareTapRootContainerView(store: CareTapAppStore(services: .preview))
}
