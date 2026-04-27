import Foundation

struct CareTapServiceContainer {
    let homeSnapshots: HomeSnapshotProviding
    let recordStore: CareTapRecordStoring
    let nfcTags: NFCTagServicing
    let doseLogging: DoseLoggingServicing
    let reminders: ReminderScheduling
    let auth: AuthCoordinating
    let backend: BackendRepositoryAccessing
    let caregiverRelationships: CaregiverRelationshipProviding
    let scheduleGenerator: MedicationScheduleGenerating
    let refillEstimator: RefillEstimating
    let premiumSubscriptions: PremiumSubscriptionServicing
    let widgetSnapshots: CareTapWidgetSnapshotStoring
    let liveActivities: CareTapDoseActivityManaging

    @MainActor
    static let preview: CareTapServiceContainer = {
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        return CareTapServiceContainer(
            homeSnapshots: PreviewHomeSnapshotService(),
            recordStore: recordStore,
            nfcTags: StubNFCTagService(),
            doseLogging: RepositoryBackedDoseLoggingService(recordStore: recordStore),
            reminders: StubReminderScheduler(),
            auth: StubAppleSignInCoordinator(),
            backend: backend,
            caregiverRelationships: RepositoryBackedCaregiverRelationshipService(
                relationshipsRepository: backend.localRepositories.careRelationships,
                invitationsRepository: backend.localRepositories.invitations
            ),
            scheduleGenerator: StubMedicationScheduleGenerator(),
            refillEstimator: StubRefillEstimator(),
            premiumSubscriptions: StubPremiumSubscriptionService(),
            widgetSnapshots: CareTapWidgetSnapshotStore(),
            liveActivities: CareTapDoseActivityManager()
        )
    }()

    static func live(
        configuration: SupabaseConfiguration,
        diskStore: CareTapBackendDiskStore
    ) throws -> CareTapServiceContainer {
        let backend = try SupabaseBackendRepository.live(configuration: configuration, diskStore: diskStore)
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        #if targetEnvironment(simulator)
        let nfcService: any NFCTagServicing = SimulatorNFCTagService(recordStore: recordStore)
        #else
        let nfcService: any NFCTagServicing = CoreNFCTagService(
            recordStore: recordStore,
            universalLinkHost: configuration.universalLinkHost
        )
        #endif
        return CareTapServiceContainer(
            homeSnapshots: PreviewHomeSnapshotService(),
            recordStore: recordStore,
            nfcTags: nfcService,
            doseLogging: RepositoryBackedDoseLoggingService(recordStore: recordStore),
            reminders: LocalNotificationReminderScheduler(),
            auth: SupabaseAuthCoordinator(
                configuration: configuration,
                sessionStore: diskStore,
                recordStore: recordStore
            ),
            backend: backend,
            caregiverRelationships: RepositoryBackedCaregiverRelationshipService(
                relationshipsRepository: backend.localRepositories.careRelationships,
                invitationsRepository: backend.localRepositories.invitations
            ),
            scheduleGenerator: CareTapMedicationScheduleGenerator(),
            refillEstimator: CareTapRefillEstimator(),
            premiumSubscriptions: CareTapPremiumStoreKitService(),
            widgetSnapshots: CareTapWidgetSnapshotStore(),
            liveActivities: CareTapDoseActivityManager()
        )
    }

    static func failsafeUnavailable() -> CareTapServiceContainer {
        let backend = SupabaseBackendRepository.ephemeralEmpty()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        return CareTapServiceContainer(
            homeSnapshots: PreviewHomeSnapshotService(),
            recordStore: recordStore,
            nfcTags: StubNFCTagService(),
            doseLogging: RepositoryBackedDoseLoggingService(recordStore: recordStore),
            reminders: StubReminderScheduler(),
            auth: UnavailableAuthCoordinator(),
            backend: backend,
            caregiverRelationships: RepositoryBackedCaregiverRelationshipService(
                relationshipsRepository: backend.localRepositories.careRelationships,
                invitationsRepository: backend.localRepositories.invitations
            ),
            scheduleGenerator: CareTapMedicationScheduleGenerator(),
            refillEstimator: CareTapRefillEstimator(),
            premiumSubscriptions: StubPremiumSubscriptionService(),
            widgetSnapshots: CareTapWidgetSnapshotStore(),
            liveActivities: CareTapDoseActivityManager()
        )
    }
}

actor StubPremiumSubscriptionService: PremiumSubscriptionServicing {
    private var storedSnapshot: CareTapPremiumSnapshot

    init(snapshot: CareTapPremiumSnapshot = .ready()) {
        storedSnapshot = snapshot
    }

    func prepare() async {}

    func snapshot() async -> CareTapPremiumSnapshot {
        storedSnapshot
    }

    func purchase(plan: CareTapPremiumPlan) async throws -> CareTapPremiumPurchaseOutcome {
        storedSnapshot = .ready(
            isPremiumActive: true,
            activePlan: plan,
            renewalDescription: "Renews automatically unless canceled."
        )
        return .purchased(storedSnapshot)
    }

    func restorePurchases() async throws -> CareTapPremiumSnapshot {
        storedSnapshot
    }
}

struct StubNFCTagService: NFCTagServicing {
    func scanTag() async throws -> NFCTagReadResult {
        try await readTag(stableUID: CareTapPhaseThreePreviewScenarios.nfcTag.stableUID)
    }

    func readTag(stableUID: String) async throws -> NFCTagReadResult {
        let tag = CareTapPhaseThreePreviewScenarios.nfcTag
        guard stableUID == tag.stableUID else {
            throw CareTapServiceError.invalidTag
        }

        return NFCTagReadResult(tag: tag, matchedMedicationID: tag.medicationID)
    }

    func writeTag(_ request: NFCTagWriteRequest) async throws -> NFCTagWriteResult {
        guard !request.stableUID.isEmpty, !request.payloadIdentifier.isEmpty else {
            throw CareTapServiceError.invalidTag
        }

        // TODO: Replace with a CoreNFC write session once pairing starts a real hardware flow.
        let pairedTag = NfcTag(
            id: CareTapPhaseThreePreviewScenarios.nfcTag.id,
            careProfileID: request.careProfileID,
            medicationID: request.medicationID,
            stableUID: request.stableUID,
            payloadIdentifier: request.payloadIdentifier,
            label: request.label,
            status: .paired,
            pairedAt: .now,
            lastReadAt: nil,
            lastWrittenAt: .now,
            createdAt: CareTapPhaseThreePreviewScenarios.nfcTag.createdAt,
            updatedAt: .now,
            syncState: .localOnly
        )

        return NFCTagWriteResult(tag: pairedTag, pairingState: .success)
    }
}

final class SimulatorNFCTagService: NFCTagServicing, @unchecked Sendable {
    private let recordStore: any CareTapRecordStoring
    private let storage: UserDefaults
    private let lastPairedStableUIDKey = "CareTap.LastPairedStableUID"
    private let lastPairedPayloadIdentifierKey = "CareTap.LastPairedPayloadIdentifier"

    init(
        recordStore: any CareTapRecordStoring,
        storage: UserDefaults = .standard
    ) {
        self.recordStore = recordStore
        self.storage = storage
    }

    func scanTag() async throws -> NFCTagReadResult {
        let stableUID = storage.string(forKey: lastPairedStableUIDKey)
        let payloadIdentifier = storage.string(forKey: lastPairedPayloadIdentifierKey)

        if let stableUID {
            return try await readTag(stableUID: stableUID)
        }

        if let payloadIdentifier,
           let tag = try await recordStore.tag(payloadIdentifier: payloadIdentifier) {
            return NFCTagReadResult(tag: tag, matchedMedicationID: tag.medicationID)
        }

        guard stableUID != nil || payloadIdentifier != nil else {
            throw CareTapServiceError.missingRecord
        }
        throw CareTapServiceError.missingRecord
    }

    func readTag(stableUID: String) async throws -> NFCTagReadResult {
        if let tag = try await recordStore.tag(stableUID: stableUID) {
            return NFCTagReadResult(tag: tag, matchedMedicationID: tag.medicationID)
        }

        if let payloadIdentifier = storage.string(forKey: lastPairedPayloadIdentifierKey),
           let tag = try await recordStore.tag(payloadIdentifier: payloadIdentifier) {
            return NFCTagReadResult(tag: tag, matchedMedicationID: tag.medicationID)
        }

        throw CareTapServiceError.missingRecord
    }

    func writeTag(_ request: NFCTagWriteRequest) async throws -> NFCTagWriteResult {
        guard !request.stableUID.isEmpty, !request.payloadIdentifier.isEmpty else {
            throw CareTapServiceError.invalidTag
        }

        storage.set(request.stableUID, forKey: lastPairedStableUIDKey)
        storage.set(request.payloadIdentifier, forKey: lastPairedPayloadIdentifierKey)

        let pairedTag = NfcTag(
            id: UUID(),
            careProfileID: request.careProfileID,
            medicationID: request.medicationID,
            stableUID: request.stableUID,
            payloadIdentifier: request.payloadIdentifier,
            label: request.label,
            status: .paired,
            pairedAt: .now,
            lastReadAt: .now,
            lastWrittenAt: .now,
            createdAt: .now,
            updatedAt: .now,
            syncState: .pendingUpload
        )

        return NFCTagWriteResult(tag: pairedTag, pairingState: .success)
    }
}

struct StubDoseLoggingService: DoseLoggingServicing {
    func logDose(for occurrence: DoseOccurrence, request: DoseLoggingRequest) async throws -> DoseLoggingResult {
        let validationState = validationState(for: occurrence, request: request)
        let resolutionReason = request.resolutionReason ?? request.note
        let log = DoseLog(
            id: UUID(),
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            occurrenceID: occurrence.id,
            actorUserID: request.actorUserID,
            source: request.source,
            action: request.action,
            validationState: validationState,
            effectiveAt: request.loggedAt,
            loggedAt: request.loggedAt,
            note: request.note,
            resolutionKind: resolutionKind(for: occurrence, request: request),
            resolutionReason: resolutionReason,
            undoesLogID: request.undoesLogID,
            supersedesLogID: request.action == .correctEntry ? (request.undoesLogID ?? occurrence.resolvedByLogID) : nil,
            nfcTagID: request.nfcTagID,
            createdAt: request.loggedAt,
            updatedAt: request.loggedAt,
            syncState: .localOnly
        )

        var flags = occurrence.flags
        var status = occurrence.status
        var reminderState = occurrence.reminderState
        var resolvedAt = occurrence.resolvedAt
        var resolvedByLogID = occurrence.resolvedByLogID

        switch validationState {
        case .accepted:
            switch request.action {
            case .confirmTaken:
                reminderState = .actionTaken
                resolvedAt = request.loggedAt
                resolvedByLogID = log.id
                if request.loggedAt > occurrence.windowClosesAt {
                    status = .late
                    flags.append(.late)
                } else {
                    status = .completed
                }
                flags.append(.resolved)
            case .markSkipped:
                reminderState = .actionTaken
                resolvedAt = request.loggedAt
                resolvedByLogID = log.id
                status = .skipped
                flags.append(.skipped)
                flags.append(.resolved)
            case .correctEntry:
                if request.undoesLogID != nil {
                    let reopened = reopenedStatus(for: occurrence, now: request.loggedAt)
                    status = reopened.status
                    reminderState = .scheduled
                    resolvedAt = nil
                    resolvedByLogID = nil
                    flags = reopened.flags
                } else {
                    reminderState = .actionTaken
                    resolvedAt = request.loggedAt
                    resolvedByLogID = log.id
                    status = .resolved
                    flags.append(.resolved)
                }
            }
        case .duplicate:
            flags.append(.duplicate)
        case .tooEarly:
            flags.append(.tooEarly)
        case .superseded, .rejected:
            break
        }

        let updatedOccurrence = DoseOccurrence(
            id: occurrence.id,
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            scheduleRuleID: occurrence.scheduleRuleID,
            scheduledAt: occurrence.scheduledAt,
            windowOpensAt: occurrence.windowOpensAt,
            windowClosesAt: occurrence.windowClosesAt,
            snoozedUntil: occurrence.snoozedUntil,
            status: status,
            reminderState: reminderState,
            flags: Array(Set(flags)),
            resolvedByLogID: resolvedByLogID,
            resolvedAt: resolvedAt,
            createdAt: occurrence.createdAt,
            updatedAt: request.loggedAt,
            syncState: .localOnly
        )

        return DoseLoggingResult(occurrence: updatedOccurrence, log: log)
    }

    private func validationState(for occurrence: DoseOccurrence, request: DoseLoggingRequest) -> DoseLogValidationState {
        if request.action == .confirmTaken && request.loggedAt < occurrence.windowOpensAt {
            return .tooEarly
        }

        if occurrence.isResolved && request.action != .correctEntry {
            return .duplicate
        }

        return .accepted
    }

    private func resolutionKind(for occurrence: DoseOccurrence, request: DoseLoggingRequest) -> DoseLogResolutionKind {
        switch request.action {
        case .confirmTaken:
            return request.loggedAt > occurrence.windowClosesAt ? .lateConfirmation : .standard
        case .markSkipped:
            return .skippedWithReason
        case .correctEntry:
            return request.undoesLogID == nil ? .correctedEntry : .undo
        }
    }

    private func reopenedStatus(for occurrence: DoseOccurrence, now: Date) -> (status: DoseOccurrenceStatus, flags: [DoseOccurrenceFlag]) {
        var flags = Set(occurrence.flags)
        flags.subtract([.resolved, .skipped, .late, .missed])

        let status: DoseOccurrenceStatus
        if let snoozedUntil = occurrence.snoozedUntil, snoozedUntil > now {
            status = .snoozed
        } else if now < occurrence.scheduledAt {
            status = .scheduled
        } else if now <= occurrence.windowClosesAt {
            status = .dueNow
        } else if now > occurrence.windowClosesAt.addingTimeInterval(4 * 60 * 60) {
            flags.insert(.missed)
            status = .missed
        } else {
            status = .overdue
        }

        return (status, Array(flags))
    }
}

struct StubReminderScheduler: ReminderScheduling, Sendable {
    func scheduleReminders(
        for occurrence: DoseOccurrence,
        medication: Medication,
        preference: ReminderPreference
    ) async throws -> [ReminderSchedulePlan] {
        let dueDate = occurrence.snoozedUntil ?? occurrence.scheduledAt
        var plans: [ReminderSchedulePlan] = []

        for channel in preference.channels {
            let firstFireDate = dueDate.addingTimeInterval(TimeInterval(-preference.leadTimeMinutes * 60))
            plans.append(
                ReminderSchedulePlan(
                    occurrenceID: occurrence.id,
                    channel: channel,
                    fireDate: firstFireDate,
                    title: "\(medication.name) due",
                    body: "A reminder can prompt the check-in, but it does not confirm anything by itself.",
                    primaryActionLabel: "Tap Tag"
                )
            )

            if channel == .localNotification,
               let followUpAfterMinutes = preference.followUpAfterMinutes,
               preference.maxFollowUps > 0 {
                plans.append(
                    ReminderSchedulePlan(
                        occurrenceID: occurrence.id,
                        channel: channel,
                        fireDate: dueDate.addingTimeInterval(TimeInterval(followUpAfterMinutes * 60)),
                        title: "\(medication.name) still needs confirmation",
                        body: "TapCare can keep nudging without treating a dismissal as a completed check-in.",
                        primaryActionLabel: "Check In"
                    )
                )
            }
        }

        // TODO: Replace with UNUserNotificationCenter scheduling and cancellation.
        return plans.sorted { $0.fireDate < $1.fireDate }
    }

    func cancelReminders(for occurrenceID: UUID) async throws {
        // TODO: Remove pending local notifications once reminder identifiers are persisted.
        _ = occurrenceID
    }
}

@MainActor
final class StubAppleSignInCoordinator: AuthCoordinating, @unchecked Sendable {
    private var currentUser: User? = CareTapPhaseThreePreviewScenarios.user

    func sessionSnapshot() async -> AuthenticationSessionSnapshot {
        makeSnapshot()
    }

    func signInWithApple(with payload: AppleIdentityTokenPayload, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        guard let currentUser else {
            return AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
        }

        self.currentUser = User(
            id: currentUser.id,
            authUserID: currentUser.authUserID ?? UUID(),
            appleSubject: payload.appleSubject.isEmpty ? currentUser.appleSubject ?? "apple-preview-linked" : payload.appleSubject,
            preferredRole: preferredRole,
            displayName: payload.givenName ?? currentUser.displayName,
            initials: currentUser.initials,
            timezoneIdentifier: currentUser.timezoneIdentifier,
            localeIdentifier: currentUser.localeIdentifier,
            isSignInWithAppleLinked: true,
            createdAt: currentUser.createdAt,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )

        return makeSnapshot()
    }

    func signUpWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        try await stubEmailAuth(email: credential.email, displayName: credential.displayName, preferredRole: preferredRole)
    }

    func signInWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        try await stubEmailAuth(email: credential.email, displayName: credential.displayName, preferredRole: preferredRole)
    }

    func signOut() async {
        currentUser = nil
    }

    func deleteAccount() async throws {
        currentUser = nil
    }

    private func stubEmailAuth(email: String, displayName: String?, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        guard let currentUser else {
            return AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
        }

        let name = displayName ?? email.split(separator: "@").first.map(String.init) ?? "User"
        self.currentUser = User(
            id: currentUser.id,
            authUserID: currentUser.authUserID ?? UUID(),
            appleSubject: nil,
            preferredRole: preferredRole,
            displayName: name,
            initials: currentUser.initials,
            timezoneIdentifier: currentUser.timezoneIdentifier,
            localeIdentifier: currentUser.localeIdentifier,
            isSignInWithAppleLinked: false,
            createdAt: currentUser.createdAt,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )

        return makeSnapshot()
    }

    private func makeSnapshot() -> AuthenticationSessionSnapshot {
        let state: AuthenticationSessionState

        if let currentUser {
            state = currentUser.isSignInWithAppleLinked ? .linkedForSync : .locallyAuthorized
        } else {
            state = .signedOut
        }

        return AuthenticationSessionSnapshot(state: state, user: currentUser, lastUpdatedAt: .now)
    }
}

private struct CareTapStartupUnavailableError: LocalizedError {
    var errorDescription: String? {
        "CareTap couldn’t start its secure local storage or account services on this iPhone yet. Please update the app or try reinstalling it."
    }
}

final class UnavailableAuthCoordinator: AuthCoordinating, @unchecked Sendable {
    func sessionSnapshot() async -> AuthenticationSessionSnapshot {
        AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
    }

    func signInWithApple(with payload: AppleIdentityTokenPayload, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        throw CareTapStartupUnavailableError()
    }

    func signUpWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        throw CareTapStartupUnavailableError()
    }

    func signInWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot {
        throw CareTapStartupUnavailableError()
    }

    func signOut() async {}

    func deleteAccount() async throws {
        throw CareTapStartupUnavailableError()
    }
}

struct StubCaregiverRelationshipService: CaregiverRelationshipProviding {
    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship] {
        guard caregiverUserID == CareTapPhaseThreePreviewScenarios.user.id else {
            return []
        }

        return [CareTapPhaseThreePreviewScenarios.careRelationship]
    }

    func invitations(for careProfileID: UUID) async throws -> [Invitation] {
        guard careProfileID == CareTapPhaseThreePreviewScenarios.careProfile.id else {
            return []
        }

        return [CareTapPhaseThreePreviewScenarios.invitation]
    }
}

struct StubMedicationScheduleGenerator: MedicationScheduleGenerating, Sendable {
    private let referenceDate: Date?

    init(referenceDate: Date? = nil) {
        self.referenceDate = referenceDate
    }

    func generateOccurrences(
        for medication: Medication,
        rules: [ScheduleRule],
        within interval: DateInterval
    ) -> [DoseOccurrence] {
        var generated: [DoseOccurrence] = []

        for rule in rules where rule.isActive && rule.medicationID == medication.id {
            switch rule.type {
            case .daily, .weekly:
                generated.append(contentsOf: generateDayBasedOccurrences(medication: medication, rule: rule, interval: interval))
            case .interval:
                generated.append(contentsOf: generateIntervalOccurrences(medication: medication, rule: rule, interval: interval))
            case .asNeeded:
                continue
            }
        }

        return generated.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private func generateDayBasedOccurrences(
        medication: Medication,
        rule: ScheduleRule,
        interval: DateInterval
    ) -> [DoseOccurrence] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: rule.timezoneIdentifier) ?? .current

        let startDay = calendar.startOfDay(for: max(interval.start, rule.startsOn))
        let endDate = min(interval.end, rule.endsOn ?? interval.end)
        let allowedWeekdays = Set(rule.daysOfWeek.map(\.rawValue))
        var cursor = startDay
        var occurrences: [DoseOccurrence] = []

        while cursor <= endDate {
            let weekday = calendar.component(.weekday, from: cursor)
            let isAllowedDay: Bool

            if rule.type == .weekly {
                isAllowedDay = allowedWeekdays.contains(weekday)
            } else {
                isAllowedDay = allowedWeekdays.isEmpty || allowedWeekdays.contains(weekday)
            }

            if isAllowedDay {
                for time in rule.timesOfDay {
                    var components = calendar.dateComponents([.year, .month, .day], from: cursor)
                    components.hour = time.hour
                    components.minute = time.minute
                    if let scheduledAt = calendar.date(from: components), interval.contains(scheduledAt) {
                        occurrences.append(makeOccurrence(for: medication, rule: rule, scheduledAt: scheduledAt))
                    }
                }
            }

            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? endDate.addingTimeInterval(1)
        }

        return occurrences
    }

    private func generateIntervalOccurrences(
        medication: Medication,
        rule: ScheduleRule,
        interval: DateInterval
    ) -> [DoseOccurrence] {
        guard let intervalHours = rule.intervalHours, intervalHours > 0 else {
            return []
        }

        var scheduledAt = rule.startsOn
        let endDate = min(interval.end, rule.endsOn ?? interval.end)
        var occurrences: [DoseOccurrence] = []

        while scheduledAt <= endDate {
            if interval.contains(scheduledAt) {
                occurrences.append(makeOccurrence(for: medication, rule: rule, scheduledAt: scheduledAt))
            }

            scheduledAt = scheduledAt.addingTimeInterval(TimeInterval(intervalHours * 60 * 60))
        }

        return occurrences
    }

    private func makeOccurrence(for medication: Medication, rule: ScheduleRule, scheduledAt: Date) -> DoseOccurrence {
        let windowOpensAt = scheduledAt.addingTimeInterval(-15 * 60)
        let windowClosesAt = scheduledAt.addingTimeInterval(TimeInterval(rule.gracePeriodMinutes * 60))
        let status: DoseOccurrenceStatus
        let evaluationDate = referenceDate ?? .now

        if evaluationDate < scheduledAt {
            status = .scheduled
        } else if evaluationDate <= windowClosesAt {
            status = .dueNow
        } else {
            status = .overdue
        }

        return DoseOccurrence(
            id: UUID(),
            careProfileID: medication.careProfileID,
            medicationID: medication.id,
            scheduleRuleID: rule.id,
            scheduledAt: scheduledAt,
            windowOpensAt: windowOpensAt,
            windowClosesAt: windowClosesAt,
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
}

struct StubRefillEstimator: RefillEstimating, Sendable {
    func estimateRefillState(
        for medication: Medication,
        rules: [ScheduleRule],
        asOf referenceDate: Date
    ) -> RefillState {
        let doseQuantity = medication.doseQuantity ?? 1
        let quantityOnHand = medication.supplyCount
        let dosesRemaining = quantityOnHand.map { Int(floor($0 / doseQuantity)) } ?? 0
        let dailyDoses = max(estimatedDailyDoses(from: rules), 1)
        let daysRemaining = Int(floor(Double(dosesRemaining) / dailyDoses))
        let estimatedRunOutDate = quantityOnHand == nil ? nil : referenceDate.addingTimeInterval(TimeInterval(daysRemaining * 24 * 60 * 60))

        let riskLevel: RefillRiskLevel
        switch daysRemaining {
        case ..<1:
            riskLevel = .depleted
        case 1...3:
            riskLevel = .urgent
        case 4...7:
            riskLevel = .watch
        default:
            riskLevel = .onTrack
        }

        return RefillState(
            id: UUID(),
            medicationID: medication.id,
            quantityOnHand: quantityOnHand,
            dosesRemainingEstimate: dosesRemaining,
            estimatedRunOutDate: estimatedRunOutDate,
            riskLevel: riskLevel,
            lastCalculatedAt: referenceDate,
            createdAt: referenceDate,
            updatedAt: referenceDate,
            syncState: .localOnly
        )
    }

    private func estimatedDailyDoses(from rules: [ScheduleRule]) -> Double {
        rules
            .filter(\.isActive)
            .reduce(0) { partialResult, rule in
                switch rule.type {
                case .daily:
                    let dailyTimes = max(rule.timesOfDay.count, 1)
                    return partialResult + Double(dailyTimes)
                case .weekly:
                    let activeDays = max(rule.daysOfWeek.count, 1)
                    let dailyTimes = max(rule.timesOfDay.count, 1)
                    return partialResult + (Double(activeDays * dailyTimes) / 7.0)
                case .interval:
                    guard let intervalHours = rule.intervalHours, intervalHours > 0 else {
                        return partialResult
                    }
                    return partialResult + (24.0 / Double(intervalHours))
                case .asNeeded:
                    return partialResult
                }
            }
    }
}
