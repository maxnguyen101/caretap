import XCTest
@testable import CareTap

@MainActor
final class CareTapAppFlowTests: XCTestCase {
    private final class InMemoryAppStatePersistence: CareTapAppStatePersisting {
        var state: CareTapPersistedAppState

        init(state: CareTapPersistedAppState = .default()) {
            self.state = state
        }

        func load() -> CareTapPersistedAppState {
            state
        }

        func save(_ state: CareTapPersistedAppState) {
            self.state = state
        }

        func clear() {
            state = .default()
        }
    }

    private final class TestAuthCoordinator: AppleSignInAuthCoordinating, @unchecked Sendable {
        var snapshot: AuthenticationSessionSnapshot

        init(user: User?) {
            snapshot = AuthenticationSessionSnapshot(
                state: user == nil ? .signedOut : .linkedForSync,
                user: user,
                lastUpdatedAt: .now
            )
        }

        func sessionSnapshot() async -> AuthenticationSessionSnapshot {
            snapshot
        }

        func signInWithApple(with payload: AppleIdentityTokenPayload, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
            snapshot
        }

        func signUpWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
            snapshot
        }

        func signInWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
            snapshot
        }

        func signOut() async {
            snapshot = AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
        }

        func deleteAccount() async throws {
            snapshot = AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
        }
    }

    private struct NoOpWidgetSnapshotStore: CareTapWidgetSnapshotStoring {
        func loadBestNextStep() throws -> BestNextStepSnapshot? { nil }
        func loadTodaySnapshot() throws -> TodaySnapshotWidgetState? { nil }
        func save(bestNextStep: BestNextStepSnapshot, todaySnapshot: TodaySnapshotWidgetState) throws {}
    }

    private struct NoOpLiveActivityManager: CareTapDoseActivityManaging {
        func updateCurrentDoseActivity(profileName: String, medication: Medication, occurrence: DoseOccurrence) async {}
        func endAllActivities() async {}
    }

    private final class CapturingLiveActivityManager: CareTapDoseActivityManaging, @unchecked Sendable {
        private(set) var updatedOccurrenceIDs: [UUID] = []
        private(set) var endAllCallCount = 0

        func updateCurrentDoseActivity(profileName: String, medication: Medication, occurrence: DoseOccurrence) async {
            updatedOccurrenceIDs.append(occurrence.id)
        }

        func endAllActivities() async {
            endAllCallCount += 1
        }
    }

    private struct NoOpReminderScheduler: ReminderScheduling {
        func scheduleReminders(
            for occurrence: DoseOccurrence,
            medication: Medication,
            preference: ReminderPreference
        ) async throws -> [ReminderSchedulePlan] {
            []
        }

        func cancelReminders(for occurrenceID: UUID) async throws {}
    }

    private func makePatientUser() -> User {
        User(
            id: UUID(),
            authUserID: UUID(),
            appleSubject: "patient-subject",
            preferredRole: .patient,
            displayName: "Mia Patient",
            initials: "MP",
            timezoneIdentifier: "America/Los_Angeles",
            localeIdentifier: "en_US",
            isSignInWithAppleLinked: true,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )
    }

    private func makePatientProfile(for user: User) -> CareProfile {
        CareProfile(
            id: UUID(),
            createdByUserID: user.id,
            patientUserID: user.id,
            displayName: user.displayName,
            preferredName: "Mia",
            initials: user.initials,
            avatarStyle: .patient,
            timezoneIdentifier: user.timezoneIdentifier,
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
    }

    private func makeCaregiverUser() -> User {
        User(
            id: UUID(),
            authUserID: UUID(),
            appleSubject: "caregiver-subject",
            preferredRole: .caregiver,
            displayName: "Chris Caregiver",
            initials: "CC",
            timezoneIdentifier: "America/Los_Angeles",
            localeIdentifier: "en_US",
            isSignInWithAppleLinked: true,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )
    }

    private func makeServices(
        user: User?,
        seedProfile: CareProfile? = nil,
        seedInvitation: Invitation? = nil
    ) async throws -> CareTapServiceContainer {
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)

        if let user {
            _ = try await recordStore.upsertUser(user)
        }

        if let seedProfile {
            _ = try await recordStore.upsertCareProfile(seedProfile)
        }

        if let seedInvitation {
            _ = try await recordStore.upsertInvitation(seedInvitation)
        }

        return CareTapServiceContainer(
            homeSnapshots: PreviewHomeSnapshotService(),
            recordStore: recordStore,
            nfcTags: StubNFCTagService(),
            doseLogging: RepositoryBackedDoseLoggingService(recordStore: recordStore),
            reminders: NoOpReminderScheduler(),
            auth: TestAuthCoordinator(user: user),
            backend: backend,
            caregiverRelationships: RepositoryBackedCaregiverRelationshipService(
                relationshipsRepository: backend.localRepositories.careRelationships,
                invitationsRepository: backend.localRepositories.invitations
            ),
            scheduleGenerator: CareTapMedicationScheduleGenerator(),
            refillEstimator: CareTapRefillEstimator(),
            premiumSubscriptions: StubPremiumSubscriptionService(),
            widgetSnapshots: NoOpWidgetSnapshotStore(),
            liveActivities: NoOpLiveActivityManager()
        )
    }

    private func makeUnseededServices(
        user: User?,
        seedProfile: CareProfile? = nil,
        seedMedications: [Medication] = [],
        seedRules: [ScheduleRule] = [],
        seedOccurrences: [DoseOccurrence] = [],
        liveActivities: CareTapDoseActivityManaging = NoOpLiveActivityManager()
    ) async throws -> (services: CareTapServiceContainer, recordStore: RepositoryBackedCareTapRecordStore) {
        let localTransport = InMemorySupabaseTransport()
        let remoteTransport = InMemorySupabaseTransport()
        let remoteGateway = SupabaseSyncGatewayClient(repositories: CareTapSupabaseRepositorySet(transport: remoteTransport))
        let syncEngine = try OfflineFirstSyncEngine(localTransport: localTransport, remoteGateway: remoteGateway)
        let backend = SupabaseBackendRepository(syncEngine: syncEngine)
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)

        if let user {
            _ = try await recordStore.upsertUser(user)
        }

        if let seedProfile {
            _ = try await recordStore.upsertCareProfile(seedProfile)
        }

        for medication in seedMedications {
            _ = try await recordStore.upsertMedication(medication)
        }

        for rule in seedRules {
            _ = try await recordStore.upsertScheduleRule(rule)
        }

        for occurrence in seedOccurrences {
            _ = try await recordStore.upsertDoseOccurrence(occurrence)
        }

        let defaultsSuite = "CareTapAppFlowTests.\(UUID().uuidString)"
        let storage = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        storage.removePersistentDomain(forName: defaultsSuite)
        addTeardownBlock {
            storage.removePersistentDomain(forName: defaultsSuite)
        }

        return (
            CareTapServiceContainer(
                homeSnapshots: PreviewHomeSnapshotService(),
                recordStore: recordStore,
                nfcTags: SimulatorNFCTagService(recordStore: recordStore, storage: storage),
                doseLogging: RepositoryBackedDoseLoggingService(recordStore: recordStore),
                reminders: NoOpReminderScheduler(),
                auth: TestAuthCoordinator(user: user),
                backend: backend,
                caregiverRelationships: RepositoryBackedCaregiverRelationshipService(
                    relationshipsRepository: backend.localRepositories.careRelationships,
                    invitationsRepository: backend.localRepositories.invitations
                ),
                scheduleGenerator: CareTapMedicationScheduleGenerator(),
                refillEstimator: CareTapRefillEstimator(),
                premiumSubscriptions: StubPremiumSubscriptionService(),
                widgetSnapshots: NoOpWidgetSnapshotStore(),
                liveActivities: liveActivities
            ),
            recordStore
        )
    }

    private func makeMedication(
        id: UUID = UUID(),
        profileID: UUID,
        name: String,
        createdAt: Date
    ) -> Medication {
        Medication(
            id: id,
            careProfileID: profileID,
            nfcTagID: nil,
            name: name,
            dosage: "10 mg",
            doseQuantity: 1,
            doseQuantityUnit: "tablet",
            instructions: nil,
            bottleLabel: "\(name) Bottle",
            bottlePhotoLocalPath: nil,
            form: .bottle,
            scheduleSummary: "Every day",
            isActive: true,
            supplyCount: 30,
            createdAt: createdAt,
            updatedAt: createdAt,
            archivedAt: nil,
            syncState: .localOnly
        )
    }

    private func makeRule(
        id: UUID = UUID(),
        medicationID: UUID,
        profileID: UUID,
        at date: Date
    ) -> ScheduleRule {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ScheduleRule(
            id: id,
            medicationID: medicationID,
            careProfileID: profileID,
            type: .daily,
            timezoneIdentifier: "America/Los_Angeles",
            startsOn: Calendar.current.startOfDay(for: date),
            endsOn: nil,
            daysOfWeek: ScheduleWeekday.allCases,
            timesOfDay: [
                ScheduleTimeOfDay(
                    id: UUID(),
                    hour: components.hour ?? 8,
                    minute: components.minute ?? 0,
                    label: "Dose"
                )
            ],
            intervalHours: nil,
            gracePeriodMinutes: 60,
            snoozeDurationMinutes: 20,
            isActive: true,
            createdAt: date,
            updatedAt: date,
            syncState: .localOnly
        )
    }

    private func makeOccurrence(
        id: UUID = UUID(),
        medicationID: UUID,
        profileID: UUID,
        ruleID: UUID,
        scheduledAt: Date,
        status: DoseOccurrenceStatus
    ) -> DoseOccurrence {
        DoseOccurrence(
            id: id,
            careProfileID: profileID,
            medicationID: medicationID,
            scheduleRuleID: ruleID,
            scheduledAt: scheduledAt,
            windowOpensAt: scheduledAt.addingTimeInterval(-15 * 60),
            windowClosesAt: scheduledAt.addingTimeInterval(60 * 60),
            snoozedUntil: nil,
            status: status,
            reminderState: .scheduled,
            flags: [],
            resolvedByLogID: nil,
            resolvedAt: nil,
            createdAt: scheduledAt,
            updatedAt: scheduledAt,
            syncState: .localOnly
        )
    }

    func testSignedOutStartRoutesToRoleSelection() async throws {
        let store = CareTapAppStore(
            services: try await makeServices(user: nil),
            statePersistence: InMemoryAppStatePersistence()
        )

        await store.start()

        XCTAssertEqual(store.route, .onboarding(.roleSelection))
        XCTAssertNil(store.selectedRole)
    }

    func testPatientWithIncompleteSetupResumesSavedStep() async throws {
        let user = makePatientUser()
        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.patientSetupStep = .routine
        let store = CareTapAppStore(
            services: try await makeServices(user: user),
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        XCTAssertEqual(store.route, .onboarding(.patientSetup(.routine)))
        XCTAssertEqual(store.selectedRole, .patient)
    }

    func testCompletedPatientSetupRoutesIntoPatientExperience() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true
        let store = CareTapAppStore(
            services: try await makeServices(user: user, seedProfile: profile),
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        XCTAssertEqual(store.route, .patient)
        XCTAssertEqual(store.selectedRole, .patient)
    }

    func testCaregiverWithoutCompletedSetupRoutesToWelcome() async throws {
        let user = makeCaregiverUser()
        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .caregiver
        let store = CareTapAppStore(
            services: try await makeServices(user: user),
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        XCTAssertEqual(store.route, .onboarding(.caregiverWelcome))
        XCTAssertEqual(store.selectedRole, .caregiver)
    }

    func testAcceptInviteCodeLinksCaregiverAndRoutesToHome() async throws {
        let user = makeCaregiverUser()
        let profile = CareProfile(
            id: UUID(),
            createdByUserID: UUID(),
            patientUserID: nil,
            displayName: "Nora Patient",
            preferredName: "Nora",
            initials: "NP",
            avatarStyle: .lovedOne,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let invitation = Invitation(
            id: UUID(),
            careProfileID: profile.id,
            createdByUserID: profile.createdByUserID,
            recipientDisplayName: "Chris Caregiver",
            recipientContact: "invite-code:FLOWTEST",
            offeredRole: .caregiver,
            relationshipLabel: .friend,
            status: .pending,
            inviteToken: "FLOWTEST",
            expiresAt: Date().addingTimeInterval(60 * 60),
            acceptedAt: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .caregiver
        let store = CareTapAppStore(
            services: try await makeServices(
                user: user,
                seedProfile: profile,
                seedInvitation: invitation
            ),
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        store.setInviteCode(invitation.inviteToken)
        await store.acceptInviteCode()

        XCTAssertEqual(store.route, .caregiver)
        XCTAssertEqual(store.caregiverRelationshipRows.count, 1)
        XCTAssertTrue(store.inviteCode.isEmpty)
    }

    func testDeclineInviteCodeRoutesCaregiverToHomeWithoutLinking() async throws {
        let user = makeCaregiverUser()
        let profile = CareProfile(
            id: UUID(),
            createdByUserID: UUID(),
            patientUserID: nil,
            displayName: "Nora Patient",
            preferredName: "Nora",
            initials: "NP",
            avatarStyle: .lovedOne,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let invitation = Invitation(
            id: UUID(),
            careProfileID: profile.id,
            createdByUserID: profile.createdByUserID,
            recipientDisplayName: "Chris Caregiver",
            recipientContact: "invite-code:DECLINE01",
            offeredRole: .caregiver,
            relationshipLabel: .friend,
            status: .pending,
            inviteToken: "DECLINE01",
            expiresAt: Date().addingTimeInterval(60 * 60),
            acceptedAt: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .caregiver

        let services = try await makeServices(
            user: user,
            seedProfile: profile,
            seedInvitation: invitation
        )
        let store = CareTapAppStore(
            services: services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        store.setInviteCode(invitation.inviteToken)
        await store.declineInviteCode()

        let invitations = try await services.recordStore.invitations(for: profile.id)

        XCTAssertEqual(store.route, .caregiver)
        XCTAssertTrue(store.caregiverRelationshipRows.isEmpty)
        XCTAssertTrue(store.inviteCode.isEmpty)
        XCTAssertEqual(store.infoMessage, "That invite was declined. TapCare can still continue in family support mode without linking yet.")
        XCTAssertEqual(invitations.first?.status, .declined)
    }

    func testSettingsRePairTargetsCurrentMedicationInsteadOfLastMedication() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let primaryMedication = makeMedication(profileID: profile.id, name: "Lisinopril", createdAt: now.addingTimeInterval(-120))
        let secondaryMedication = makeMedication(profileID: profile.id, name: "Metformin", createdAt: now.addingTimeInterval(-60))
        let primaryRule = makeRule(medicationID: primaryMedication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let secondaryRule = makeRule(medicationID: secondaryMedication.id, profileID: profile.id, at: now.addingTimeInterval(2 * 60 * 60))
        let primaryOccurrence = makeOccurrence(
            medicationID: primaryMedication.id,
            profileID: profile.id,
            ruleID: primaryRule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )
        let secondaryOccurrence = makeOccurrence(
            medicationID: secondaryMedication.id,
            profileID: profile.id,
            ruleID: secondaryRule.id,
            scheduledAt: now.addingTimeInterval(2 * 60 * 60),
            status: .scheduled
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [primaryMedication, secondaryMedication],
            seedRules: [primaryRule, secondaryRule],
            seedOccurrences: [primaryOccurrence, secondaryOccurrence]
        )
        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handleSettingsRowTap(
            SettingsRowState(
                symbolName: "dot.radiowaves.left.and.right",
                tone: .sage,
                title: "Reconnect this tag",
                accessory: .chevron,
                actionKind: .rePairCurrentTag
            )
        )
        await store.handleNFCPairingPrimaryAction()

        let storedMedications = try await dependencies.recordStore.medications(for: profile.id)
        let updatedPrimaryMedication = try XCTUnwrap(storedMedications.first(where: { $0.id == primaryMedication.id }))
        let updatedSecondaryMedication = try XCTUnwrap(storedMedications.first(where: { $0.id == secondaryMedication.id }))

        XCTAssertNotNil(updatedPrimaryMedication.nfcTagID)
        XCTAssertNil(updatedSecondaryMedication.nfcTagID)
        XCTAssertEqual(store.nfcPairingState.medicationName, updatedPrimaryMedication.displayTitle)
    }

    func testBottleTapLogsDoseAfterSettingsPairing() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Lisinopril", createdAt: now.addingTimeInterval(-120))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handleSettingsRowTap(
            SettingsRowState(
                symbolName: "dot.radiowaves.left.and.right",
                tone: .sage,
                title: "Reconnect this tag",
                accessory: .chevron,
                actionKind: .rePairCurrentTag
            )
        )
        await store.handleNFCPairingPrimaryAction()
        await store.handleNFCPairingPrimaryAction()
        await store.handlePatientPrimaryAction()

        let interval = DateInterval(
            start: now.addingTimeInterval(-12 * 60 * 60),
            end: now.addingTimeInterval(12 * 60 * 60)
        )
        let storedOccurrences = try await dependencies.recordStore.occurrences(for: profile.id, within: interval)
        var storedLogs: [DoseLog] = []
        for storedOccurrence in storedOccurrences where storedOccurrence.medicationID == medication.id {
            storedLogs.append(contentsOf: try await dependencies.recordStore.logs(for: storedOccurrence.id))
        }
        let nfcTapLog = storedLogs.first {
            $0.source == .nfcTap && $0.validationState == .accepted
        }

        XCTAssertNil(store.errorMessage)
        XCTAssertNotNil(nfcTapLog)
        XCTAssertTrue(store.infoMessage?.contains("confirmed from the tag tap") == true)
    }

    func testHandleSettingsRowTapPresentsTapKitShop() async throws {
        let store = CareTapAppStore(
            services: try await makeServices(user: nil),
            statePersistence: InMemoryAppStatePersistence()
        )

        await store.handleSettingsRowTap(
            SettingsRowState(
                symbolName: "bag.fill",
                tone: .warm,
                title: "Tap Kit",
                accessory: .chevron,
                actionKind: .openTapKitShop
            )
        )

        XCTAssertTrue(store.isPresentingTapKitShop)
    }

    func testPatientHomeScansPairedTagEvenWhenCurrentHeroMedicationIsUnpaired() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let currentMedication = makeMedication(profileID: profile.id, name: "Lisinopril", createdAt: now.addingTimeInterval(-180))
        let pairedMedication = makeMedication(profileID: profile.id, name: "Metformin", createdAt: now.addingTimeInterval(-120))
        let currentRule = makeRule(medicationID: currentMedication.id, profileID: profile.id, at: now.addingTimeInterval(-10 * 60))
        let pairedRule = makeRule(medicationID: pairedMedication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let currentOccurrence = makeOccurrence(
            medicationID: currentMedication.id,
            profileID: profile.id,
            ruleID: currentRule.id,
            scheduledAt: now.addingTimeInterval(-10 * 60),
            status: .dueNow
        )
        let pairedOccurrence = makeOccurrence(
            medicationID: pairedMedication.id,
            profileID: profile.id,
            ruleID: pairedRule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [currentMedication, pairedMedication],
            seedRules: [currentRule, pairedRule],
            seedOccurrences: [currentOccurrence, pairedOccurrence]
        )

        let writeResult = try await dependencies.services.nfcTags.writeTag(
            NFCTagWriteRequest(
                careProfileID: profile.id,
                medicationID: pairedMedication.id,
                label: pairedMedication.bottleLabel,
                stableUID: "caretap-pairing-\(pairedMedication.id.uuidString.lowercased())",
                payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: pairedMedication.id)
            )
        )
        let storedTag = try await dependencies.recordStore.upsertNfcTag(writeResult.tag)
        _ = try await dependencies.recordStore.upsertMedication(
            Medication(
                id: pairedMedication.id,
                careProfileID: pairedMedication.careProfileID,
                nfcTagID: storedTag.id,
                name: pairedMedication.name,
                dosage: pairedMedication.dosage,
                doseQuantity: pairedMedication.doseQuantity,
                doseQuantityUnit: pairedMedication.doseQuantityUnit,
                instructions: pairedMedication.instructions,
                bottleLabel: pairedMedication.bottleLabel,
                bottlePhotoLocalPath: pairedMedication.bottlePhotoLocalPath,
                form: pairedMedication.form,
                scheduleSummary: pairedMedication.scheduleSummary,
                isActive: pairedMedication.isActive,
                supplyCount: pairedMedication.supplyCount,
                createdAt: pairedMedication.createdAt,
                updatedAt: .now,
                archivedAt: pairedMedication.archivedAt,
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handlePatientPrimaryAction()

        let storedLogs = try await dependencies.recordStore.logs(for: pairedOccurrence.id)

        XCTAssertNil(store.errorMessage)
        XCTAssertTrue(storedLogs.contains { $0.source == .nfcTap && $0.validationState == .accepted })
    }

    func testPatientPrimaryActionForFutureDoseOpensScheduleInsteadOfLoggingTooEarly() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Protein Powder", createdAt: now.addingTimeInterval(-120))
        let futureScheduledAt = now.addingTimeInterval(2 * 60 * 60)
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: futureScheduledAt)
        let occurrence = DoseOccurrence(
            id: UUID(),
            careProfileID: profile.id,
            medicationID: medication.id,
            scheduleRuleID: rule.id,
            scheduledAt: futureScheduledAt,
            windowOpensAt: futureScheduledAt.addingTimeInterval(-15 * 60),
            windowClosesAt: futureScheduledAt.addingTimeInterval(60 * 60),
            snoozedUntil: nil,
            status: .scheduled,
            reminderState: .scheduled,
            flags: [],
            resolvedByLogID: nil,
            resolvedAt: nil,
            createdAt: now,
            updatedAt: now,
            syncState: .localOnly
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handlePatientPrimaryAction()

        XCTAssertEqual(store.selectedDestination, .workspace)
        XCTAssertFalse(store.infoMessage?.contains("before the dose window opened") == true)
        XCTAssertNil(store.errorMessage)
    }

    func testIncomingUniversalLinkResolvesTagTapIntoDoseLog() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Lisinopril", createdAt: now.addingTimeInterval(-120))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        let writeResult = try await dependencies.services.nfcTags.writeTag(
            NFCTagWriteRequest(
                careProfileID: profile.id,
                medicationID: medication.id,
                label: medication.bottleLabel,
                stableUID: "caretap-pairing-\(medication.id.uuidString.lowercased())",
                payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: medication.id)
            )
        )
        let storedTag = try await dependencies.recordStore.upsertNfcTag(writeResult.tag)
        _ = try await dependencies.recordStore.upsertMedication(
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
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handleIncomingURL(
            URL(string: "https://example.com/tag/\(storedTag.payloadIdentifier)")!
        )

        let storedLogs = try await dependencies.recordStore.logs(for: occurrence.id)

        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.route, .patient)
        XCTAssertTrue(storedLogs.contains { $0.source == .nfcTap && $0.validationState == .accepted })
    }

    func testPendingIncomingUniversalLinkOnColdStartResolvesTagTapIntoDoseLog() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Creatine", createdAt: now.addingTimeInterval(-120))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        let writeResult = try await dependencies.services.nfcTags.writeTag(
            NFCTagWriteRequest(
                careProfileID: profile.id,
                medicationID: medication.id,
                label: medication.bottleLabel,
                stableUID: "caretap-pairing-\(medication.id.uuidString.lowercased())",
                payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: medication.id)
            )
        )
        let storedTag = try await dependencies.recordStore.upsertNfcTag(writeResult.tag)
        _ = try await dependencies.recordStore.upsertMedication(
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
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.handleIncomingURL(
            URL(string: "https://example.com/tag/\(storedTag.payloadIdentifier)")!
        )
        await store.start()

        let storedLogs = try await dependencies.recordStore.logs(for: occurrence.id)

        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.route, .patient)
        XCTAssertTrue(storedLogs.contains { $0.source == .nfcTap && $0.validationState == .accepted })
        XCTAssertTrue(store.infoMessage?.contains("confirmed from the tag tap") == true)
    }

    func testPendingIncomingShortcutTagURLSwitchesBackToPatientAndResolvesDoseLog() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Creatine", createdAt: now.addingTimeInterval(-120))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(-5 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(-5 * 60),
            status: .dueNow
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .caregiver
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true
        persistedState.hasCompletedCaregiverSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        let writeResult = try await dependencies.services.nfcTags.writeTag(
            NFCTagWriteRequest(
                careProfileID: profile.id,
                medicationID: medication.id,
                label: medication.bottleLabel,
                stableUID: "caretap-pairing-\(medication.id.uuidString.lowercased())",
                payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: medication.id)
            )
        )
        let storedTag = try await dependencies.recordStore.upsertNfcTag(writeResult.tag)
        _ = try await dependencies.recordStore.upsertMedication(
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
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.handleIncomingURL(
            CareTapDeepLink.tagURL(payloadIdentifier: storedTag.payloadIdentifier)!
        )
        await store.start()

        let storedLogs = try await dependencies.recordStore.logs(for: occurrence.id)

        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.selectedRole, .patient)
        XCTAssertEqual(store.route, .patient)
        XCTAssertTrue(storedLogs.contains { $0.source == .nfcTap && $0.validationState == .accepted })
    }

    func testStartDoesNotShowLiveActivityForFarFutureScheduledDose() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Vitamin D", createdAt: now.addingTimeInterval(-300))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(8 * 60 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(8 * 60 * 60),
            status: .scheduled
        )
        let liveActivities = CapturingLiveActivityManager()

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence],
            liveActivities: liveActivities
        )
        _ = try await dependencies.recordStore.upsertReminderPreference(
            ReminderPreference(
                id: UUID(),
                userID: user.id,
                careProfileID: profile.id,
                channels: [.localNotification, .liveActivity],
                leadTimeMinutes: 10,
                followUpAfterMinutes: 20,
                maxFollowUps: 1,
                quietHours: nil,
                enablesLiveActivity: true,
                createdAt: now,
                updatedAt: now,
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        XCTAssertTrue(liveActivities.updatedOccurrenceIDs.isEmpty)
        XCTAssertGreaterThanOrEqual(liveActivities.endAllCallCount, 1)
    }

    func testStartShowsLiveActivityOnlyWithinReminderLeadTime() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Creatine", createdAt: now.addingTimeInterval(-300))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(5 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(5 * 60),
            status: .scheduled
        )
        let liveActivities = CapturingLiveActivityManager()

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence],
            liveActivities: liveActivities
        )
        _ = try await dependencies.recordStore.upsertReminderPreference(
            ReminderPreference(
                id: UUID(),
                userID: user.id,
                careProfileID: profile.id,
                channels: [.localNotification, .liveActivity],
                leadTimeMinutes: 10,
                followUpAfterMinutes: 20,
                maxFollowUps: 1,
                quietHours: nil,
                enablesLiveActivity: true,
                createdAt: now,
                updatedAt: now,
                syncState: .localOnly
            )
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        XCTAssertEqual(liveActivities.updatedOccurrenceIDs, [occurrence.id])
    }

    func testWidgetDestinationDeepLinkOpensRequestedTab() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Protein Powder", createdAt: now.addingTimeInterval(-300))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now.addingTimeInterval(60 * 60))
        let occurrence = makeOccurrence(
            medicationID: medication.id,
            profileID: profile.id,
            ruleID: rule.id,
            scheduledAt: now.addingTimeInterval(60 * 60),
            status: .scheduled
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.handleIncomingURL(URL(string: "caretap://workspace")!)

        XCTAssertEqual(store.selectedDestination, .workspace)
        XCTAssertEqual(store.route, .patient)
    }

    func testUndoLatestDoseLogReopensOccurrence() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)
        let now = Date()
        let medication = makeMedication(profileID: profile.id, name: "Vitamin D", createdAt: now.addingTimeInterval(-600))
        let rule = makeRule(medicationID: medication.id, profileID: profile.id, at: now)
        let originalLogID = UUID()
        let occurrence = DoseOccurrence(
            id: UUID(),
            careProfileID: profile.id,
            medicationID: medication.id,
            scheduleRuleID: rule.id,
            scheduledAt: now.addingTimeInterval(-10 * 60),
            windowOpensAt: now.addingTimeInterval(-25 * 60),
            windowClosesAt: now.addingTimeInterval(50 * 60),
            snoozedUntil: nil,
            status: .completed,
            reminderState: .actionTaken,
            flags: [.resolved],
            resolvedByLogID: originalLogID,
            resolvedAt: now.addingTimeInterval(-60),
            createdAt: now.addingTimeInterval(-10 * 60),
            updatedAt: now.addingTimeInterval(-60),
            syncState: .localOnly
        )
        let originalLog = DoseLog(
            id: originalLogID,
            careProfileID: profile.id,
            medicationID: medication.id,
            occurrenceID: occurrence.id,
            actorUserID: user.id,
            source: .manualPatientConfirmation,
            action: .confirmTaken,
            validationState: .accepted,
            effectiveAt: now.addingTimeInterval(-60),
            loggedAt: now.addingTimeInterval(-60),
            note: "Manual confirmation",
            resolutionKind: .standard,
            resolutionReason: nil,
            undoesLogID: nil,
            supersedesLogID: nil,
            nfcTagID: nil,
            createdAt: now.addingTimeInterval(-60),
            updatedAt: now.addingTimeInterval(-60),
            syncState: .localOnly
        )

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let dependencies = try await makeUnseededServices(
            user: user,
            seedProfile: profile,
            seedMedications: [medication],
            seedRules: [rule],
            seedOccurrences: [occurrence]
        )
        _ = try await dependencies.recordStore.upsertDoseLog(originalLog)

        let store = CareTapAppStore(
            services: dependencies.services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()
        await store.undoLatestDoseLog(for: occurrence.id)

        let refreshedOccurrences = try await dependencies.recordStore.occurrences(
            for: profile.id,
            within: DateInterval(
                start: now.addingTimeInterval(-12 * 60 * 60),
                end: now.addingTimeInterval(12 * 60 * 60)
            )
        )
        let updatedOccurrence = try XCTUnwrap(refreshedOccurrences.first(where: { $0.id == occurrence.id }))
        XCTAssertFalse(updatedOccurrence.isResolved)
        XCTAssertEqual(updatedOccurrence.status, .dueNow)

        let updatedLogs = try await dependencies.recordStore.logs(for: occurrence.id)
        XCTAssertTrue(updatedLogs.contains(where: { $0.resolutionKind == .undo && $0.undoesLogID == originalLogID }))
    }

    func testPremiumSettingsRowIsRemovedBecausePremiumIsBuiltIn() async throws {
        let user = makePatientUser()
        let profile = makePatientProfile(for: user)

        var persistedState = CareTapPersistedAppState.default()
        persistedState.selectedRole = .patient
        persistedState.activeCareProfileID = profile.id
        persistedState.hasCompletedPatientSetup = true

        let services = try await makeServices(
            user: user,
            seedProfile: profile
        )
        let store = CareTapAppStore(
            services: services,
            statePersistence: InMemoryAppStatePersistence(state: persistedState)
        )

        await store.start()

        let openPremiumRow = store.settingsState.sections
            .flatMap(\.rows)
            .first(where: { $0.actionKind == .openPremium })

        XCTAssertNil(openPremiumRow, "Premium should no longer appear as a paywalled settings row.")
        XCTAssertTrue(store.premiumViewState.status.isActive, "All premium features are built-in and always active.")
    }
}
