import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class CareTapAppStore: ObservableObject {
    private enum NFCPairingEntryContext {
        case onboarding
        case settings
    }

    @Published private(set) var route: CareTapRootRoute = .launching
    @Published private(set) var selectedRole: CareTapRole?
    @Published var addMedicationState: AddMedicationViewState = CareTapPhaseTwoPreviewScenarios.addMedicationDefault
    @Published var scheduleSetupState = ScheduleSetupViewState(
        stepText: "Step 2 of 3",
        title: "Daily Schedule",
        message: "Choose the exact times that should feel natural for this routine.",
        medicationName: "Item",
        category: .prescription,
        dosage: "",
        bottleLabel: "Main container",
        containerKind: .bottle,
        instructions: "",
        dosageTitle: "Dose",
        containerTitle: "Bottle label",
        notesTitle: "Instructions",
        timingHelperText: "Add or adjust the exact times you want to see on Home.",
        photoSectionTitle: "Container Photo",
        selectedTimes: [],
        startDate: .now,
        startDateText: Date.now.formatted(date: .abbreviated, time: .omitted),
        reminderSummary: "Reminders happen right when it is due.",
        hasBottlePhoto: false,
        photoCaption: "Optional container photo",
        primaryActionTitle: "Continue to Tap Setup",
        secondaryActionTitle: "Back",
        scheduleFrequency: .onceDaily,
        intervalHours: 8,
        selectedWeekdays: []
    )
    @Published var nfcPairingState: NFCPairingViewState = CareTapPhaseTwoPreviewScenarios.nfcReady
    @Published var completionState = SetupCompletionViewState(
        title: "TapCare is ready",
        message: "The first item is ready and future check-ins can happen from Home.",
        summaryItems: [],
        primaryActionTitle: "Open Home"
    )
    @Published var caregiverWelcomeState = CaregiverWelcomeViewState(
        title: "Connect someone",
        message: "Enter an invite code to follow confirmed check-ins, missed items, and refill risk.",
        inviteInstructions: "You can connect more than one person later.",
        primaryActionTitle: "Connect",
        secondaryActionTitle: "Not Now"
    )
    @Published var patientHomeState: PatientHomeState = CareTapPreviewScenarios.patientDueNow
    @Published var caregiverHomeState: CaregiverHomeState = CareTapPreviewScenarios.caregiverAttentionNeeded
    @Published var settingsState: SettingsViewState = CareTapPhaseTwoPreviewScenarios.settingsLoaded
    @Published var patientMedicationRows: [PatientMedicationRowState] = []
    @Published var patientHistoryRows: [PatientHistoryRowState] = []
    @Published var caregiverRelationshipRows: [CaregiverRelationshipRowState] = []
    @Published var caregiverInvitationRows: [CaregiverInvitationRowState] = []
    @Published var inviteCode: String = ""
    @Published var isBusy = false
    @Published var noticeInbox: [CareTapNoticeItem] = []
    @Published var isPresentingNotificationCenter = false
    @Published var errorMessage: String? {
        didSet {
            guard oldValue != errorMessage else { return }
            handleErrorBannerChange(previousValue: oldValue)
        }
    }
    @Published var infoMessage: String? {
        didSet {
            guard oldValue != infoMessage else { return }
            handleInfoBannerChange(previousValue: oldValue)
        }
    }
    @Published var exportURL: URL?
    @Published var isPresentingDeleteAccountConfirmation = false
    @Published var isPresentingProfileEditor = false
    @Published var isPresentingPremiumSheet = false
    @Published var isPresentingTapKitShop = false
    @Published var tapKitCheckoutURL: URL?
    @Published private(set) var tapKitSelectedPackSlug: TapKitPack.Slug = TapKitPack.recommendedSlug
    @Published private(set) var tapKitOrderConfirmation: TapKitOrderConfirmationState?
    @Published var tapConfirmation: NFCTapConfirmationState?
    @Published private(set) var premiumViewState = CareTapPremiumViewState.from(
        snapshot: .loading,
        isPurchasing: false
    )
    @Published var editableDisplayName = ""

    private let services: CareTapServiceContainer
    private let statePersistence: CareTapAppStatePersisting
    private var hasStarted = false
    private var persistedState: CareTapPersistedAppState
    private var currentUser: User?
    private var activeCareProfile: CareProfile?
    private var medications: [Medication] = []
    private var occurrences: [DoseOccurrence] = []
    private var doseLogsByOccurrenceID: [UUID: [DoseLog]] = [:]
    private var relationships: [CareRelationship] = []
    private var pendingDoubleTapMedicationID: UUID?
    private var pendingEarlyOccurrenceID: UUID?
    private var pendingOffScheduleMedicationID: UUID?
    private var invitations: [Invitation] = []
    private var refillStatesByMedicationID: [UUID: RefillState] = [:]
    private var rulesByMedicationID: [UUID: [ScheduleRule]] = [:]
    private var linkedCareProfiles: [CareProfile] = []
    private var activeProfileRelationships: [CareRelationship] = []
    private var settingsNotificationAuthorized = false
    private var nfcPairingEntryContext: NFCPairingEntryContext = .onboarding
    private var nfcPairingMedicationID: UUID?
    private var pendingIncomingURL: URL?
    private var infoBannerDismissTask: Task<Void, Never>?
    private var errorBannerDismissTask: Task<Void, Never>?
    private let bundledCatalog = CareTapBundledMedicationCatalog()
    private var premiumSnapshot: CareTapPremiumSnapshot = .loading

    var selectedDestination: CareTapDestination {
        persistedState.selectedDestination
    }

    var selectedPatientWorkspaceSection: PatientWorkspaceSection {
        persistedState.patientWorkspaceSection
    }

    var selectedCaregiverWorkspaceSection: CaregiverWorkspaceSection {
        persistedState.caregiverWorkspaceSection
    }

    var authenticatedDisplayName: String? {
        currentUser?.displayName
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var unreadNoticeCount: Int {
        noticeInbox.filter(\.isUnread).count
    }

    var tapKitCheckoutConfiguration: TapKitCheckoutConfiguration {
        TapKitCheckoutConfiguration()
    }

    var tapKitShopState: TapKitShopViewState {
        TapKitShopViewState.default(
            isCheckoutConfigured: tapKitCheckoutConfiguration.isConfigured,
            selectedPackSlug: tapKitSelectedPackSlug,
            confirmation: tapKitOrderConfirmation
        )
    }

    init(
        services: CareTapServiceContainer,
        statePersistence: CareTapAppStatePersisting = CareTapAppStateStore()
    ) {
        self.services = services
        self.statePersistence = statePersistence
        persistedState = statePersistence.load()
        selectedRole = persistedState.selectedRole
        rebuildOnboardingStates()
    }

    func start() async {
        guard !hasStarted else {
            await processPendingIncomingURLIfNeeded()
            return
        }

        hasStarted = true
        refreshPremiumStateInBackground()
        Task { @MainActor in
            settingsNotificationAuthorized = await notificationAuthorizationGranted()
        }

        let snapshot = await services.auth.sessionSnapshot()
        currentUser = snapshot.user

        if let user = snapshot.user {
            persistedState.localUserID = nil
            persistedState.selectedRole = persistedState.selectedRole ?? user.preferredRole
            selectedRole = persistedState.selectedRole
            persist()
            await routeAuthenticatedUser(user)
        } else if let user = await restoreLocalUser() {
            currentUser = user
            persistedState.selectedRole = persistedState.selectedRole ?? user.preferredRole
            persistedState.localUserID = user.id
            selectedRole = persistedState.selectedRole
            persist()
            await routeAuthenticatedUser(user)
        } else {
            route = .onboarding(.roleSelection)
        }

        await processPendingIncomingURLIfNeeded()
    }

    func selectRole(_ role: CareTapRole) {
        selectedRole = role
        persistedState.selectedRole = role
        persist()

        if let currentUser {
            Task {
                await routeAuthenticatedUser(currentUser)
            }
        } else {
            route = .onboarding(.roleSelection)
        }
    }

    func continueLocally(as role: CareTapRole) async {
        selectedRole = role
        persistedState.selectedRole = role
        isBusy = true
        defer { isBusy = false }

        do {
            let user = try await ensureLocalUser(preferredRole: role)
            currentUser = user
            persistedState.localUserID = user.id
            persistedState.selectedRole = role
            persist()
            infoMessage = "TapCare is ready on this iPhone. You can add sync later from Settings."
            await routeAuthenticatedUser(user)
            await processPendingIncomingURLIfNeeded()
        } catch {
            errorMessage = "TapCare couldn’t create the local profile on this iPhone yet."
        }
    }

    func signIn(with payload: AppleIdentityTokenPayload) async {
        guard let selectedRole else {
            errorMessage = "Choose how you want to use CareTap first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let snapshot = try await services.auth.signInWithApple(with: payload, preferredRole: selectedRole)
            guard let user = snapshot.user else {
                throw CareTapServiceError.authenticationFailed
            }

            currentUser = user
            persistedState.localUserID = nil
            persistedState.selectedRole = selectedRole
            persist()
            await routeAuthenticatedUser(user)
            await processPendingIncomingURLIfNeeded()
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "CareTap couldn’t finish Sign in with Apple yet. Check the Apple provider configuration in Supabase and try again."
            }
        }
    }

    func signUpWithEmail(email: String, password: String, displayName: String?) async {
        guard let selectedRole else {
            errorMessage = "Choose how you want to use CareTap first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let credential = EmailPasswordCredential(email: email, password: password, displayName: displayName)
            let snapshot = try await services.auth.signUpWithEmail(credential, preferredRole: selectedRole)
            guard let user = snapshot.user else {
                throw CareTapServiceError.authenticationFailed
            }

            currentUser = user
            persistedState.localUserID = nil
            persistedState.selectedRole = selectedRole
            persist()
            await routeAuthenticatedUser(user)
            await processPendingIncomingURLIfNeeded()
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "Couldn’t create the account. The email may already be in use, or the password is too short."
            }
        }
    }

    func signInWithEmail(email: String, password: String) async {
        guard let selectedRole else {
            errorMessage = "Choose how you want to use CareTap first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let credential = EmailPasswordCredential(email: email, password: password, displayName: nil)
            let snapshot = try await services.auth.signInWithEmail(credential, preferredRole: selectedRole)
            guard let user = snapshot.user else {
                throw CareTapServiceError.authenticationFailed
            }

            currentUser = user
            persistedState.localUserID = nil
            persistedState.selectedRole = selectedRole
            persist()
            await routeAuthenticatedUser(user)
            await processPendingIncomingURLIfNeeded()
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "Couldn’t sign in. Check your email and password and try again."
            }
        }
    }

    func signOut() async {
        isBusy = true
        await services.auth.signOut()
        isBusy = false

        await resetSessionState(infoBanner: nil)
    }

    func dismissDeleteAccountConfirmation() {
        isPresentingDeleteAccountConfirmation = false
    }

    func confirmDeleteAccount() async {
        dismissDeleteAccountConfirmation()

        guard let currentUser else {
            errorMessage = "No signed-in account to delete."
            return
        }

        if currentUser.authUserID == nil || currentUser.syncState == .localOnly {
            await resetSessionState(infoBanner: "Your local TapCare profile was removed from this iPhone.")
            return
        }

        isBusy = true
        infoMessage = "Removing your account…"

        do {
            try await services.auth.deleteAccount()
            isBusy = false
            await resetSessionState(infoBanner: "Your TapCare account and local data were removed from this iPhone.")
        } catch {
            isBusy = false
            infoMessage = nil
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "CareTap couldn’t delete the account right now. Check your connection and try again from Settings."
            }
        }
    }

    func handleIncomingURL(_ url: URL) async {
        guard hasStarted, route != .launching else {
            pendingIncomingURL = url
            return
        }

        await processIncomingURL(url)
    }

    func selectDestination(_ destination: CareTapDestination) {
        persistedState.selectedDestination = destination
        persist()

        if route == .patient {
            patientHomeState = CareTapStateBuilder.patientHomeState(
                user: currentUser ?? CareTapPhaseThreePreviewScenarios.user,
                careProfile: activeCareProfile ?? CareTapPhaseThreePreviewScenarios.careProfile,
                relationships: relationships,
                medications: medications,
                occurrences: occurrences,
                destination: destination
            )
        } else if route == .caregiver {
            caregiverHomeState = CareTapStateBuilder.caregiverHomeState(
                caregiver: currentUser ?? CareTapPhaseThreePreviewScenarios.user,
                lovedOne: activeCareProfile ?? CareTapPhaseThreePreviewScenarios.careProfile,
                linkedProfiles: linkedCareProfiles,
                activeProfileRelationships: activeProfileRelationships,
                medications: medications,
                occurrences: occurrences,
                refillStates: Array(refillStatesByMedicationID.values),
                destination: destination
            )
        }
    }

    func selectPatientWorkspaceSection(_ section: PatientWorkspaceSection) {
        persistedState.patientWorkspaceSection = section
        selectDestination(.workspace)
    }

    func selectCaregiverWorkspaceSection(_ section: CaregiverWorkspaceSection) {
        persistedState.caregiverWorkspaceSection = section
        selectDestination(.workspace)
    }

    func selectCaregiverProfile(_ profileID: UUID) async {
        guard route == .caregiver else {
            return
        }

        guard activeCareProfile?.id != profileID else {
            if selectedDestination != .home {
                selectDestination(.home)
            }
            return
        }

        do {
            guard let profile = try await services.recordStore.fetchCareProfile(id: profileID) else {
                infoMessage = "That linked person is no longer available on this device."
                return
            }

            activeCareProfile = profile
            persistedState.activeCareProfileID = profile.id
            persistedState.selectedDestination = .home
            persist()
            try await refreshCaregiverExperience()
            route = .caregiver
        } catch {
            errorMessage = "CareTap couldn’t switch to that person yet."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func clearInfo() {
        infoMessage = nil
    }

    func presentNotificationCenter() {
        markAllNoticesRead()
        isPresentingNotificationCenter = true
    }

    func dismissNotificationCenter() {
        isPresentingNotificationCenter = false
    }

    func clearNotificationInbox() {
        noticeInbox.removeAll()
    }

    func clearExportURL() {
        exportURL = nil
    }

    func dismissProfileEditor() {
        isPresentingProfileEditor = false
    }

    func presentPremiumPaywall() {
        CareTapInteraction.dismissKeyboard()
        isPresentingPremiumSheet = true
    }

    func dismissPremiumPaywall() {
        isPresentingPremiumSheet = false
    }

    func presentTapKitShop() {
        CareTapInteraction.dismissKeyboard()
        isPresentingTapKitShop = true
    }

    func dismissTapKitShop() {
        isPresentingTapKitShop = false
        tapKitCheckoutURL = nil
    }

    func selectTapKitPack(_ slug: TapKitPack.Slug) {
        guard tapKitSelectedPackSlug != slug else { return }
        tapKitSelectedPackSlug = slug
        CareTapHaptics.selection()
    }

    /// Builds the Stripe Checkout URL for the currently selected pack and exposes it
    /// to the shop view, which renders an in-app `SFSafariViewController`. If no
    /// Stripe Payment Link is configured, surfaces an info banner instead.
    func startTapKitCheckout() {
        let configuration = tapKitCheckoutConfiguration
        let pack = TapKitPack.pack(for: tapKitSelectedPackSlug)
        guard let url = configuration.paymentLink(for: pack) else {
            infoMessage = "TapKit checkout is being connected to Stripe — try again shortly."
            return
        }
        tapKitOrderConfirmation = nil
        tapKitCheckoutURL = url
    }

    /// Called by the SFSafariViewController wrapper when the user manually closes
    /// the checkout sheet without finishing.
    func dismissTapKitCheckout() {
        tapKitCheckoutURL = nil
    }

    /// Called from `processIncomingURL` when Stripe redirects back to the app.
    func handleTapKitOrderResult(success: Bool, packSlug: String?) {
        tapKitCheckoutURL = nil
        guard success else {
            infoMessage = "TapKit order canceled — your selection is still saved."
            return
        }

        let resolvedSlug = packSlug
            .flatMap(TapKitPack.Slug.init(rawValue:))
            ?? tapKitSelectedPackSlug
        let pack = TapKitPack.pack(for: resolvedSlug)
        tapKitOrderConfirmation = TapKitOrderConfirmationState(
            pack: pack,
            confirmedAt: .now
        )
        isPresentingTapKitShop = true
        CareTapHaptics.success()
    }

    func dismissTapKitOrderConfirmation() {
        tapKitOrderConfirmation = nil
    }

    /// Remember that the user walked through setting up the Shortcuts
    /// automation so the tap confirmation sheet can stop showing the hint.
    func markAutomationConfigured() {
        guard !persistedState.hasConfirmedNFCAutomation else { return }
        persistedState.hasConfirmedNFCAutomation = true
        persist()
    }

    func presentError(_ message: String) {
        errorMessage = message
    }

    func presentProfileEditor() {
        CareTapInteraction.dismissKeyboard()
        editableDisplayName = currentDisplayName
        isPresentingProfileEditor = true
    }

    func saveProfileEditor() async {
        guard let currentUser else { return }

        let trimmedName = editableDisplayName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a name to keep going."
            return
        }

        do {
            let updatedUser = User(
                id: currentUser.id,
                authUserID: currentUser.authUserID,
                appleSubject: currentUser.appleSubject,
                preferredRole: currentUser.preferredRole,
                displayName: trimmedName,
                initials: Self.initials(from: trimmedName),
                timezoneIdentifier: currentUser.timezoneIdentifier,
                localeIdentifier: currentUser.localeIdentifier,
                isSignInWithAppleLinked: currentUser.isSignInWithAppleLinked,
                createdAt: currentUser.createdAt,
                updatedAt: .now,
                lastActiveAt: .now,
                syncState: .pendingUpload
            )
            self.currentUser = try await services.recordStore.upsertUser(updatedUser)

            if let activeCareProfile,
               selectedRole == .patient,
               activeCareProfile.createdByUserID == currentUser.id {
                let updatedProfile = CareProfile(
                    id: activeCareProfile.id,
                    createdByUserID: activeCareProfile.createdByUserID,
                    patientUserID: activeCareProfile.patientUserID,
                    displayName: trimmedName,
                    preferredName: Self.preferredName(from: trimmedName),
                    initials: Self.initials(from: trimmedName),
                    avatarStyle: activeCareProfile.avatarStyle,
                    timezoneIdentifier: activeCareProfile.timezoneIdentifier,
                    notes: activeCareProfile.notes,
                    createdAt: activeCareProfile.createdAt,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
                self.activeCareProfile = try await services.recordStore.upsertCareProfile(updatedProfile)
            }

            isPresentingProfileEditor = false
            infoMessage = "Name updated."
            try await refreshRoleExperience()
        } catch {
            errorMessage = "CareTap couldn’t save that name yet."
        }
    }

    func purchasePremium(_ plan: CareTapPremiumPlan) async {
        setPremiumPurchasing(true)
        defer { setPremiumPurchasing(false) }

        do {
            let outcome = try await services.premiumSubscriptions.purchase(plan: plan)
            applyPremiumSnapshot(outcome.snapshot)
            await refreshPremiumDependentState()

            switch outcome {
            case .purchased:
                isPresentingPremiumSheet = false
                infoMessage = "TapCare Premium is active."
            case .pending:
                infoMessage = "The App Store is still confirming that purchase."
            case .cancelled:
                break
            }
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "CareTap couldn’t start Premium right now."
            }
        }
    }

    func restorePremiumPurchases() async {
        setPremiumPurchasing(true)
        defer { setPremiumPurchasing(false) }

        do {
            let snapshot = try await services.premiumSubscriptions.restorePurchases()
            applyPremiumSnapshot(snapshot)
            await refreshPremiumDependentState()
            infoMessage = snapshot.isPremiumActive
                ? "Your TapCare Premium access was restored."
                : "No active TapCare Premium subscription was found on this Apple Account."
        } catch {
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription,
               !description.isEmpty {
                errorMessage = description
            } else {
                errorMessage = "CareTap couldn’t restore purchases right now."
            }
        }
    }

    func setInviteCode(_ value: String) {
        inviteCode = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    func returnToRoleSelection() {
        selectedRole = nil
        persistedState.selectedRole = nil
        persist()
        route = .onboarding(.roleSelection)
    }

    func startPatientAddMedicationFlow() {
        guard currentUser != nil else {
            route = .onboarding(.roleSelection)
            return
        }

        persistedState.patientSetupStep = .item
        persist()
        rebuildOnboardingStates()
        route = .onboarding(.patientSetup(.item))
    }

    func reviewSetupDetails() {
        persistedState.patientSetupStep = .routine
        persist()
        rebuildOnboardingStates()
        route = .onboarding(.patientSetup(.routine))
    }

    private func routeAuthenticatedUser(_ user: User) async {
        switch selectedRole ?? user.preferredRole {
        case .patient:
            await routePatient(user)
        case .caregiver:
            await routeCaregiver(user)
        }
    }

    private func routePatient(_ user: User) async {
        do {
            let profiles = try await services.recordStore.careProfiles(createdBy: user.id)
            let profile = profiles.first(where: { $0.id == persistedState.activeCareProfileID })
                ?? profiles.first(where: { $0.patientUserID == user.id })
                ?? profiles.first

            activeCareProfile = profile
            if persistedState.hasCompletedPatientSetup, profile != nil {
                try await refreshPatientExperience()
                route = .patient
            } else {
                route = .onboarding(.patientSetup(persistedState.patientSetupStep))
                rebuildOnboardingStates()
            }
        } catch {
            errorMessage = "CareTap couldn’t load the patient setup state from local storage."
            route = .onboarding(.patientSetup(persistedState.patientSetupStep))
        }
    }

    private func routeCaregiver(_ user: User) async {
        do {
            let caregiverRelationships = try await services.recordStore.relationships(for: user.id)
            relationships = caregiverRelationships

            if let activeProfileID = persistedState.activeCareProfileID,
               let profile = try await services.recordStore.fetchCareProfile(id: activeProfileID) {
                activeCareProfile = profile
            } else if let firstRelationship = caregiverRelationships.first,
                      let profile = try await services.recordStore.fetchCareProfile(id: firstRelationship.careProfileID) {
                activeCareProfile = profile
                persistedState.activeCareProfileID = profile.id
            } else {
                activeCareProfile = nil
            }

            if persistedState.hasCompletedCaregiverSetup {
                try await refreshCaregiverExperience()
                route = .caregiver
            } else {
                route = .onboarding(.caregiverWelcome)
                rebuildOnboardingStates()
            }
        } catch {
            errorMessage = "CareTap couldn’t load caregiver sharing yet. You can still continue with the invite flow."
            route = .onboarding(.caregiverWelcome)
        }
    }

    private func restoreLocalUser() async -> User? {
        do {
            if let localUserID = persistedState.localUserID,
               let user = try await services.recordStore.fetchUser(id: localUserID),
               user.authUserID == nil || user.syncState == .localOnly {
                return user
            }

            if let activeProfileID = persistedState.activeCareProfileID,
               let profile = try await services.recordStore.fetchCareProfile(id: activeProfileID),
               let user = try await services.recordStore.fetchUser(id: profile.createdByUserID),
               user.authUserID == nil || user.syncState == .localOnly {
                persistedState.localUserID = user.id
                return user
            }
        } catch {
            return nil
        }

        return nil
    }

    private func ensureLocalUser(preferredRole role: CareTapRole) async throws -> User {
        if let restoredUser = await restoreLocalUser() {
            guard restoredUser.preferredRole != role else {
                return restoredUser
            }

            return try await services.recordStore.upsertUser(
                User(
                    id: restoredUser.id,
                    authUserID: restoredUser.authUserID,
                    appleSubject: restoredUser.appleSubject,
                    preferredRole: role,
                    displayName: restoredUser.displayName,
                    initials: restoredUser.initials,
                    timezoneIdentifier: restoredUser.timezoneIdentifier,
                    localeIdentifier: restoredUser.localeIdentifier,
                    isSignInWithAppleLinked: restoredUser.isSignInWithAppleLinked,
                    createdAt: restoredUser.createdAt,
                    updatedAt: .now,
                    lastActiveAt: .now,
                    syncState: .localOnly
                )
            )
        }

        let displayName = role == .patient ? "Me" : "Caregiver"
        return try await services.recordStore.upsertUser(
            User(
                id: UUID(),
                authUserID: nil,
                appleSubject: nil,
                preferredRole: role,
                displayName: displayName,
                initials: Self.initials(from: displayName),
                timezoneIdentifier: TimeZone.current.identifier,
                localeIdentifier: Locale.current.identifier,
                isSignInWithAppleLinked: false,
                createdAt: .now,
                updatedAt: .now,
                lastActiveAt: .now,
                syncState: .localOnly
            )
        )
    }

    private func persist() {
        statePersistence.save(persistedState)
    }

    private func resetSessionState(infoBanner: String?) async {
        currentUser = nil
        activeCareProfile = nil
        medications = []
        occurrences = []
        doseLogsByOccurrenceID = [:]
        relationships = []
        invitations = []
        refillStatesByMedicationID = [:]
        rulesByMedicationID = [:]
        linkedCareProfiles = []
        activeProfileRelationships = []
        exportURL = nil
        pendingIncomingURL = nil
        isPresentingPremiumSheet = false
        isPresentingTapKitShop = false
        persistedState = .default()
        selectedRole = nil
        statePersistence.clear()
        await services.liveActivities.endAllActivities()
        route = .onboarding(.roleSelection)
        rebuildOnboardingStates()
        infoMessage = infoBanner
    }

    private func rebuildOnboardingStates() {
        let draft = persistedState.patientSetupDraft
        let lookupState = lookupState(for: draft.searchQuery)
        let category = draft.medicationCategory
        let itemTerm = category == .prescription ? "medication" : "item"
        let timeSlots = ["Morning", "Noon", "Evening", "Night"].map { title -> MedicationTimeSlotState in
            MedicationTimeSlotState(
                title: title,
                timeText: defaultTime(for: title).formatted(date: .omitted, time: .shortened),
                symbolName: symbolName(for: title),
                isSelected: draft.selectedTimeTitles.contains(title)
            )
        }

        addMedicationState = AddMedicationViewState(
            stepText: "Step 1 of 3",
            title: "Choose the item",
            message: "Start with what you already call it, then pick the usual part of the day.",
            selectedCategory: category,
            searchPlaceholder: "Medication, vitamin, creatine, protein powder…",
            searchQuery: draft.searchQuery,
            lookupState: lookupState,
            timeSlots: timeSlots,
            infoTitle: "Keep this first step light",
            infoMessage: "Exact times, container details, reminders, and an optional image all come next.",
            primaryActionTitle: "Continue to Routine",
            secondaryActionTitle: "Cancel"
        )

        scheduleSetupState = ScheduleSetupViewState(
            stepText: "Step 2 of 3",
            title: scheduleTitle(for: category),
            message: scheduleMessage(for: category, containerKind: draft.containerKind),
            medicationName: draft.medicationName.isEmpty ? itemTerm.capitalized : draft.medicationName,
            category: category,
            dosage: draft.dosage,
            bottleLabel: draft.bottleLabel,
            containerKind: draft.containerKind,
            instructions: draft.instructions,
            dosageTitle: dosageFieldTitle(for: category),
            containerTitle: containerFieldTitle(for: draft.containerKind),
            notesTitle: notesFieldTitle(for: category),
            timingHelperText: timingHelperText(for: category),
            photoSectionTitle: photoSectionTitle(for: draft.containerKind),
            selectedTimes: draft.exactTimes.map {
                ScheduleSetupTimeState(
                    id: $0.id,
                    title: $0.title,
                    symbolName: $0.symbolName,
                    hour: $0.hour,
                    minute: $0.minute,
                    displayTime: timeString(hour: $0.hour, minute: $0.minute)
                )
            },
            startDate: draft.startsOn,
            startDateText: draft.startsOn.formatted(date: .abbreviated, time: .omitted),
            reminderSummary: draft.reminderLeadTimeMinutes == 0
                ? "CareTap will remind right when it is due."
                : "CareTap will remind \(draft.reminderLeadTimeMinutes) minutes early.",
            hasBottlePhoto: draft.bottlePhotoLocalPath != nil,
            photoCaption: draft.bottlePhotoLocalPath == nil
                ? "Optional, but helpful if containers look similar or someone else helps manage them."
                : "Container photo saved on this device and ready for Home.",
            primaryActionTitle: "Continue to Tap Setup",
            secondaryActionTitle: "Back",
            scheduleFrequency: draft.scheduleFrequency,
            intervalHours: draft.intervalHours,
            selectedWeekdays: draft.selectedWeekdays,
            takeWithFood: draft.takeWithFood,
            supplyCount: draft.supplyCount,
            lowSupplyThreshold: draft.lowSupplyThreshold
        )

        let nfcMedication = nfcPairingTargetMedication() ?? medications.last
        let nfcMedicationName = nfcMedication?.displayTitle ?? (draft.medicationName.isEmpty ? "Item" : "\(draft.medicationName) \(draft.dosage)")
        let nfcBottleLabel = nfcMedication?.bottleLabel ?? draft.bottleLabel
        nfcPairingState = NFCPairingViewState(
            stepText: "Step 3 of 3",
            title: "Tap setup",
            message: "Pair a tag if you want tap-to-log, or keep going with manual check-ins.",
            medicationName: nfcMedicationName,
            bottleLabel: nfcBottleLabel,
            phase: nfcPairingState.phase,
            helperTitle: "",
            helperMessage: "",
            helpItems: [],
            footerNote: ""
        )

        completionState = SetupCompletionViewState(
            title: "TapCare is ready",
            message: "Setup is complete. From Home, you can tap the container when it is due and still use manual fallback anytime.",
            summaryItems: [
                draft.medicationName.isEmpty ? "You can add more items later" : "\(draft.medicationName) is ready",
                draft.bottlePhotoLocalPath == nil ? "A container photo can be added later" : "Container photo saved on device",
                nfcPairingState.phase == .success ? "Tag pairing is active" : "Manual check-in stays available"
            ],
            primaryActionTitle: "Open Home"
        )
    }

    private func lookupState(for query: String) -> MedicationLookupState {
        if query.isEmpty {
            return .suggestions(bundledCatalog.allSuggestions())
        }

        let matches = bundledCatalog.suggestions(matching: query)
        return matches.isEmpty ? .empty(query: query) : .suggestions(matches)
    }

    private func defaultTime(for title: String) -> Date {
        let components: DateComponents
        switch title {
        case "Noon":
            components = DateComponents(hour: 12, minute: 30)
        case "Evening":
            components = DateComponents(hour: 18, minute: 0)
        case "Night":
            components = DateComponents(hour: 21, minute: 0)
        default:
            components = DateComponents(hour: 8, minute: 0)
        }

        return Calendar.current.date(from: components) ?? .now
    }

    private func symbolName(for title: String) -> String {
        switch title {
        case "Noon":
            return "sun.max"
        case "Evening":
            return "sun.haze.fill"
        case "Night":
            return "moon.fill"
        default:
            return "sun.max.fill"
        }
    }

    private func timeString(hour: Int, minute: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func notificationAuthorizationGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

}

extension CareTapAppStore {
    func updateMedicationQuery(_ query: String) {
        persistedState.patientSetupDraft.searchQuery = query
        persistedState.patientSetupDraft.selectedSuggestionID = nil
        persistedState.patientSetupDraft.medicationName = query
        persistedState.patientSetupDraft.medicationCategory = inferredCategory(from: query, fallback: persistedState.patientSetupDraft.medicationCategory)
        persist()
        let draft = persistedState.patientSetupDraft
        addMedicationState = AddMedicationViewState(
            stepText: "Step 1 of 3",
            title: "Choose the item",
            message: "Use the label you already recognize. You can refine the routine details in the next step.",
            selectedCategory: draft.medicationCategory,
            searchPlaceholder: "Medication, vitamin, creatine, protein powder…",
            searchQuery: draft.searchQuery,
            lookupState: lookupState(for: draft.searchQuery),
            timeSlots: addMedicationState.timeSlots,
            infoTitle: "More details come next",
            infoMessage: "You’ll choose exact times, container details, reminders, and an optional image next.",
            primaryActionTitle: "Continue to Routine",
            secondaryActionTitle: "Cancel"
        )
    }

    func selectMedicationSuggestion(_ suggestion: MedicationSuggestionState) {
        persistedState.patientSetupDraft.searchQuery = suggestion.title
        persistedState.patientSetupDraft.medicationName = suggestion.title
        persistedState.patientSetupDraft.selectedSuggestionID = suggestion.id
        persistedState.patientSetupDraft.medicationCategory = suggestion.category
        persistedState.patientSetupDraft.containerKind = suggestion.defaultContainerKind
        persistedState.patientSetupDraft.bottleLabel = defaultContainerLabel(for: suggestion.defaultContainerKind)
        if let defaultDosage = suggestion.defaultDosage,
           persistedState.patientSetupDraft.dosage.isEmpty {
            persistedState.patientSetupDraft.dosage = defaultDosage
        }
        if let defaultLeadTime = suggestion.defaultReminderLeadTimeMinutes,
           persistedState.patientSetupDraft.reminderLeadTimeMinutes == 0 {
            persistedState.patientSetupDraft.reminderLeadTimeMinutes = defaultLeadTime
        }
        if !suggestion.defaultTimeTitles.isEmpty {
            persistedState.patientSetupDraft.selectedTimeTitles = suggestion.defaultTimeTitles
            persistedState.patientSetupDraft.exactTimes = suggestion.defaultTimeTitles.map { title in
                CareTapExactDoseTime(
                    title: title,
                    symbolName: symbolName(for: title),
                    hour: Calendar.current.component(.hour, from: defaultTime(for: title)),
                    minute: Calendar.current.component(.minute, from: defaultTime(for: title))
                )
            }
        }
        persist()
        rebuildOnboardingStates()
    }

    func updateMedicationCategory(_ category: MedicationCategory) {
        persistedState.patientSetupDraft.medicationCategory = category

        if persistedState.patientSetupDraft.dosage.isEmpty {
            switch category {
            case .prescription, .otc:
                persistedState.patientSetupDraft.dosage = "1 dose"
            case .supplement:
                persistedState.patientSetupDraft.dosage = "1 serving"
            }
        }

        persist()
        rebuildOnboardingStates()
    }

    func updateContainerKind(_ containerKind: ContainerKind) {
        let previousContainerKind = persistedState.patientSetupDraft.containerKind
        persistedState.patientSetupDraft.containerKind = containerKind
        if persistedState.patientSetupDraft.bottleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || persistedState.patientSetupDraft.bottleLabel == defaultContainerLabel(for: previousContainerKind) {
            persistedState.patientSetupDraft.bottleLabel = defaultContainerLabel(for: containerKind)
        }
        persist()
        rebuildOnboardingStates()
    }

    func toggleTimeSlot(_ slot: MedicationTimeSlotState) {
        var titles = persistedState.patientSetupDraft.selectedTimeTitles
        let existingTimes = persistedState.patientSetupDraft.exactTimes
        if let index = titles.firstIndex(of: slot.title) {
            if titles.count > 1 {
                titles.remove(at: index)
            }
        } else {
            titles.append(slot.title)
        }

        persistedState.patientSetupDraft.selectedTimeTitles = titles.sorted(by: slotOrder)
        let customTimes = existingTimes.filter { !defaultSlotTitles.contains($0.title) }
        let presetTimes = persistedState.patientSetupDraft.selectedTimeTitles.map { title in
            existingTimes.first(where: { $0.title == title }) ?? CareTapExactDoseTime(
                title: title,
                symbolName: symbolName(for: title),
                hour: Calendar.current.component(.hour, from: defaultTime(for: title)),
                minute: Calendar.current.component(.minute, from: defaultTime(for: title))
            )
        }
        persistedState.patientSetupDraft.exactTimes = (presetTimes + customTimes)
            .sorted(by: exactTimeOrder(lhs:rhs:))
        persist()
        rebuildOnboardingStates()
    }

    func updateScheduleDetails(
        dosage: String,
        bottleLabel: String,
        instructions: String,
        reminderLeadTimeMinutes: Int
    ) {
        persistedState.patientSetupDraft.dosage = dosage
        persistedState.patientSetupDraft.bottleLabel = bottleLabel
        persistedState.patientSetupDraft.instructions = instructions
        persistedState.patientSetupDraft.reminderLeadTimeMinutes = reminderLeadTimeMinutes
        persist()
        rebuildOnboardingStates()
    }

    func updateScheduleStartDate(_ date: Date) {
        persistedState.patientSetupDraft.startsOn = date
        persist()
        rebuildOnboardingStates()
    }

    func updateScheduleFrequency(_ frequency: ScheduleFrequency) {
        persistedState.patientSetupDraft.scheduleFrequency = frequency
        if frequency == .specificWeekdays,
           persistedState.patientSetupDraft.selectedWeekdays.isEmpty {
            persistedState.patientSetupDraft.selectedWeekdays = [defaultSelectedWeekday(for: persistedState.patientSetupDraft.startsOn)]
        }
        persist()
        rebuildOnboardingStates()
    }

    func updateScheduleIntervalHours(_ hours: Int) {
        persistedState.patientSetupDraft.intervalHours = min(max(hours, 1), 24)
        persist()
        rebuildOnboardingStates()
    }

    func toggleScheduleWeekday(_ weekday: Int) {
        guard (1...7).contains(weekday) else { return }

        if let index = persistedState.patientSetupDraft.selectedWeekdays.firstIndex(of: weekday) {
            if persistedState.patientSetupDraft.selectedWeekdays.count > 1 {
                persistedState.patientSetupDraft.selectedWeekdays.remove(at: index)
            }
        } else {
            persistedState.patientSetupDraft.selectedWeekdays.append(weekday)
        }

        persistedState.patientSetupDraft.selectedWeekdays.sort()
        persist()
        rebuildOnboardingStates()
    }

    func updateFoodPreference(_ withFood: Bool?) {
        persistedState.patientSetupDraft.takeWithFood = withFood
        persist()
    }

    func updateSupplySettings(_ supply: Int, _ threshold: Int) {
        persistedState.patientSetupDraft.supplyCount = supply
        persistedState.patientSetupDraft.lowSupplyThreshold = threshold
        persist()
    }

    func updateExactTime(id: UUID, hour: Int, minute: Int) {
        persistedState.patientSetupDraft.exactTimes = persistedState.patientSetupDraft.exactTimes.map { exactTime in
            guard exactTime.id == id else {
                return exactTime
            }

            return CareTapExactDoseTime(
                id: exactTime.id,
                title: exactTime.title,
                symbolName: exactTime.symbolName,
                hour: hour,
                minute: minute
            )
        }
        .sorted(by: exactTimeOrder(lhs:rhs:))
        persist()
        rebuildOnboardingStates()
    }

    func addCustomExactTime() {
        let nextTime = suggestedCustomExactTime(from: persistedState.patientSetupDraft.exactTimes)
        let title = nextCustomTimeTitle(from: persistedState.patientSetupDraft.exactTimes)

        persistedState.patientSetupDraft.exactTimes.append(
            CareTapExactDoseTime(
                title: title,
                symbolName: "clock.fill",
                hour: Calendar.current.component(.hour, from: nextTime),
                minute: Calendar.current.component(.minute, from: nextTime)
            )
        )
        persistedState.patientSetupDraft.exactTimes.sort(by: exactTimeOrder(lhs:rhs:))
        persist()
        rebuildOnboardingStates()
    }

    func removeExactTime(id: UUID) {
        guard persistedState.patientSetupDraft.exactTimes.count > 1,
              let timeToRemove = persistedState.patientSetupDraft.exactTimes.first(where: { $0.id == id }) else {
            return
        }

        persistedState.patientSetupDraft.exactTimes.removeAll { $0.id == id }
        if defaultSlotTitles.contains(timeToRemove.title) {
            persistedState.patientSetupDraft.selectedTimeTitles.removeAll { $0 == timeToRemove.title }
            if persistedState.patientSetupDraft.selectedTimeTitles.isEmpty,
               let firstRemainingDefault = persistedState.patientSetupDraft.exactTimes.first(where: { defaultSlotTitles.contains($0.title) }) {
                persistedState.patientSetupDraft.selectedTimeTitles = [firstRemainingDefault.title]
            }
        }

        persistedState.patientSetupDraft.exactTimes.sort(by: exactTimeOrder(lhs:rhs:))
        persist()
        rebuildOnboardingStates()
    }

    func attachBottlePhoto(data: Data) {
        do {
            let directoryURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let photoDirectory = directoryURL
                .appending(path: "CareTap", directoryHint: .isDirectory)
                .appending(path: "BottlePhotos", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)

            let fileURL = photoDirectory.appending(path: "\(UUID().uuidString).jpg")
            try data.write(to: fileURL, options: .atomic)
            persistedState.patientSetupDraft.bottlePhotoLocalPath = fileURL.path
            persist()
            rebuildOnboardingStates()
        } catch {
            errorMessage = "CareTap couldn’t save that photo on this device."
        }
    }

    func continueFromMedicationStep() {
        let medicationName = persistedState.patientSetupDraft.medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? persistedState.patientSetupDraft.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            : persistedState.patientSetupDraft.medicationName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !medicationName.isEmpty else {
            errorMessage = "Add a name first so TapCare can build the first schedule around something real."
            return
        }

        guard !persistedState.patientSetupDraft.selectedTimeTitles.isEmpty else {
            errorMessage = "Choose at least one daily time so the first check-in has a schedule."
            return
        }

        persistedState.patientSetupDraft.medicationName = medicationName
        persistedState.patientSetupStep = .routine
        persist()
        rebuildOnboardingStates()
        route = .onboarding(.patientSetup(.routine))
    }

    func returnToMedicationStep() {
        persistedState.patientSetupStep = .item
        persist()
        route = .onboarding(.patientSetup(.item))
        rebuildOnboardingStates()
    }

    func continueFromScheduleStep() async {
        guard let user = currentUser else {
            errorMessage = "Sign in first so TapCare can save this setup."
            return
        }

        let medicationName = persistedState.patientSetupDraft.medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !medicationName.isEmpty else {
            errorMessage = "This item still needs a name before TapCare can save it."
            return
        }

        if persistedState.patientSetupDraft.scheduleFrequency == .specificWeekdays,
           persistedState.patientSetupDraft.selectedWeekdays.isEmpty {
            errorMessage = "Choose at least one day so CareTap knows when to expect this item."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let profile = try await ensurePatientCareProfile(for: user)
            activeCareProfile = profile
            persistedState.activeCareProfileID = profile.id

            let medication = Medication(
                id: UUID(),
                careProfileID: profile.id,
                nfcTagID: nil,
                name: medicationName,
                category: persistedState.patientSetupDraft.medicationCategory,
                dosage: persistedState.patientSetupDraft.dosage.isEmpty ? "1 dose" : persistedState.patientSetupDraft.dosage,
                doseQuantity: 1,
                doseQuantityUnit: "dose",
                instructions: buildInstructions(),
                bottleLabel: persistedState.patientSetupDraft.bottleLabel,
                bottlePhotoLocalPath: persistedState.patientSetupDraft.bottlePhotoLocalPath,
                form: medicationForm(for: persistedState.patientSetupDraft.containerKind),
                containerKind: persistedState.patientSetupDraft.containerKind,
                scheduleSummary: scheduleSummaryText(from: persistedState.patientSetupDraft.exactTimes),
                isActive: true,
                supplyCount: Double(persistedState.patientSetupDraft.supplyCount),
                createdAt: .now,
                updatedAt: .now,
                archivedAt: nil,
                syncState: .pendingUpload
            )

            let storedMedication = try await services.recordStore.upsertMedication(medication)
            medications = [storedMedication]

            let draft = persistedState.patientSetupDraft
            let ruleType: ScheduleRuleType
            let ruleDaysOfWeek: [ScheduleWeekday]
            let ruleIntervalHours: Int?

            switch draft.scheduleFrequency {
            case .onceDaily, .twiceDaily, .threeTimesDaily:
                ruleType = .daily
                ruleDaysOfWeek = ScheduleWeekday.allCases
                ruleIntervalHours = nil
            case .everyXHours:
                ruleType = .interval
                ruleDaysOfWeek = ScheduleWeekday.allCases
                ruleIntervalHours = max(1, draft.intervalHours)
            case .specificWeekdays:
                ruleType = .weekly
                ruleDaysOfWeek = draft.selectedWeekdays.isEmpty
                    ? ScheduleWeekday.allCases
                    : draft.selectedWeekdays.compactMap { ScheduleWeekday(rawValue: $0) }
                ruleIntervalHours = nil
            case .asNeeded:
                ruleType = .asNeeded
                ruleDaysOfWeek = []
                ruleIntervalHours = nil
            }

            let rule = ScheduleRule(
                id: UUID(),
                medicationID: storedMedication.id,
                careProfileID: profile.id,
                type: ruleType,
                timezoneIdentifier: TimeZone.current.identifier,
                startsOn: Calendar.current.startOfDay(for: draft.startsOn),
                endsOn: nil,
                daysOfWeek: ruleDaysOfWeek,
                timesOfDay: draft.exactTimes.map {
                    ScheduleTimeOfDay(id: $0.id, hour: $0.hour, minute: $0.minute, label: $0.title)
                },
                intervalHours: ruleIntervalHours,
                gracePeriodMinutes: 60,
                snoozeDurationMinutes: 20,
                isActive: true,
                createdAt: .now,
                updatedAt: .now,
                syncState: .pendingUpload
            )
            let storedRule = try await services.recordStore.upsertScheduleRule(rule)
            rulesByMedicationID[storedMedication.id] = [storedRule]

            let reminderPreference = ReminderPreference(
                id: UUID(),
                userID: user.id,
                careProfileID: profile.id,
                channels: [.localNotification, .liveActivity],
                leadTimeMinutes: persistedState.patientSetupDraft.reminderLeadTimeMinutes,
                followUpAfterMinutes: 20,
                maxFollowUps: 1,
                quietHours: persistedState.patientSetupDraft.quietHoursEnabled
                    ? QuietHours(startHour: 22, startMinute: 0, endHour: 7, endMinute: 0)
                    : nil,
                enablesLiveActivity: true,
                createdAt: .now,
                updatedAt: .now,
                syncState: .pendingUpload
            )
            _ = try await services.recordStore.upsertReminderPreference(reminderPreference)

            let interval = DateInterval(
                start: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
                end: Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now.addingTimeInterval(14 * 24 * 60 * 60)
            )
            let generatedOccurrences = services.scheduleGenerator.generateOccurrences(
                for: storedMedication,
                rules: [storedRule],
                within: interval
            ).map { occurrence in
                DoseOccurrence(
                    id: occurrence.id,
                    careProfileID: occurrence.careProfileID,
                    medicationID: occurrence.medicationID,
                    scheduleRuleID: occurrence.scheduleRuleID,
                    scheduledAt: occurrence.scheduledAt,
                    windowOpensAt: occurrence.windowOpensAt,
                    windowClosesAt: occurrence.windowClosesAt,
                    snoozedUntil: nil,
                    status: occurrence.status,
                    reminderState: .scheduled,
                    flags: [],
                    resolvedByLogID: nil,
                    resolvedAt: nil,
                    createdAt: .now,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
            }

            for occurrence in generatedOccurrences {
                _ = try await services.recordStore.upsertDoseOccurrence(occurrence)
            }

            let refillState = services.refillEstimator.estimateRefillState(
                for: storedMedication,
                rules: [storedRule],
                asOf: .now
            )
            let storedRefillState = try await services.recordStore.upsertRefillState(refillState)
            refillStatesByMedicationID[storedMedication.id] = storedRefillState

            for occurrence in generatedOccurrences.prefix(6) where !occurrence.isResolved {
                _ = try? await services.reminders.scheduleReminders(
                    for: occurrence,
                    medication: storedMedication,
                    preference: reminderPreference
                )
            }

            persistedState.patientSetupStep = .tapSetup
            persist()
            try await refreshPatientExperience()
            presentNFCPairing(for: storedMedication, entryContext: .onboarding)
            route = .onboarding(.patientSetup(.tapSetup))
        } catch {
            errorMessage = "CareTap couldn’t save this schedule yet."
        }
    }

    func handleNFCPairingBack() {
        if nfcPairingEntryContext == .settings {
            persistedState.selectedDestination = .settings
            persist()
            route = .patient
            return
        }

        persistedState.patientSetupStep = .routine
        persist()
        route = .onboarding(.patientSetup(.routine))
    }

    func handleNFCPairingSecondaryAction() async {
        if nfcPairingState.phase == .success {
            if let medication = nfcPairingTargetMedication() {
                presentNFCPairing(for: medication, entryContext: nfcPairingEntryContext)
            }
            return
        }

        if nfcPairingEntryContext == .settings {
            persistedState.selectedDestination = .settings
            persist()
            route = .patient
            return
        }

        await finishPatientSetup()
    }

    func handleNFCPairingPrimaryAction() async {
        if nfcPairingState.phase == .success {
            if nfcPairingEntryContext == .settings {
                persistedState.selectedDestination = .settings
                persist()
                do {
                    try await refreshPatientExperience()
                } catch {
                    route = .patient
                }
            } else {
                await finishPatientSetup()
            }
            return
        }

        guard let profile = activeCareProfile,
              let medication = nfcPairingTargetMedication() else {
            errorMessage = "No medication found to pair. Add one first."
            return
        }

        nfcPairingState = NFCPairingViewState(
            stepText: nfcPairingEntryContext == .onboarding ? "Step 3 of 3" : "NFC Tools",
            title: "Hold steady",
            message: "Writing to the tag. Keep the container close.",
            medicationName: medication.displayTitle,
            bottleLabel: medication.bottleLabel,
            phase: .writing,
            helperTitle: "",
            helperMessage: "",
            helpItems: [],
            footerNote: "",
            automationURL: nfcPairingState.automationURL,
            primaryActionTitle: "Pairing\u{2026}",
            secondaryActionTitle: nfcPairingEntryContext == .onboarding ? "Skip" : "Back"
        )

        do {
            let payloadIdentifier = CareTapDeepLink.payloadIdentifier(for: medication.id)
            let result = try await services.nfcTags.writeTag(
                NFCTagWriteRequest(
                    careProfileID: profile.id,
                    medicationID: medication.id,
                    label: medication.bottleLabel,
                    stableUID: "caretap-pairing-\(medication.id.uuidString.lowercased())",
                    payloadIdentifier: payloadIdentifier
                )
            )
            let existingTagByStableUID = try await services.recordStore.tag(stableUID: result.tag.stableUID)
            let existingTag = if let existingTagByStableUID {
                existingTagByStableUID
            } else {
                try await services.recordStore.tag(payloadIdentifier: result.tag.payloadIdentifier)
            }
            let storedTag = try await services.recordStore.upsertNfcTag(
                NfcTag(
                    id: existingTag?.id ?? result.tag.id,
                    careProfileID: result.tag.careProfileID,
                    medicationID: result.tag.medicationID,
                    stableUID: result.tag.stableUID,
                    payloadIdentifier: result.tag.payloadIdentifier,
                    label: result.tag.label,
                    status: result.tag.status,
                    pairedAt: result.tag.pairedAt,
                    lastReadAt: existingTag?.lastReadAt,
                    lastWrittenAt: result.tag.lastWrittenAt,
                    createdAt: existingTag?.createdAt ?? result.tag.createdAt,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
            )

            if let previousMedicationID = existingTag?.medicationID,
               previousMedicationID != medication.id,
               let previousMedication = medications.first(where: { $0.id == previousMedicationID }) {
                let detachedMedication = try await services.recordStore.upsertMedication(
                    Medication(
                        id: previousMedication.id,
                        careProfileID: previousMedication.careProfileID,
                        nfcTagID: nil,
                        name: previousMedication.name,
                        dosage: previousMedication.dosage,
                        doseQuantity: previousMedication.doseQuantity,
                        doseQuantityUnit: previousMedication.doseQuantityUnit,
                        instructions: previousMedication.instructions,
                        bottleLabel: previousMedication.bottleLabel,
                        bottlePhotoLocalPath: previousMedication.bottlePhotoLocalPath,
                        form: previousMedication.form,
                        scheduleSummary: previousMedication.scheduleSummary,
                        isActive: previousMedication.isActive,
                        supplyCount: previousMedication.supplyCount,
                        createdAt: previousMedication.createdAt,
                        updatedAt: .now,
                        archivedAt: previousMedication.archivedAt,
                        syncState: .pendingUpload
                    )
                )
                medications = medications.map { existingMedication in
                    existingMedication.id == detachedMedication.id ? detachedMedication : existingMedication
                }
                infoMessage = "This tag was paired to something else. It's been reassigned here."
            }

            let updatedMedication = try await services.recordStore.upsertMedication(
                Medication(
                    id: medication.id,
                    careProfileID: medication.careProfileID,
                    nfcTagID: storedTag.id,
                    name: medication.name,
                    dosage: medication.dosage,
                    doseQuantity: medication.doseQuantity,
                    doseQuantityUnit: medication.doseQuantityUnit,
                    instructions: medication.instructions,
                    bottleLabel: medication.bottleLabel,
                    bottlePhotoLocalPath: medication.bottlePhotoLocalPath,
                    form: medication.form,
                    scheduleSummary: medication.scheduleSummary,
                    isActive: medication.isActive,
                    supplyCount: medication.supplyCount,
                    createdAt: medication.createdAt,
                    updatedAt: .now,
                    archivedAt: medication.archivedAt,
                    syncState: .pendingUpload
                )
            )
            medications = medications.map { existingMedication in
                existingMedication.id == updatedMedication.id ? updatedMedication : existingMedication
            }
            CareTapHaptics.success()
            nfcPairingState = NFCPairingViewState(
                stepText: nfcPairingEntryContext == .onboarding ? "Step 3 of 3" : "NFC Tools",
                title: "Tag paired",
                message: "Tap this container anytime to log a dose instantly.",
                medicationName: updatedMedication.displayTitle,
                bottleLabel: updatedMedication.bottleLabel,
                phase: .success,
                helperTitle: "",
                helperMessage: "",
                helpItems: [],
                footerNote: "",
                automationURL: CareTapDeepLink.tagURL(payloadIdentifier: payloadIdentifier),
                primaryActionTitle: nfcPairingEntryContext == .onboarding ? "Continue" : "Done",
                secondaryActionTitle: "Pair Another"
            )
        } catch {
            CareTapHaptics.error()
            nfcPairingState = NFCPairingViewState(
                stepText: nfcPairingEntryContext == .onboarding ? "Step 3 of 3" : "NFC Tools",
                title: "Pairing didn't finish",
                message: "The tag wasn't writable or moved too soon. You can try again or skip for now.",
                medicationName: medication.displayTitle,
                bottleLabel: medication.bottleLabel,
                phase: .failure,
                helperTitle: "",
                helperMessage: "",
                helpItems: [],
                footerNote: "",
                automationURL: nfcPairingState.automationURL,
                primaryActionTitle: "Try Again",
                secondaryActionTitle: nfcPairingEntryContext == .onboarding ? "Skip" : "Back"
            )
        }
    }

    func finishPatientSetup() async {
        persistedState.patientSetupStep = .tapSetup
        persistedState.hasCompletedPatientSetup = true
        persistedState.selectedDestination = .home
        persist()
        do {
            try await refreshPatientExperience()
            route = .patient
        } catch {
            errorMessage = "CareTap finished setup, but the patient home needs one more refresh."
        }
    }

    func handlePatientPrimaryAction() async {
        guard let currentOccurrence = currentOccurrence() else {
            if medications.isEmpty {
                persistedState.patientSetupStep = .item
                persist()
                route = .onboarding(.patientSetup(.item))
            } else {
                selectPatientWorkspaceSection(.items)
            }
            return
        }

        let currentMedication = medications.first(where: { $0.id == currentOccurrence.medicationID })

        if currentMedication?.nfcTagID != nil {
            do {
                let readResult = try await services.nfcTags.scanTag()
                try await handleScannedTag(readResult, note: "Tag tap confirmed in app")
            } catch {
                errorMessage = "Couldn't read the tag. Try holding the top of your iPhone closer, or use the manual button."
            }
        } else {
            await confirmCurrentDoseManually()
        }
    }

    private func presentNFCPairing(
        for medication: Medication,
        entryContext: NFCPairingEntryContext
    ) {
        nfcPairingEntryContext = entryContext
        nfcPairingMedicationID = medication.id
        nfcPairingState = NFCPairingViewState(
            stepText: entryContext == .onboarding ? "Step 3 of 3" : "NFC Tools",
            title: "Pair the tag",
            message: "Hold the top of your iPhone near the NFC sticker on the container.",
            medicationName: medication.displayTitle,
            bottleLabel: medication.bottleLabel,
            phase: .ready,
            helperTitle: "",
            helperMessage: "",
            helpItems: [],
            footerNote: "",
            automationURL: medication.nfcTagID == nil
                ? nil
                : CareTapDeepLink.tagURL(payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: medication.id)),
            primaryActionTitle: "Start Pairing",
            secondaryActionTitle: entryContext == .onboarding ? "Skip" : "Back"
        )
    }

    private func nfcPairingTargetMedication() -> Medication? {
        if let nfcPairingMedicationID,
           let pairedMedication = medications.first(where: { $0.id == nfcPairingMedicationID }) {
            return pairedMedication
        }

        if let currentOccurrence = currentOccurrence() {
            return medications.first(where: { $0.id == currentOccurrence.medicationID })
        }

        return medications.last
    }

    private func tappableOccurrence(for medicationID: UUID) -> DoseOccurrence? {
        occurrences
            .filter {
                $0.medicationID == medicationID
                    && isActionableOccurrence($0)
            }
            .sorted(by: preferredOccurrenceOrder(lhs:rhs:))
            .first
    }

    private func processPendingIncomingURLIfNeeded() async {
        guard let pendingIncomingURL else {
            return
        }

        self.pendingIncomingURL = nil
        await processIncomingURL(pendingIncomingURL)
    }

    private func processIncomingURL(_ url: URL) async {
        guard let deepLink = CareTapDeepLink(url: url) else {
            return
        }

        switch deepLink {
        case .tagTap(let payloadIdentifier):
            await handleIncomingTagTap(payloadIdentifier: payloadIdentifier)
        case .destination(let destination):
            await handleIncomingDestinationLink(destination)
        case .tapKitOrderResult(let success, let packSlug):
            handleTapKitOrderResult(success: success, packSlug: packSlug)
        }
    }

    private func handleIncomingDestinationLink(_ destination: CareTapDestination) async {
        guard let currentUser else {
            pendingIncomingURL = CareTapDeepLink.widgetURL(destination: destination)
            route = .onboarding(.roleSelection)
            infoMessage = "Finish signing in to open \(destination.title.lowercased())."
            return
        }

        persistedState.selectedDestination = destination
        persist()
        await routeAuthenticatedUser(currentUser)
    }

    private func handleIncomingTagTap(payloadIdentifier: String) async {
        guard currentUser != nil else {
            pendingIncomingURL = CareTapDeepLink.tagURL(payloadIdentifier: payloadIdentifier)
            route = .onboarding(.roleSelection)
            infoMessage = "Open TapCare after signing in to finish this tag tap."
            return
        }

        if selectedRole != .patient, persistedState.hasCompletedPatientSetup {
            selectedRole = .patient
            persistedState.selectedRole = .patient
            persist()
        }

        guard selectedRole == .patient else {
            infoMessage = "This tag tap is meant for the personal view on the shared phone."
            return
        }

        do {
            infoMessage = "Checking the tag..."
            let profile = try await ensureActivePatientProfile()
            activeCareProfile = profile
            persistedState.activeCareProfileID = profile.id
            persist()

            let storedTag = try await services.recordStore.tag(payloadIdentifier: payloadIdentifier)
            guard let storedTag else {
                infoMessage = "This tag has not been paired in CareTap yet."
                return
            }

            try await refreshPatientExperience()
            try await handleScannedTag(
                NFCTagReadResult(tag: storedTag, matchedMedicationID: storedTag.medicationID),
                note: "Tag tap confirmed from the tag."
            )
            persistedState.selectedDestination = .home
            persist()
            route = .patient
        } catch {
            errorMessage = "CareTap couldn’t finish that tag tap yet."
        }
    }

    private func handleScannedTag(
        _ readResult: NFCTagReadResult,
        note: String
    ) async throws {
        guard let matchedMedicationID = readResult.matchedMedicationID ?? readResult.tag.medicationID,
              let matchedMedication = medications.first(where: { $0.id == matchedMedicationID }) else {
            errorMessage = "CareTap recognized the tag, but it is not linked to an active item yet."
            presentTapConfirmation(
                .unknownTag(.init(message: "This tag isn't paired to an active item yet. Open TapCare and pair it first.")),
                isNFCSource: true
            )
            return
        }

        if let recentDoubleTap = detectDoubleTap(for: matchedMedicationID) {
            let minutesAgo = max(0, Int(Date().timeIntervalSince(recentDoubleTap.loggedAt) / 60))
            presentTapConfirmation(
                .alreadyLogged(.init(
                    medicationName: matchedMedication.displayTitle,
                    dosage: matchedMedication.dosage,
                    previousLoggedAt: recentDoubleTap.loggedAt,
                    minutesAgo: minutesAgo
                )),
                isNFCSource: true
            )
            pendingDoubleTapMedicationID = matchedMedicationID
            infoMessage = nil
            CareTapHaptics.warning()
            return
        }

        let targetOccurrence: DoseOccurrence
        if let tappable = tappableOccurrence(for: matchedMedicationID) {
            targetOccurrence = tappable
        } else if let nearest = nearestUnresolvedOccurrence(for: matchedMedicationID) {
            guard nearest.windowOpensAt <= .now else {
                presentTapConfirmation(
                    .tooEarly(.init(
                        medicationName: matchedMedication.displayTitle,
                        dosage: matchedMedication.dosage,
                        windowOpensAt: nearest.windowOpensAt
                    )),
                    isNFCSource: true
                )
                pendingEarlyOccurrenceID = nearest.id
                return
            }
            targetOccurrence = nearest
        } else {
            presentTapConfirmation(
                .noActiveDose(.init(
                    medicationName: matchedMedication.displayTitle,
                    dosage: matchedMedication.dosage,
                    nextScheduledAt: occurrences
                        .filter { $0.medicationID == matchedMedicationID && !$0.isResolved }
                        .sorted(by: { $0.scheduledAt < $1.scheduledAt })
                        .first?
                        .scheduledAt
                )),
                isNFCSource: true
            )
            pendingOffScheduleMedicationID = matchedMedicationID
            return
        }

        let result = try await services.doseLogging.logDose(
            for: targetOccurrence,
            request: DoseLoggingRequest(
                actorUserID: currentUser?.id,
                source: .nfcTap,
                action: .confirmTaken,
                loggedAt: .now,
                note: note,
                nfcTagID: readResult.tag.id
            )
        )
        try await handleDoseLoggingResult(
            result,
            acceptedMessage: "\(matchedMedication.displayTitle) was confirmed from the tag tap."
        )

        if case .accepted = result.log.validationState {
            presentTapConfirmation(
                .logged(.init(
                    medicationName: matchedMedication.displayTitle,
                    dosage: matchedMedication.dosage,
                    loggedAt: result.log.loggedAt,
                    nextDoseLabel: nextDoseLabel(for: matchedMedicationID, after: result.log.loggedAt),
                    isAutomationConfigured: persistedState.hasConfirmedNFCAutomation
                )),
                isNFCSource: true
            )
        }
    }

    /// Last 4-minute accepted log guard — if the user taps their bottle moments
    /// after confirming it, we want to notice and gently surface the existing
    /// log instead of silently re-resolving the occurrence.
    private func detectDoubleTap(for medicationID: UUID) -> DoseLog? {
        let threshold = Date().addingTimeInterval(
            -TimeInterval(NFCTapConfirmationState.doubleTapGuardMinutes * 60)
        )
        return doseLogsByOccurrenceID.values
            .flatMap { $0 }
            .filter {
                $0.medicationID == medicationID
                && $0.validationState == .accepted
                && $0.action == .confirmTaken
                && $0.loggedAt >= threshold
            }
            .max(by: { $0.loggedAt < $1.loggedAt })
    }

    private func nextDoseLabel(for medicationID: UUID, after date: Date) -> String? {
        let upcoming = occurrences
            .filter { $0.medicationID == medicationID && !$0.isResolved && $0.scheduledAt > date }
            .sorted(by: { $0.scheduledAt < $1.scheduledAt })
            .first
        return upcoming.map { $0.scheduledAt.formatted(date: .abbreviated, time: .shortened) }
    }

    private func presentTapConfirmation(
        _ outcome: NFCTapConfirmationState.Outcome,
        isNFCSource: Bool
    ) {
        tapConfirmation = NFCTapConfirmationState(outcome: outcome, isNFCSource: isNFCSource)
    }

    func dismissTapConfirmation() {
        tapConfirmation = nil
        pendingDoubleTapMedicationID = nil
        pendingEarlyOccurrenceID = nil
        pendingOffScheduleMedicationID = nil
    }

    func reviewTapConfirmationHistory() {
        dismissTapConfirmation()
        selectPatientWorkspaceSection(.history)
    }

    func logAnywayFromTapConfirmation() async {
        guard let medicationID = pendingDoubleTapMedicationID,
              let medication = medications.first(where: { $0.id == medicationID }) else {
            dismissTapConfirmation()
            return
        }

        dismissTapConfirmation()

        let targetOccurrence: DoseOccurrence
        if let tappable = tappableOccurrence(for: medicationID) {
            targetOccurrence = tappable
        } else if let nearest = nearestUnresolvedOccurrence(for: medicationID),
                  nearest.windowOpensAt <= .now {
            targetOccurrence = nearest
        } else {
            infoMessage = "\(medication.displayTitle) is already logged. The next scheduled dose will take the confirmation."
            return
        }

        do {
            let result = try await services.doseLogging.logDose(
                for: targetOccurrence,
                request: DoseLoggingRequest(
                    actorUserID: currentUser?.id,
                    source: .manualPatientConfirmation,
                    action: .confirmTaken,
                    loggedAt: .now,
                    note: "Additional dose confirmed after double-tap guard.",
                    nfcTagID: nil
                )
            )
            try await handleDoseLoggingResult(
                result,
                acceptedMessage: "\(medication.displayTitle) logged as an additional dose."
            )
        } catch {
            errorMessage = "CareTap couldn’t record the extra dose yet."
        }
    }

    func logOutsideWindowFromTapConfirmation() async {
        if let occurrenceID = pendingEarlyOccurrenceID,
           let occurrence = occurrences.first(where: { $0.id == occurrenceID }),
           let medication = medications.first(where: { $0.id == occurrence.medicationID }) {
            dismissTapConfirmation()
            do {
                let result = try await services.doseLogging.logDose(
                    for: occurrence,
                    request: DoseLoggingRequest(
                        actorUserID: currentUser?.id,
                        source: .manualPatientConfirmation,
                        action: .confirmTaken,
                        loggedAt: .now,
                        note: "Confirmed early from a tap — outside the usual window.",
                        nfcTagID: nil
                    )
                )
                try await handleDoseLoggingResult(
                    result,
                    acceptedMessage: "\(medication.displayTitle) marked as taken early."
                )
            } catch {
                errorMessage = "CareTap couldn’t record that early confirmation."
            }
            return
        }

        if let medicationID = pendingOffScheduleMedicationID,
           let medication = medications.first(where: { $0.id == medicationID }) {
            dismissTapConfirmation()
            if let nearest = nearestUnresolvedOccurrence(for: medicationID) {
                do {
                    let result = try await services.doseLogging.logDose(
                        for: nearest,
                        request: DoseLoggingRequest(
                            actorUserID: currentUser?.id,
                            source: .manualPatientConfirmation,
                            action: .confirmTaken,
                            loggedAt: .now,
                            note: "Confirmed off-schedule from a tap.",
                            nfcTagID: nil
                        )
                    )
                    try await handleDoseLoggingResult(
                        result,
                        acceptedMessage: "\(medication.displayTitle) logged as an off-schedule dose."
                    )
                } catch {
                    errorMessage = "CareTap couldn’t record that off-schedule dose."
                }
            } else {
                infoMessage = "\(medication.displayTitle) has no scheduled doses — the log was saved as a reminder."
            }
            return
        }

        dismissTapConfirmation()
    }

    private func nearestUnresolvedOccurrence(for medicationID: UUID) -> DoseOccurrence? {
        let now = Date()
        let candidates = occurrences
            .filter { $0.medicationID == medicationID && !$0.isResolved }

        let pastOrOpen = candidates
            .filter { $0.windowOpensAt <= now }
            .sorted { abs($0.scheduledAt.timeIntervalSince(now)) < abs($1.scheduledAt.timeIntervalSince(now)) }

        if let best = pastOrOpen.first {
            return best
        }

        return candidates
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    private func ensureActivePatientProfile() async throws -> CareProfile {
        if let activeCareProfile {
            return activeCareProfile
        }

        if let activeProfileID = persistedState.activeCareProfileID,
           let profile = try await services.recordStore.fetchCareProfile(id: activeProfileID) {
            return profile
        }

        guard let user = currentUser else {
            throw CareTapServiceError.missingRecord
        }

        let profile = try await ensurePatientCareProfile(for: user)
        return profile
    }

    func handlePatientSecondaryAction(_ action: SecondaryActionState) async {
        switch action.kind ?? legacyPatientSecondaryActionKind(for: action.title) {
        case .manualCheckIn:
            await confirmCurrentDoseManually()
        case .snooze:
            await snoozeCurrentDose()
        case .skip:
            await skipCurrentDose()
        case .openHistory:
            selectPatientWorkspaceSection(.history)
        case .openItems:
            selectPatientWorkspaceSection(.items)
        case .openSettings:
            selectDestination(.settings)
        case nil:
            break
        }
    }

    private func confirmCurrentDoseManually() async {
        guard let currentOccurrence = currentOccurrence() else { return }
        let medication = medications.first(where: { $0.id == currentOccurrence.medicationID })
        let medicationTitle = medication?.displayTitle ?? "This dose"

        do {
            let result = try await services.doseLogging.logDose(
                for: currentOccurrence,
                request: DoseLoggingRequest(
                    actorUserID: currentUser?.id,
                    source: .manualPatientConfirmation,
                    action: .confirmTaken,
                    loggedAt: .now,
                    note: "Manual patient confirmation",
                    nfcTagID: nil
                )
            )
            try await handleDoseLoggingResult(
                result,
                acceptedMessage: "\(medicationTitle) was confirmed manually."
            )

            if case .accepted = result.log.validationState, let medication {
                presentTapConfirmation(
                    .logged(.init(
                        medicationName: medication.displayTitle,
                        dosage: medication.dosage,
                        loggedAt: result.log.loggedAt,
                        nextDoseLabel: nextDoseLabel(for: medication.id, after: result.log.loggedAt),
                        isAutomationConfigured: true
                    )),
                    isNFCSource: false
                )
            }
        } catch {
            errorMessage = "CareTap couldn’t save that manual confirmation."
        }
    }

    private func snoozeCurrentDose() async {
        guard let currentOccurrence = currentOccurrence(),
              let rules = rulesByMedicationID[currentOccurrence.medicationID],
              let rule = rules.first(where: { $0.id == currentOccurrence.scheduleRuleID }) else {
            return
        }

        let snoozedOccurrence = DoseOccurrence(
            id: currentOccurrence.id,
            careProfileID: currentOccurrence.careProfileID,
            medicationID: currentOccurrence.medicationID,
            scheduleRuleID: currentOccurrence.scheduleRuleID,
            scheduledAt: currentOccurrence.scheduledAt,
            windowOpensAt: currentOccurrence.windowOpensAt,
            windowClosesAt: currentOccurrence.windowClosesAt,
            snoozedUntil: Date().addingTimeInterval(TimeInterval(rule.snoozeDurationMinutes * 60)),
            status: .snoozed,
            reminderState: .actionTaken,
            flags: currentOccurrence.flags,
            resolvedByLogID: currentOccurrence.resolvedByLogID,
            resolvedAt: currentOccurrence.resolvedAt,
            createdAt: currentOccurrence.createdAt,
            updatedAt: .now,
            syncState: .pendingUpload
        )

        do {
            _ = try await services.recordStore.upsertDoseOccurrence(snoozedOccurrence)
            if let medication = medications.first(where: { $0.id == currentOccurrence.medicationID }),
               let reminderPreference = try await currentReminderPreference() {
                _ = try? await services.reminders.scheduleReminders(
                    for: snoozedOccurrence,
                    medication: medication,
                    preference: reminderPreference
                )
            }
            try await refreshPatientExperience()
        } catch {
            errorMessage = "CareTap couldn’t snooze that dose yet."
        }
    }

    private func skipCurrentDose() async {
        guard let currentOccurrence = currentOccurrence() else { return }
        let medicationTitle = medications
            .first(where: { $0.id == currentOccurrence.medicationID })?
            .displayTitle ?? "This dose"

        do {
            let result = try await services.doseLogging.logDose(
                for: currentOccurrence,
                request: DoseLoggingRequest(
                    actorUserID: currentUser?.id,
                    source: .manualPatientConfirmation,
                    action: .markSkipped,
                    loggedAt: .now,
                    note: "Skipped in patient home",
                    nfcTagID: nil
                )
            )
            try await handleDoseLoggingResult(
                result,
                acceptedMessage: "\(medicationTitle) was marked as skipped."
            )
        } catch {
            errorMessage = "CareTap couldn’t mark that dose as skipped."
        }
    }

    func undoLatestDoseLog(for occurrenceID: UUID) async {
        guard let occurrence = occurrences.first(where: { $0.id == occurrenceID }),
              let logToUndo = doseLogsByOccurrenceID[occurrenceID]?
                .sorted(by: { $0.loggedAt > $1.loggedAt })
                .first(where: { $0.validationState == .accepted && $0.resolutionKind != .undo }) else {
            infoMessage = "There isn’t a recent confirmation to undo for that item."
            return
        }

        let medicationTitle = medications
            .first(where: { $0.id == occurrence.medicationID })?
            .displayTitle ?? "That item"

        do {
            let result = try await services.doseLogging.logDose(
                for: occurrence,
                request: DoseLoggingRequest(
                    actorUserID: currentUser?.id,
                    source: .laterCorrection,
                    action: .correctEntry,
                    loggedAt: .now,
                    note: "Undone from history",
                    resolutionReason: "Latest confirmation was undone",
                    undoesLogID: logToUndo.id,
                    nfcTagID: nil
                )
            )
            try await handleDoseLoggingResult(
                result,
                acceptedMessage: "\(medicationTitle) is open again after undoing the last check-in."
            )
        } catch {
            errorMessage = "CareTap couldn’t undo that check-in yet."
        }
    }

    private func refreshPatientExperience() async throws {
        guard let user = currentUser else {
            throw CareTapServiceError.missingRecord
        }
        let profile = if let activeCareProfile {
            activeCareProfile
        } else {
            try await ensurePatientCareProfile(for: user)
        }

        activeCareProfile = profile
        persistedState.activeCareProfileID = profile.id
        persist()

        try await ensureDerivedPatientData(for: profile, user: user)

        patientHomeState = CareTapStateBuilder.patientHomeState(
            user: user,
            careProfile: profile,
            relationships: relationships,
            medications: medications,
            occurrences: occurrences,
            destination: persistedState.selectedDestination
        )

        patientMedicationRows = CareTapStateBuilder.patientMedicationRows(
            medications: medications,
            occurrences: occurrences,
            refillStates: refillStatesByMedicationID,
            logsByOccurrenceID: doseLogsByOccurrenceID,
            relationships: relationships
        )
        let medicationMap = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })
        patientHistoryRows = CareTapStateBuilder.patientHistoryRows(
            occurrences: occurrences,
            medications: medicationMap,
            logsByOccurrenceID: doseLogsByOccurrenceID
        )

        let reminderPreference = try await currentReminderPreference()
        settingsState = CareTapStateBuilder.settingsState(
            user: user,
            profile: personProfile(for: user, profile: profile),
            selectedRole: .patient,
            reminderPreference: reminderPreference,
            relationships: relationships,
            invitations: invitations,
            isNotificationAuthorized: settingsNotificationAuthorized,
            syncSnapshot: await services.recordStore.syncSnapshot()
        )

        try? services.widgetSnapshots.save(
            bestNextStep: CareTapStateBuilder.bestNextStepSnapshot(from: patientHomeState),
            todaySnapshot: CareTapStateBuilder.todaySnapshotWidgetState(from: patientHomeState)
        )
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

        if let occurrence = liveActivityOccurrence(reminderPreference: reminderPreference),
           let medication = medications.first(where: { $0.id == occurrence.medicationID }) {
            await services.liveActivities.updateCurrentDoseActivity(
                profileName: profile.preferredName ?? profile.displayName,
                medication: medication,
                occurrence: occurrence
            )
        } else {
            await services.liveActivities.endAllActivities()
        }

        route = .patient
        await syncInBackground()
    }

    private func ensurePatientCareProfile(for user: User) async throws -> CareProfile {
        let profiles = try await services.recordStore.careProfiles(createdBy: user.id)
        if let existing = profiles.first(where: { $0.patientUserID == user.id }) ?? profiles.first {
            return existing
        }

        let profile = CareProfile(
            id: UUID(),
            createdByUserID: user.id,
            patientUserID: user.id,
            displayName: user.displayName,
            preferredName: user.displayName.components(separatedBy: " ").first,
            initials: user.initials,
            avatarStyle: .patient,
            timezoneIdentifier: user.timezoneIdentifier,
            notes: "Patient-managed CareTap profile",
            createdAt: .now,
            updatedAt: .now,
            syncState: .pendingUpload
        )
        return try await services.recordStore.upsertCareProfile(profile)
    }

    private func ensureDerivedPatientData(for profile: CareProfile, user: User) async throws {
        relationships = try await services.recordStore.relationships(forCareProfileID: profile.id)
        invitations = try await services.recordStore.invitations(for: profile.id)
        medications = try await services.recordStore.medications(for: profile.id)

        var nextRules: [UUID: [ScheduleRule]] = [:]
        for medication in medications {
            nextRules[medication.id] = try await services.recordStore.rules(for: medication.id)
        }
        rulesByMedicationID = nextRules

        let interval = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now,
            end: Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now.addingTimeInterval(14 * 24 * 60 * 60)
        )
        var currentOccurrences = try await services.recordStore.occurrences(for: profile.id, within: interval)
        let existingKeys = Set(currentOccurrences.map { occurrenceKey(ruleID: $0.scheduleRuleID, scheduledAt: $0.scheduledAt) })

        for medication in medications {
            let generated = services.scheduleGenerator.generateOccurrences(
                for: medication,
                rules: nextRules[medication.id] ?? [],
                within: interval
            )
            for generatedOccurrence in generated {
                let key = occurrenceKey(ruleID: generatedOccurrence.scheduleRuleID, scheduledAt: generatedOccurrence.scheduledAt)
                if !existingKeys.contains(key) {
                    _ = try await services.recordStore.upsertDoseOccurrence(
                        DoseOccurrence(
                            id: generatedOccurrence.id,
                            careProfileID: generatedOccurrence.careProfileID,
                            medicationID: generatedOccurrence.medicationID,
                            scheduleRuleID: generatedOccurrence.scheduleRuleID,
                            scheduledAt: generatedOccurrence.scheduledAt,
                            windowOpensAt: generatedOccurrence.windowOpensAt,
                            windowClosesAt: generatedOccurrence.windowClosesAt,
                            snoozedUntil: nil,
                            status: generatedOccurrence.status,
                            reminderState: .scheduled,
                            flags: [],
                            resolvedByLogID: nil,
                            resolvedAt: nil,
                            createdAt: .now,
                            updatedAt: .now,
                            syncState: .pendingUpload
                        )
                    )
                }
            }
        }

        currentOccurrences = try await services.recordStore.occurrences(for: profile.id, within: interval)
        var normalizedOccurrences: [DoseOccurrence] = []
        for occurrence in currentOccurrences {
            let normalized = dynamicOccurrence(occurrence)
            if normalized != occurrence {
                _ = try await services.recordStore.upsertDoseOccurrence(normalized)
                normalizedOccurrences.append(normalized)
            } else {
                normalizedOccurrences.append(occurrence)
            }
        }
        occurrences = normalizedOccurrences.sorted { $0.scheduledAt < $1.scheduledAt }
        doseLogsByOccurrenceID = try await loadLogs(for: occurrences)

        refillStatesByMedicationID = [:]
        for medication in medications {
            let rules = nextRules[medication.id] ?? []
            let state = services.refillEstimator.estimateRefillState(for: medication, rules: rules, asOf: .now)
            let stored = try await services.recordStore.upsertRefillState(state)
            refillStatesByMedicationID[medication.id] = stored
        }

        if let reminderPreference = try await currentReminderPreference() {
            for occurrence in occurrences where !occurrence.isResolved && occurrence.scheduledAt > .now.addingTimeInterval(-60) {
                if let medication = medications.first(where: { $0.id == occurrence.medicationID }) {
                    _ = try? await services.reminders.scheduleReminders(
                        for: occurrence,
                        medication: medication,
                        preference: reminderPreference
                    )
                }
            }
        }
    }

    private func currentReminderPreference() async throws -> ReminderPreference? {
        guard let user = currentUser, let profile = activeCareProfile else {
            return nil
        }

        return try await services.recordStore.preference(for: user.id, careProfileID: profile.id)
    }

    private func dynamicOccurrence(_ occurrence: DoseOccurrence) -> DoseOccurrence {
        guard !occurrence.isResolved else {
            return occurrence
        }

        let now = Date()
        let nextStatus: DoseOccurrenceStatus
        if let snoozedUntil = occurrence.snoozedUntil, snoozedUntil > now {
            nextStatus = .snoozed
        } else if now < occurrence.scheduledAt {
            nextStatus = .scheduled
        } else if now <= occurrence.windowClosesAt {
            nextStatus = .dueNow
        } else if now > occurrence.windowClosesAt.addingTimeInterval(4 * 60 * 60) {
            nextStatus = .missed
        } else {
            nextStatus = .overdue
        }

        if nextStatus == occurrence.status {
            return occurrence
        }

        var flags = Set(occurrence.flags)
        if nextStatus == .missed {
            flags.insert(.missed)
        }

        return DoseOccurrence(
            id: occurrence.id,
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            scheduleRuleID: occurrence.scheduleRuleID,
            scheduledAt: occurrence.scheduledAt,
            windowOpensAt: occurrence.windowOpensAt,
            windowClosesAt: occurrence.windowClosesAt,
            snoozedUntil: occurrence.snoozedUntil,
            status: nextStatus,
            reminderState: occurrence.reminderState,
            flags: Array(flags),
            resolvedByLogID: occurrence.resolvedByLogID,
            resolvedAt: occurrence.resolvedAt,
            createdAt: occurrence.createdAt,
            updatedAt: .now,
            syncState: .pendingUpload
        )
    }

    private func currentOccurrence() -> DoseOccurrence? {
        occurrences
            .filter { isActionableOccurrence($0) }
            .sorted(by: preferredOccurrenceOrder(lhs:rhs:))
            .first
    }

    private func isActionableOccurrence(_ occurrence: DoseOccurrence, now: Date = .now) -> Bool {
        guard !occurrence.isResolved else {
            return false
        }

        switch occurrence.status {
        case .dueNow, .overdue, .missed, .snoozed:
            return true
        case .scheduled:
            return occurrence.windowOpensAt <= now
        case .completed, .late, .skipped, .resolved:
            return false
        }
    }

    private func liveActivityOccurrence(reminderPreference: ReminderPreference?) -> DoseOccurrence? {
        guard reminderPreference?.enablesLiveActivity ?? true else {
            return nil
        }

        let now = Date()
        let leadTimeSeconds = TimeInterval((reminderPreference?.leadTimeMinutes ?? 0) * 60)

        return occurrences
            .filter { occurrence in
                guard !occurrence.isResolved else {
                    return false
                }

                switch occurrence.status {
                case .dueNow, .overdue, .missed, .snoozed:
                    return true
                case .scheduled:
                    let nextReferenceDate = occurrence.snoozedUntil ?? occurrence.scheduledAt
                    return nextReferenceDate.timeIntervalSince(now) <= leadTimeSeconds
                case .completed, .late, .skipped, .resolved:
                    return false
                }
            }
            .sorted(by: preferredOccurrenceOrder(lhs:rhs:))
            .first
    }

    private func preferredOccurrenceOrder(lhs: DoseOccurrence, rhs: DoseOccurrence) -> Bool {
        let lhsPriority = occurrencePriority(lhs)
        let rhsPriority = occurrencePriority(rhs)
        guard lhsPriority == rhsPriority else {
            return lhsPriority < rhsPriority
        }

        switch lhsPriority {
        case 0, 1, 3:
            return lhs.scheduledAt > rhs.scheduledAt
        case 2:
            return lhs.scheduledAt < rhs.scheduledAt
        default:
            return lhs.scheduledAt > rhs.scheduledAt
        }
    }

    private func occurrencePriority(_ occurrence: DoseOccurrence) -> Int {
        let now = Date()

        if let snoozedUntil = occurrence.snoozedUntil, snoozedUntil > now {
            return 0
        }

        if occurrence.windowOpensAt <= now, occurrence.windowClosesAt >= now {
            return 0
        }

        if occurrence.windowClosesAt < now {
            return now.timeIntervalSince(occurrence.windowClosesAt) <= 12 * 60 * 60 ? 1 : 3
        }

        if occurrence.scheduledAt > now {
            return 2
        }

        return 3
    }

    private func buildInstructions() -> String? {
        let draft = persistedState.patientSetupDraft
        var parts: [String] = []
        if let withFood = draft.takeWithFood {
            parts.append(withFood ? "Take with food" : "Take on an empty stomach")
        }
        if !draft.instructions.isEmpty {
            parts.append(draft.instructions)
        }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }

    private func scheduleTitle(for category: MedicationCategory) -> String {
        switch category {
        case .prescription:
            return "Fill in the details"
        case .otc:
            return "Shape the routine"
        case .supplement:
            return "Set the routine details"
        }
    }

    private func scheduleMessage(for category: MedicationCategory, containerKind: ContainerKind) -> String {
        switch category {
        case .prescription:
            return "Add the dose, exact times, and the \(containerKind.title.lowercased()) details you want to see every day."
        case .otc:
            return "Add the amount, exact times, and the \(containerKind.title.lowercased()) details you want to keep close."
        case .supplement:
            return "Set the amount, exact times, and the \(containerKind.title.lowercased()) details that make this routine easy to repeat."
        }
    }

    private func dosageFieldTitle(for category: MedicationCategory) -> String {
        switch category {
        case .prescription:
            return "Dose"
        case .otc, .supplement:
            return "Amount"
        }
    }

    private func containerFieldTitle(for containerKind: ContainerKind) -> String {
        switch containerKind {
        case .bottle:
            return "Bottle label"
        case .organizer:
            return "Organizer label"
        case .tray:
            return "Tray label"
        case .packet:
            return "Packet label"
        }
    }

    private func notesFieldTitle(for category: MedicationCategory) -> String {
        switch category {
        case .prescription:
            return "Instructions"
        case .otc, .supplement:
            return "Routine notes"
        }
    }

    private func timingHelperText(for category: MedicationCategory) -> String {
        switch category {
        case .prescription:
            return "Add or adjust the exact times you want to see on Home."
        case .otc:
            return "Add the exact times that feel realistic for this item."
        case .supplement:
            return "Add the exact times that feel natural for this routine."
        }
    }

    private func photoSectionTitle(for containerKind: ContainerKind) -> String {
        switch containerKind {
        case .packet:
            return "Packet Photo"
        case .tray:
            return "Tray Photo"
        default:
            return "Container Photo"
        }
    }

    private func medicationForm(for containerKind: ContainerKind) -> MedicationForm {
        switch containerKind {
        case .bottle:
            return .bottle
        case .organizer:
            return .pillOrganizer
        case .tray:
            return .other
        case .packet:
            return .blisterPack
        }
    }

    private func defaultContainerLabel(for containerKind: ContainerKind) -> String {
        switch containerKind {
        case .bottle:
            return "Primary bottle"
        case .organizer:
            return "Weekly organizer"
        case .tray:
            return "Daily tray"
        case .packet:
            return "Primary packet"
        }
    }

    private func inferredCategory(from query: String, fallback: MedicationCategory) -> MedicationCategory {
        let loweredQuery = query.lowercased()
        let supplementKeywords = ["vitamin", "protein", "creatine", "electrolyte", "magnesium", "omega", "fish oil", "melatonin", "probiotic"]
        let otcKeywords = ["ibuprofen", "acetaminophen", "tylenol", "advil", "allergy", "cetirizine"]

        if supplementKeywords.contains(where: loweredQuery.contains) {
            return .supplement
        }

        if otcKeywords.contains(where: loweredQuery.contains) {
            return .otc
        }

        return fallback
    }

    private func scheduleSummaryText(from exactTimes: [CareTapExactDoseTime]) -> String {
        let times = exactTimes
            .sorted { lhs, rhs in lhs.hour == rhs.hour ? lhs.minute < rhs.minute : lhs.hour < rhs.hour }
            .map { timeString(hour: $0.hour, minute: $0.minute) }
            .joined(separator: ", ")
        return "Every day at \(times)"
    }

    private func occurrenceKey(ruleID: UUID, scheduledAt: Date) -> String {
        "\(ruleID.uuidString)-\(scheduledAt.timeIntervalSince1970)"
    }

    private func slotOrder(lhs: String, rhs: String) -> Bool {
        let order = defaultSlotTitles
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    private var defaultSlotTitles: [String] {
        ["Morning", "Noon", "Evening", "Night"]
    }

    private func exactTimeOrder(lhs: CareTapExactDoseTime, rhs: CareTapExactDoseTime) -> Bool {
        if lhs.hour == rhs.hour {
            return lhs.minute < rhs.minute
        }
        return lhs.hour < rhs.hour
    }

    private func suggestedCustomExactTime(from exactTimes: [CareTapExactDoseTime]) -> Date {
        guard let latestTime = exactTimes.max(by: { exactTimeOrder(lhs: $0, rhs: $1) }) else {
            return Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? .now
        }

        let baseDate = Calendar.current.date(
            from: DateComponents(hour: latestTime.hour, minute: latestTime.minute)
        ) ?? .now
        let offsetDate = Calendar.current.date(byAdding: .hour, value: 4, to: baseDate) ?? baseDate
        let components = Calendar.current.dateComponents([.hour, .minute], from: offsetDate)
        return Calendar.current.date(
            from: DateComponents(hour: components.hour ?? 9, minute: components.minute ?? 0)
        ) ?? offsetDate
    }

    private func nextCustomTimeTitle(from exactTimes: [CareTapExactDoseTime]) -> String {
        let customTitles = exactTimes
            .map(\.title)
            .filter { $0.hasPrefix("Custom time") }

        guard !customTitles.contains("Custom time") else {
            return "Custom time \(customTitles.count + 1)"
        }

        return "Custom time"
    }

    private func defaultSelectedWeekday(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func personProfile(for user: User, profile: CareProfile) -> PersonProfile {
        if selectedRole == .caregiver {
            return PersonProfile(id: user.id, displayName: user.displayName, initials: user.initials, style: .caregiver)
        }

        return PersonProfile(
            id: profile.id,
            displayName: profile.preferredName ?? profile.displayName,
            initials: profile.initials,
            style: profile.avatarStyle
        )
    }

    private func loadLogs(for occurrences: [DoseOccurrence]) async throws -> [UUID: [DoseLog]] {
        var groupedLogs: [UUID: [DoseLog]] = [:]
        for occurrence in occurrences {
            groupedLogs[occurrence.id] = try await services.recordStore.logs(for: occurrence.id)
        }
        return groupedLogs
    }

    private func handleDoseLoggingResult(
        _ result: DoseLoggingResult,
        acceptedMessage: String
    ) async throws {
        switch result.log.validationState {
        case .accepted:
            try await services.reminders.cancelReminders(for: result.occurrence.id)
            CareTapHaptics.success()
            infoMessage = acceptedMessage
        case .duplicate:
            CareTapHaptics.warning()
            infoMessage = "CareTap already has a confirmation for this dose, so the first trusted log stayed in place."
        case .tooEarly:
            CareTapHaptics.warning()
            infoMessage = "That confirmation landed before the dose window opened, so CareTap kept the event unresolved for now."
        case .superseded:
            infoMessage = "A newer correction already replaced that dose log."
        case .rejected:
            CareTapHaptics.error()
            errorMessage = "CareTap couldn’t save that dose log."
        }

        try await refreshRoleExperience()
    }

    private func handleInfoBannerChange(previousValue: String?) {
        infoBannerDismissTask?.cancel()

        guard let message = infoMessage, !message.isEmpty else {
            return
        }

        if shouldStoreNotice(message: message), previousValue != message {
            appendNotice(title: "TapCare", message: message, tone: .mist)
        }

        scheduleBannerDismiss(matching: message, seconds: 3.5, kind: .info)
    }

    private func handleErrorBannerChange(previousValue: String?) {
        errorBannerDismissTask?.cancel()

        guard let message = errorMessage, !message.isEmpty else {
            return
        }

        if shouldStoreNotice(message: message), previousValue != message {
            appendNotice(title: "Needs attention", message: message, tone: .alert)
        }

        scheduleBannerDismiss(matching: message, seconds: 5.0, kind: .error)
    }

    private enum BannerKind {
        case info
        case error
    }

    private func scheduleBannerDismiss(
        matching message: String,
        seconds: Double,
        kind: BannerKind
    ) {
        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled else { return }

            switch kind {
            case .info:
                if self.infoMessage == message {
                    self.infoMessage = nil
                }
            case .error:
                if self.errorMessage == message {
                    self.errorMessage = nil
                }
            }
        }

        switch kind {
        case .info:
            infoBannerDismissTask = task
        case .error:
            errorBannerDismissTask = task
        }
    }

    private func shouldStoreNotice(message: String) -> Bool {
        !message.hasSuffix("...")
    }

    private func appendNotice(title: String, message: String, tone: CareTapTone) {
        if let existingIndex = noticeInbox.firstIndex(where: { $0.title == title && $0.message == message }) {
            noticeInbox[existingIndex].isUnread = !isPresentingNotificationCenter
            return
        }

        noticeInbox.insert(
            CareTapNoticeItem(
                title: title,
                message: message,
                tone: tone,
                isUnread: !isPresentingNotificationCenter
            ),
            at: 0
        )
    }

    private func markAllNoticesRead() {
        noticeInbox = noticeInbox.map { notice in
            var updated = notice
            updated.isUnread = false
            return updated
        }
    }

    private func syncInBackground() async {
        _ = try? await services.recordStore.syncPendingChanges()
    }
}

extension CareTapAppStore {
    func completeCaregiverOnboardingWithoutInvite() async {
        persistedState.hasCompletedCaregiverSetup = true
        persist()
        do {
            try await refreshCaregiverExperience()
            route = .caregiver
        } catch {
            route = .caregiver
        }
    }

    func handleCaregiverWelcomeSecondaryAction() async {
        if inviteCode.isEmpty {
            await completeCaregiverOnboardingWithoutInvite()
        } else {
            await declineInviteCode()
        }
    }

    func acceptInviteCode() async {
        guard let user = currentUser else {
            errorMessage = "Sign in first so TapCare can link this support account."
            return
        }

        guard !inviteCode.isEmpty else {
            errorMessage = "Enter an invite code first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            let redemption = try await services.recordStore.redeemInvitation(
                token: inviteCode,
                caregiverUserID: user.id
            )

            persistedState.hasCompletedCaregiverSetup = true
            persistedState.activeCareProfileID = redemption.careProfileID
            persist()

            activeCareProfile = try await services.recordStore.fetchCareProfile(id: redemption.careProfileID)
            inviteCode = ""
            try await refreshCaregiverExperience()
            route = .caregiver
        } catch {
            errorMessage = "CareTap couldn’t accept that invite code. Make sure it hasn’t expired and try again."
        }
    }

    func declineInviteCode() async {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            await completeCaregiverOnboardingWithoutInvite()
            return
        }

        do {
            try await services.recordStore.declineInvitation(token: trimmedCode)
            infoMessage = "That invite was declined. TapCare can still continue in family support mode without linking yet."
            inviteCode = ""
            await completeCaregiverOnboardingWithoutInvite()
        } catch {
            errorMessage = "CareTap couldn’t decline that invite code yet."
        }
    }

    func handleCaregiverQuickAction(_ action: QuickActionState) async {
        switch action.kind ?? legacyQuickActionKind(for: action.title) {
        case .reviewMedications:
            selectCaregiverWorkspaceSection(.people)
        case .call:
            #if canImport(UIKit)
            if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(URL(string: "tel://")!)
            } else {
                infoMessage = "Open Phone to place a call to your loved one."
            }
            #endif
        case .message:
            #if canImport(UIKit)
            if let url = URL(string: "sms://"), UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(URL(string: "sms://")!)
            } else {
                infoMessage = "Open Messages to send a text to your loved one."
            }
            #endif
        case .reviewTimeline:
            selectCaregiverWorkspaceSection(.history)
        case .openSharing:
            selectCaregiverWorkspaceSection(.people)
        case .resolveDose:
            await caregiverLogDoseOnBehalf()
        case nil:
            break
        }
    }

    private func caregiverLogDoseOnBehalf() async {
        guard let currentOcc = occurrences.first(where: { !$0.isResolved }),
              let medication = medications.first(where: { $0.id == currentOcc.medicationID }) else {
            infoMessage = "There are no open doses to log right now."
            return
        }

        do {
            let result = try await services.doseLogging.logDose(
                for: currentOcc,
                request: DoseLoggingRequest(
                    actorUserID: currentUser?.id,
                    source: .caregiverLogged,
                    action: .confirmTaken,
                    loggedAt: .now,
                    note: "Logged by caregiver",
                    nfcTagID: nil
                )
            )
            try await handleDoseLoggingResult(
                result,
                acceptedMessage: "\(medication.displayTitle) logged on behalf of your loved one."
            )
        } catch {
            errorMessage = "CareTap couldn't log that dose yet."
        }
    }

    func revokeInvitation(_ invitationID: UUID) async {
        guard let invitation = invitations.first(where: { $0.id == invitationID }) else {
            return
        }

        do {
            _ = try await services.recordStore.upsertInvitation(
                Invitation(
                    id: invitation.id,
                    careProfileID: invitation.careProfileID,
                    createdByUserID: invitation.createdByUserID,
                    recipientDisplayName: invitation.recipientDisplayName,
                    recipientContact: invitation.recipientContact,
                    offeredRole: invitation.offeredRole,
                    relationshipLabel: invitation.relationshipLabel,
                    status: .revoked,
                    inviteToken: invitation.inviteToken,
                    expiresAt: invitation.expiresAt,
                    acceptedAt: invitation.acceptedAt,
                    createdAt: invitation.createdAt,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
            )
            try await refreshRoleExperience()
        } catch {
            errorMessage = "CareTap couldn’t revoke that invitation yet."
        }
    }

    func revokeRelationship(_ relationshipID: UUID) async {
        guard let relationship = relationships.first(where: { $0.id == relationshipID }) else {
            return
        }

        do {
            _ = try await services.recordStore.upsertCareRelationship(
                CareRelationship(
                    id: relationship.id,
                    caregiverUserID: relationship.caregiverUserID,
                    careProfileID: relationship.careProfileID,
                    label: relationship.label,
                    status: .revoked,
                    permissions: relationship.permissions,
                    receivesMissedDoseAlerts: relationship.receivesMissedDoseAlerts,
                    receivesRefillAlerts: relationship.receivesRefillAlerts,
                    createdAt: relationship.createdAt,
                    updatedAt: .now,
                    acceptedAt: relationship.acceptedAt,
                    syncState: .pendingUpload
                )
            )
            try await refreshRoleExperience()
        } catch {
            errorMessage = "CareTap couldn’t update that shared-care relationship yet."
        }
    }

    func updateRelationshipAlerts(
        _ relationshipID: UUID,
        receivesMissedDoseAlerts: Bool?,
        receivesRefillAlerts: Bool?
    ) async {
        guard let relationship = relationships.first(where: { $0.id == relationshipID }) else {
            return
        }

        do {
            _ = try await services.recordStore.upsertCareRelationship(
                CareRelationship(
                    id: relationship.id,
                    caregiverUserID: relationship.caregiverUserID,
                    careProfileID: relationship.careProfileID,
                    label: relationship.label,
                    status: relationship.status,
                    permissions: relationship.permissions,
                    receivesMissedDoseAlerts: receivesMissedDoseAlerts ?? relationship.receivesMissedDoseAlerts,
                    receivesRefillAlerts: receivesRefillAlerts ?? relationship.receivesRefillAlerts,
                    createdAt: relationship.createdAt,
                    updatedAt: .now,
                    acceptedAt: relationship.acceptedAt,
                    syncState: .pendingUpload
                )
            )
            try await refreshRoleExperience()
        } catch {
            errorMessage = "CareTap couldn’t update those shared-care alerts yet."
        }
    }

    func handleSettingsRowTap(_ row: SettingsRowState) async {
        switch row.actionKind ?? legacySettingsActionKind(for: row.title) {
        case .accountInfo:
            presentProfileEditor()
        case .openPremium:
            presentPremiumPaywall()
        case .currentRole, .manageRole:
            infoMessage = "This phone is currently in \(selectedRole == .caregiver ? "support" : "personal") view. To switch cleanly, sign out and choose the other setup path."
        case .deleteAccount:
            isPresentingDeleteAccountConfirmation = true
        case .manageReminderLeadTime:
            guard let profile = activeCareProfile,
                  let user = currentUser else {
                return
            }

            do {
                let currentPreference = try await services.recordStore.preference(for: user.id, careProfileID: profile.id)
                let existingLeadTime = currentPreference?.leadTimeMinutes ?? 0
                let nextLeadTime: Int

                switch existingLeadTime {
                case 0:
                    nextLeadTime = 10
                case 10:
                    nextLeadTime = 20
                case 20:
                    nextLeadTime = 30
                default:
                    nextLeadTime = 0
                }

                let preference = ReminderPreference(
                    id: currentPreference?.id ?? UUID(),
                    userID: user.id,
                    careProfileID: profile.id,
                    channels: currentPreference?.channels ?? [.localNotification, .liveActivity],
                    leadTimeMinutes: nextLeadTime,
                    followUpAfterMinutes: currentPreference?.followUpAfterMinutes ?? 20,
                    maxFollowUps: currentPreference?.maxFollowUps ?? 1,
                    quietHours: currentPreference?.quietHours,
                    enablesLiveActivity: currentPreference?.enablesLiveActivity ?? true,
                    createdAt: currentPreference?.createdAt ?? .now,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
                _ = try await services.recordStore.upsertReminderPreference(preference)
                try await refreshRoleExperience()
            } catch {
                errorMessage = "CareTap couldn’t update the reminder lead time yet."
            }
        case .sharedAccess, .linkCaregiver:
            if relationships.isEmpty {
                infoMessage = "No one is linked yet. Use the invite code flow to create the first shared connection."
            } else {
                infoMessage = relationships
                    .map {
                        let label = $0.label.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                        return "\(label): \($0.status.rawValue.capitalized)"
                    }
                    .joined(separator: "\n")
            }
        case .pendingInvitations, .enterInviteCode:
            if selectedRole == .patient {
                await createCaregiverInvite()
            } else {
                route = .onboarding(.caregiverWelcome)
            }
        case .rePairCurrentTag, .rePairCurrentMedication:
            guard !medications.isEmpty else {
                startPatientAddMedicationFlow()
                infoMessage = "Add the first item before pairing a tag."
                return
            }
            if !persistedState.hasCompletedPatientSetup {
                persistedState.patientSetupStep = .tapSetup
            }
            let targetMedication = nfcPairingTargetMedication() ?? medications[0]
            presentNFCPairing(for: targetMedication, entryContext: .settings)
            persistedState.selectedDestination = .settings
            persist()
            route = .onboarding(.patientSetup(.tapSetup))
        case .testCurrentTag:
            guard !medications.isEmpty else {
                infoMessage = "Add the first item before testing a tag."
                return
            }
            do {
                let result = try await services.nfcTags.scanTag()
                infoMessage = "Tag works! Recognized \(result.tag.label)."
            } catch {
                let targetMedication = nfcPairingTargetMedication() ?? medications[0]
                presentNFCPairing(for: targetMedication, entryContext: .settings)
                persistedState.selectedDestination = .settings
                persist()
                infoMessage = "That tag needs pairing first. Let's set it up."
                route = .onboarding(.patientSetup(.tapSetup))
            }
        case .openTapKitShop:
            presentTapKitShop()
        case .exportSupportPackage, .exportData:
            await exportSupportPackage()
        case .showSupportGuide, .shareDiagnostics:
            infoMessage = "CareTap treats NFC taps, manual patient confirmation, caregiver logs, and later corrections as distinct dose log sources. Reminder dismissals never count as taken."
        case .signOut:
            await signOut()
        case .manageQuietHours:
            await toggleQuietHours()
        case .remindersToggle, nil:
            break
        }
    }

    func handleSettingsToggle(_ row: SettingsRowState, value: Bool) async {
        guard let profile = activeCareProfile,
              let user = currentUser else {
            return
        }

        do {
            let currentPreference = try await services.recordStore.preference(for: user.id, careProfileID: profile.id)
            switch row.actionKind ?? legacySettingsActionKind(for: row.title) {
            case .remindersToggle:
                let preference = ReminderPreference(
                    id: currentPreference?.id ?? UUID(),
                    userID: user.id,
                    careProfileID: profile.id,
                    channels: value ? [.localNotification, .liveActivity] : [.liveActivity],
                    leadTimeMinutes: currentPreference?.leadTimeMinutes ?? 0,
                    followUpAfterMinutes: currentPreference?.followUpAfterMinutes ?? 20,
                    maxFollowUps: currentPreference?.maxFollowUps ?? 1,
                    quietHours: currentPreference?.quietHours,
                    enablesLiveActivity: true,
                    createdAt: currentPreference?.createdAt ?? .now,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )
                _ = try await services.recordStore.upsertReminderPreference(preference)
                if !value {
                    for occurrence in occurrences where !occurrence.isResolved {
                        try? await services.reminders.cancelReminders(for: occurrence.id)
                    }
                }
                try await refreshRoleExperience()
            default:
                break
            }
        } catch {
            errorMessage = "CareTap couldn’t update that setting yet."
        }
    }

    private func legacyPatientSecondaryActionKind(for title: String) -> PatientSecondaryActionKind? {
        switch title {
        case "Manual":
            return .manualCheckIn
        case "Snooze":
            return .snooze
        case "Skip":
            return .skip
        case "History", "Timeline":
            return .openHistory
        case "Meds":
            return .openItems
        case "Settings":
            return .openSettings
        default:
            return nil
        }
    }

    private func legacyQuickActionKind(for title: String) -> CareTapQuickActionKind? {
        switch title {
        case "Call", "Call Arthur":
            return .call
        case "Message":
            return .message
        case "Review Meds":
            return .reviewMedications
        default:
            return nil
        }
    }

    private func legacySettingsActionKind(for title: String) -> SettingsActionKind? {
        switch title {
        case "Current role":
            return .currentRole
        case "TapCare Premium", "CareTap Premium", "Premium":
            return .openPremium
        case "Lead time":
            return .manageReminderLeadTime
        case "Shared access":
            return .sharedAccess
        case "Pending invitations", "Invite caregiver":
            return .pendingInvitations
        case "Pair or replace a tag", "Re-pair medication tag", "Re-pair current tag":
            return .rePairCurrentTag
        case "Tap Kit", "Order NFC stickers", "Buy NFC stickers":
            return .openTapKitShop
        case "Delete account":
            return .deleteAccount
        case "Test current tag", "Test a bottle tap":
            return .testCurrentTag
        case "Export support package", "Export medication history":
            return .exportSupportPackage
        case "How confirmation works", "How TapCare confirms doses", "How CareTap confirms doses", "Help with reminders", "Report a pairing problem":
            return .showSupportGuide
        case "Sign out":
            return .signOut
        case "Reminders", "Reminder status", "Missed dose alerts":
            return .remindersToggle
        default:
            return nil
        }
    }

    private func createCaregiverInvite() async {
        guard let profile = activeCareProfile,
              let user = currentUser else {
            errorMessage = "Finish the first setup before sharing access."
            return
        }

        do {
            let code = String(UUID().uuidString.prefix(8)).uppercased()
            let invitation = Invitation(
                id: UUID(),
                careProfileID: profile.id,
                createdByUserID: user.id,
                recipientDisplayName: nil,
                recipientContact: "invite-code:\(code)",
                offeredRole: .caregiver,
                relationshipLabel: .friend,
                status: .pending,
                inviteToken: code,
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now.addingTimeInterval(7 * 24 * 60 * 60),
                acceptedAt: nil,
                createdAt: .now,
                updatedAt: .now,
                syncState: .pendingUpload
            )
            let stored = try await services.recordStore.upsertInvitation(invitation)
            invitations.insert(stored, at: 0)
            caregiverInvitationRows = CareTapStateBuilder.caregiverInvitationRows(invitations)
            infoMessage = "Invite code: \(stored.inviteToken)"
            await syncInBackground()
        } catch {
            errorMessage = "CareTap couldn’t create a caregiver invite yet."
        }
    }

    private func refreshCaregiverExperience() async throws {
        guard let user = currentUser else {
            throw CareTapServiceError.missingRecord
        }

        relationships = try await services.recordStore.relationships(for: user.id)
        if let explicitProfileID = persistedState.activeCareProfileID {
            activeCareProfile = try await services.recordStore.fetchCareProfile(id: explicitProfileID)
        }

        if activeCareProfile == nil,
           let firstRelationship = relationships.first {
            activeCareProfile = try await services.recordStore.fetchCareProfile(id: firstRelationship.careProfileID)
            persistedState.activeCareProfileID = activeCareProfile?.id
            persist()
        }

        guard let profile = activeCareProfile else {
            linkedCareProfiles = []
            activeProfileRelationships = []
            medications = []
            occurrences = []
            doseLogsByOccurrenceID = [:]
            caregiverRelationshipRows = []
            caregiverInvitationRows = []
            patientMedicationRows = []
            patientHistoryRows = []
            settingsState = CareTapStateBuilder.settingsState(
                user: user,
                profile: PersonProfile(id: user.id, displayName: user.displayName, initials: user.initials, style: .caregiver),
                selectedRole: .caregiver,
                reminderPreference: nil,
                relationships: [],
                invitations: [],
                isNotificationAuthorized: settingsNotificationAuthorized,
                syncSnapshot: await services.recordStore.syncSnapshot()
            )
            route = .caregiver
            return
        }

        var profileMap: [UUID: CareProfile] = [profile.id: profile]
        for relationship in relationships where profileMap[relationship.careProfileID] == nil {
            if let relatedProfile = try await services.recordStore.fetchCareProfile(id: relationship.careProfileID) {
                profileMap[relatedProfile.id] = relatedProfile
            }
        }
        linkedCareProfiles = profileMap.values
            .sorted { lhs, rhs in
                if lhs.id == profile.id { return true }
                if rhs.id == profile.id { return false }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
        activeProfileRelationships = try await services.recordStore.relationships(forCareProfileID: profile.id)

        medications = try await services.recordStore.medications(for: profile.id)
        var nextRules: [UUID: [ScheduleRule]] = [:]
        for medication in medications {
            nextRules[medication.id] = try await services.recordStore.rules(for: medication.id)
        }
        rulesByMedicationID = nextRules

        let interval = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now,
            end: Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now.addingTimeInterval(14 * 24 * 60 * 60)
        )
        occurrences = try await services.recordStore.occurrences(for: profile.id, within: interval)
        occurrences = occurrences.map(dynamicOccurrence).sorted { $0.scheduledAt < $1.scheduledAt }
        doseLogsByOccurrenceID = try await loadLogs(for: occurrences)
        invitations = try await services.recordStore.invitations(for: profile.id)

        refillStatesByMedicationID = [:]
        for medication in medications {
            let state = services.refillEstimator.estimateRefillState(
                for: medication,
                rules: nextRules[medication.id] ?? [],
                asOf: .now
            )
            let storedState = try await services.recordStore.upsertRefillState(state)
            refillStatesByMedicationID[medication.id] = storedState
        }

        caregiverHomeState = CareTapStateBuilder.caregiverHomeState(
            caregiver: user,
            lovedOne: profile,
            linkedProfiles: linkedCareProfiles,
            activeProfileRelationships: activeProfileRelationships,
            medications: medications,
            occurrences: occurrences,
            refillStates: Array(refillStatesByMedicationID.values),
            destination: persistedState.selectedDestination
        )

        caregiverRelationshipRows = CareTapStateBuilder.caregiverRelationshipRows(
            relationships: relationships,
            profiles: profileMap,
            selectedCareProfileID: profile.id
        )
        caregiverInvitationRows = CareTapStateBuilder.caregiverInvitationRows(invitations)
        patientMedicationRows = CareTapStateBuilder.patientMedicationRows(
            medications: medications,
            occurrences: occurrences,
            refillStates: refillStatesByMedicationID,
            logsByOccurrenceID: doseLogsByOccurrenceID,
            relationships: relationships
        )
        patientHistoryRows = CareTapStateBuilder.patientHistoryRows(
            occurrences: occurrences,
            medications: Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) }),
            logsByOccurrenceID: doseLogsByOccurrenceID
        )

        settingsState = CareTapStateBuilder.settingsState(
            user: user,
            profile: PersonProfile(id: user.id, displayName: user.displayName, initials: user.initials, style: .caregiver),
            selectedRole: .caregiver,
            reminderPreference: nil,
            relationships: relationships,
            invitations: invitations,
            isNotificationAuthorized: settingsNotificationAuthorized,
            syncSnapshot: await services.recordStore.syncSnapshot()
        )

        route = .caregiver
        await syncInBackground()
    }

    private func toggleQuietHours() async {
        guard let profile = activeCareProfile,
              let user = currentUser else { return }

        do {
            let current = try await services.recordStore.preference(for: user.id, careProfileID: profile.id)
            let isCurrentlyEnabled = current?.quietHours != nil
            let preference = ReminderPreference(
                id: current?.id ?? UUID(),
                userID: user.id,
                careProfileID: profile.id,
                channels: current?.channels ?? [.localNotification, .liveActivity],
                leadTimeMinutes: current?.leadTimeMinutes ?? 0,
                followUpAfterMinutes: current?.followUpAfterMinutes ?? 20,
                maxFollowUps: current?.maxFollowUps ?? 1,
                quietHours: isCurrentlyEnabled
                    ? nil
                    : QuietHours(startHour: 22, startMinute: 0, endHour: 7, endMinute: 0),
                enablesLiveActivity: current?.enablesLiveActivity ?? true,
                createdAt: current?.createdAt ?? .now,
                updatedAt: .now,
                syncState: .pendingUpload
            )
            _ = try await services.recordStore.upsertReminderPreference(preference)
            infoMessage = isCurrentlyEnabled
                ? "Quiet hours turned off. Reminders can arrive anytime."
                : "Quiet hours on. No reminders between 10 PM and 7 AM."
            try await refreshRoleExperience()
        } catch {
            errorMessage = "CareTap couldn't update quiet hours yet."
        }
    }

    private func exportSupportPackage() async {
        struct SupportExport: Codable {
            let exportedAt: Date
            let user: User?
            let careProfile: CareProfile?
            let medications: [Medication]
            let occurrences: [DoseOccurrence]
            let relationships: [CareRelationship]
            let invitations: [Invitation]
        }

        do {
            let payload = SupportExport(
                exportedAt: .now,
                user: currentUser,
                careProfile: activeCareProfile,
                medications: medications,
                occurrences: occurrences,
                relationships: relationships,
                invitations: invitations
            )
            let data = try CareTapSupabaseJSON.encoder.encode(payload)
            let fileURL = FileManager.default.temporaryDirectory.appending(path: "CareTap-Support-\(UUID().uuidString).json")
            try data.write(to: fileURL, options: .atomic)
            exportURL = fileURL
        } catch {
            errorMessage = "TapCare couldn’t prepare the support package yet."
        }
    }

    private func refreshRoleExperience() async throws {
        if selectedRole == .caregiver {
            try await refreshCaregiverExperience()
        } else {
            try await refreshPatientExperience()
        }
    }

    private func refreshPremiumState() async {
        applyPremiumSnapshot(await services.premiumSubscriptions.snapshot())
    }

    private func refreshPremiumStateInBackground() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await services.premiumSubscriptions.prepare()
            await refreshPremiumState()
        }
    }

    private func applyPremiumSnapshot(_ snapshot: CareTapPremiumSnapshot) {
        premiumSnapshot = snapshot
        premiumViewState = CareTapPremiumViewState.from(
            snapshot: snapshot,
            isPurchasing: premiumViewState.isPurchasing
        )
    }

    private func setPremiumPurchasing(_ isPurchasing: Bool) {
        premiumViewState = CareTapPremiumViewState.from(
            snapshot: premiumSnapshot,
            isPurchasing: isPurchasing
        )
    }

    private func refreshPremiumDependentState() async {
        guard currentUser != nil else { return }

        do {
            try await refreshRoleExperience()
        } catch {
            errorMessage = "TapCare Premium changed, but the app couldn’t refresh every screen yet."
        }
    }

    private var currentDisplayName: String {
        if let activeCareProfile,
           selectedRole == .patient {
            return activeCareProfile.preferredName ?? activeCareProfile.displayName
        }

        return currentUser?.displayName ?? ""
    }

    private static func preferredName(from displayName: String) -> String {
        displayName
            .split(separator: " ")
            .first
            .map(String.init) ?? displayName
    }

    private static func initials(from displayName: String) -> String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)

        let initials = parts
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()

        return initials.isEmpty ? "CT" : initials
    }
}
