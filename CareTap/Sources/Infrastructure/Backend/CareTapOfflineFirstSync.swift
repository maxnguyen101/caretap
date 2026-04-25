import Foundation

/*
 Offline-first sync strategy:
 1. UI and feature services read from the local repository set only.
 2. Local edits stage typed sync mutations instead of calling Supabase directly.
 3. Sync pushes pending mutations, then pulls server changes newer than the last cursor.
 4. If the server copy is newer than the local mutation timestamp, the mutation is flagged as a conflict
    instead of silently overwriting the remote record.
 */

final class CareTapSyncStateStore {
    private let lock = NSLock()
    private let persistence: (any CareTapSyncStatePersisting)?
    private var cursor: CareTapSyncCursor?
    private var pendingMutations = CareTapSyncMutationBatch.empty
    private var conflicts: [CareTapSyncConflictPayload] = []

    init(
        cursor: CareTapSyncCursor? = nil,
        persistence: (any CareTapSyncStatePersisting)? = nil
    ) {
        self.persistence = persistence

        if let restoredState = try? persistence?.loadSyncState() {
            self.cursor = restoredState.cursor
            pendingMutations = restoredState.pendingMutations
            conflicts = restoredState.conflicts
        } else {
            self.cursor = cursor
        }
    }

    func queue(_ mutations: CareTapSyncMutationBatch) {
        lock.lock()
        defer { lock.unlock() }
        pendingMutations.users.append(contentsOf: mutations.users)
        pendingMutations.careProfiles.append(contentsOf: mutations.careProfiles)
        pendingMutations.careRelationships.append(contentsOf: mutations.careRelationships)
        pendingMutations.medications.append(contentsOf: mutations.medications)
        pendingMutations.scheduleRules.append(contentsOf: mutations.scheduleRules)
        pendingMutations.doseOccurrences.append(contentsOf: mutations.doseOccurrences)
        pendingMutations.doseLogs.append(contentsOf: mutations.doseLogs)
        pendingMutations.nfcTags.append(contentsOf: mutations.nfcTags)
        pendingMutations.reminderPreferences.append(contentsOf: mutations.reminderPreferences)
        pendingMutations.alertPolicies.append(contentsOf: mutations.alertPolicies)
        pendingMutations.refillStates.append(contentsOf: mutations.refillStates)
        pendingMutations.invitations.append(contentsOf: mutations.invitations)
        persistLockedState()
    }

    func pendingRequest() -> CareTapSyncPushRequest {
        lock.lock()
        defer { lock.unlock() }
        let request = CareTapSyncPushRequest(cursor: cursor, mutations: pendingMutations)
        return request
    }

    func recordPush(_ response: CareTapSyncPushResponse) {
        lock.lock()
        defer { lock.unlock() }
        pendingMutations = .empty
        cursor = response.cursor
        conflicts = response.conflicts
        persistLockedState()
    }

    func recordPull(_ response: CareTapSyncPullResponse) {
        lock.lock()
        defer { lock.unlock() }
        cursor = response.cursor
        conflicts = response.conflicts
        persistLockedState()
    }

    func currentCursor() -> CareTapSyncCursor? {
        lock.lock()
        defer { lock.unlock() }
        let current = cursor
        return current
    }

    func snapshot() -> BackendSyncSnapshot {
        lock.lock()
        defer { lock.unlock() }
        let snapshot = BackendSyncSnapshot(
            lastSyncAt: cursor?.lastSyncedAt,
            pendingUploadCount: pendingMutations.totalMutationCount,
            conflictCount: conflicts.count
        )
        return snapshot
    }

    private func persistLockedState() {
        guard let persistence else {
            return
        }

        try? persistence.saveSyncState(
            CareTapPersistedSyncState(
                cursor: cursor,
                pendingMutations: pendingMutations,
                conflicts: conflicts
            )
        )
    }
}

struct SupabaseSyncGatewayClient: CareTapSyncGateway {
    let repositories: CareTapSupabaseRepositorySet

    func pull(since cursor: CareTapSyncCursor?) async throws -> CareTapSyncPullResponse {
        let since = cursor?.lastSyncedAt

        let changes = CareTapSyncBatchPayload(
            users: try await repositories.usersTable.fetchModified(since: since),
            careProfiles: try await repositories.careProfilesTable.fetchModified(since: since),
            careRelationships: try await repositories.careRelationshipsTable.fetchModified(since: since),
            medications: try await repositories.medicationsTable.fetchModified(since: since),
            scheduleRules: try await repositories.scheduleRulesTable.fetchModified(since: since),
            doseOccurrences: try await repositories.doseOccurrencesTable.fetchModified(since: since),
            doseLogs: try await repositories.doseLogsTable.fetchModified(since: since),
            nfcTags: try await repositories.nfcTagsTable.fetchModified(since: since),
            reminderPreferences: try await repositories.reminderPreferencesTable.fetchModified(since: since),
            alertPolicies: try await repositories.alertPoliciesTable.fetchModified(since: since),
            refillStates: try await repositories.refillStatesTable.fetchModified(since: since),
            invitations: try await repositories.invitationsTable.fetchModified(since: since)
        )

        return CareTapSyncPullResponse(
            cursor: CareTapSyncCursor(lastSyncedAt: .now),
            changes: changes,
            conflicts: []
        )
    }

    func push(_ request: CareTapSyncPushRequest) async throws -> CareTapSyncPushResponse {
        let userResult = try await apply(request.mutations.users, via: repositories.usersTable)
        let careProfileResult = try await apply(request.mutations.careProfiles, via: repositories.careProfilesTable)
        let relationshipResult = try await apply(request.mutations.careRelationships, via: repositories.careRelationshipsTable)
        let medicationResult = try await apply(request.mutations.medications, via: repositories.medicationsTable)
        let scheduleRuleResult = try await apply(request.mutations.scheduleRules, via: repositories.scheduleRulesTable)
        let occurrenceResult = try await apply(request.mutations.doseOccurrences, via: repositories.doseOccurrencesTable)
        let logResult = try await apply(request.mutations.doseLogs, via: repositories.doseLogsTable)
        let nfcTagResult = try await apply(request.mutations.nfcTags, via: repositories.nfcTagsTable)
        let reminderPreferenceResult = try await apply(request.mutations.reminderPreferences, via: repositories.reminderPreferencesTable)
        let alertPolicyResult = try await apply(request.mutations.alertPolicies, via: repositories.alertPoliciesTable)
        let refillStateResult = try await apply(request.mutations.refillStates, via: repositories.refillStatesTable)
        let invitationResult = try await apply(request.mutations.invitations, via: repositories.invitationsTable)

        let appliedChanges = CareTapSyncBatchPayload(
            users: userResult.rows,
            careProfiles: careProfileResult.rows,
            careRelationships: relationshipResult.rows,
            medications: medicationResult.rows,
            scheduleRules: scheduleRuleResult.rows,
            doseOccurrences: occurrenceResult.rows,
            doseLogs: logResult.rows,
            nfcTags: nfcTagResult.rows,
            reminderPreferences: reminderPreferenceResult.rows,
            alertPolicies: alertPolicyResult.rows,
            refillStates: refillStateResult.rows,
            invitations: invitationResult.rows
        )

        let conflicts = userResult.conflicts
            + careProfileResult.conflicts
            + relationshipResult.conflicts
            + medicationResult.conflicts
            + scheduleRuleResult.conflicts
            + occurrenceResult.conflicts
            + logResult.conflicts
            + nfcTagResult.conflicts
            + reminderPreferenceResult.conflicts
            + alertPolicyResult.conflicts
            + refillStateResult.conflicts
            + invitationResult.conflicts

        return CareTapSyncPushResponse(
            cursor: CareTapSyncCursor(lastSyncedAt: .now),
            acceptedMutationCount: request.mutations.totalMutationCount - conflicts.count,
            appliedChanges: appliedChanges,
            conflicts: conflicts
        )
    }

    private func apply<Row: CareTapSupabaseRow>(
        _ mutations: [CareTapSyncMutation<Row>],
        via repository: SupabaseTableRepository<Row>
    ) async throws -> (rows: [Row], conflicts: [CareTapSyncConflictPayload]) {
        var accepted: [Row] = []
        var conflicts: [CareTapSyncConflictPayload] = []

        for mutation in mutations {
            if let remote = try await repository.fetch(id: mutation.row.id, includeDeleted: true),
               remote.updatedAt > mutation.clientUpdatedAt {
                conflicts.append(
                    CareTapSyncConflictPayload(
                        table: Row.table,
                        recordID: mutation.row.id,
                        summary: mutation.operation == .delete
                            ? "The remote \(Row.table.rawValue) record changed after this local removal was queued."
                            : "The remote \(Row.table.rawValue) record changed after this local edit was queued.",
                        serverUpdatedAt: remote.updatedAt,
                        clientUpdatedAt: mutation.clientUpdatedAt
                    )
                )
                continue
            }

            accepted.append(mutation.row)
        }

        return (try await repository.upsert(accepted), conflicts)
    }
}

final class OfflineFirstSyncEngine {
    let localTransport: any LocalSupabaseCachingTransport
    let localRepositories: CareTapSupabaseRepositorySet
    private let remoteGateway: any CareTapSyncGateway
    private let stateStore: CareTapSyncStateStore

    init(
        localTransport: any LocalSupabaseCachingTransport,
        remoteGateway: any CareTapSyncGateway,
        seed: CareTapSyncBatchPayload = .empty,
        cursor: CareTapSyncCursor? = nil,
        statePersistence: (any CareTapSyncStatePersisting)? = nil
    ) throws {
        self.localTransport = localTransport
        localRepositories = CareTapSupabaseRepositorySet(transport: localTransport)
        self.remoteGateway = remoteGateway
        stateStore = CareTapSyncStateStore(cursor: cursor, persistence: statePersistence)

        if !seed.isEmpty {
            try localTransport.seed(seed)
        }
    }

    func stage(_ mutations: CareTapSyncMutationBatch) async {
        stateStore.queue(mutations)
    }

    func snapshot() async -> BackendSyncSnapshot {
        stateStore.snapshot()
    }

    func sync() async throws -> BackendSyncResult {
        let pendingRequest = stateStore.pendingRequest()
        var uploadedCount = 0
        var allConflicts: [CareTapSyncConflictPayload] = []

        if !pendingRequest.mutations.isEmpty {
            let pushResponse = try await remoteGateway.push(pendingRequest)
            try localTransport.seed(pushResponse.appliedChanges)
            stateStore.recordPush(pushResponse)
            uploadedCount = pushResponse.acceptedMutationCount
            allConflicts.append(contentsOf: pushResponse.conflicts)
        }

        let pullResponse = try await remoteGateway.pull(since: stateStore.currentCursor())
        try localTransport.seed(pullResponse.changes)
        stateStore.recordPull(pullResponse)
        allConflicts.append(contentsOf: pullResponse.conflicts)

        return BackendSyncResult(
            uploadedCount: uploadedCount,
            downloadedCount: pullResponse.changes.totalRowCount,
            conflicts: allConflicts.map {
                BackendSyncConflict(entityName: $0.table.rawValue, entityID: $0.recordID, summary: $0.summary)
            }
        )
    }
}

final class SupabaseBackendRepository: BackendRepositoryAccessing, @unchecked Sendable {
    let localRepositories: CareTapSupabaseRepositorySet
    private let syncEngine: OfflineFirstSyncEngine
    private let remoteTransport: URLSessionSupabaseTransport?

    init(
        syncEngine: OfflineFirstSyncEngine,
        remoteTransport: URLSessionSupabaseTransport? = nil
    ) {
        self.syncEngine = syncEngine
        self.remoteTransport = remoteTransport
        localRepositories = syncEngine.localRepositories
    }

    static func previewSeeded() -> SupabaseBackendRepository {
        let localTransport = InMemorySupabaseTransport()
        let remoteTransport = InMemorySupabaseTransport()
        let seed = CareTapSyncBatchPayload.phaseThreePreviewSeed
        try? remoteTransport.seed(seed)

        let remoteGateway = SupabaseSyncGatewayClient(repositories: CareTapSupabaseRepositorySet(transport: remoteTransport))
        let syncEngine = try! OfflineFirstSyncEngine(
            localTransport: localTransport,
            remoteGateway: remoteGateway,
            seed: seed,
            cursor: CareTapSyncCursor(lastSyncedAt: nil)
        )

        return SupabaseBackendRepository(syncEngine: syncEngine)
    }

    static func live(configuration: SupabaseConfiguration, diskStore: CareTapBackendDiskStore) throws -> SupabaseBackendRepository {
        let localTransport = try PersistentSupabaseTransport(store: diskStore)
        let remoteTransport = URLSessionSupabaseTransport(
            configuration: configuration,
            authSessionStore: diskStore
        )
        let remoteGateway = SupabaseSyncGatewayClient(repositories: CareTapSupabaseRepositorySet(transport: remoteTransport))
        let syncEngine = try OfflineFirstSyncEngine(
            localTransport: localTransport,
            remoteGateway: remoteGateway,
            statePersistence: diskStore
        )
        return SupabaseBackendRepository(
            syncEngine: syncEngine,
            remoteTransport: remoteTransport
        )
    }

    static func ephemeralEmpty() -> SupabaseBackendRepository {
        let localTransport = InMemorySupabaseTransport()
        let remoteTransport = InMemorySupabaseTransport()
        let remoteGateway = SupabaseSyncGatewayClient(repositories: CareTapSupabaseRepositorySet(transport: remoteTransport))
        let syncEngine = try! OfflineFirstSyncEngine(localTransport: localTransport, remoteGateway: remoteGateway)
        return SupabaseBackendRepository(syncEngine: syncEngine)
    }

    func fetchCareProfile(id: UUID) async throws -> CareProfile? {
        try await localRepositories.careProfiles.fetch(id: id)
    }

    func fetchMedications(careProfileID: UUID) async throws -> [Medication] {
        try await localRepositories.medications.medications(for: careProfileID)
    }

    func fetchDoseOccurrences(careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence] {
        try await localRepositories.doseOccurrences.occurrences(for: careProfileID, within: interval)
    }

    func fetchDoseLogs(occurrenceID: UUID) async throws -> [DoseLog] {
        try await localRepositories.doseLogs.logs(for: occurrenceID)
    }

    func syncSnapshot() async -> BackendSyncSnapshot {
        await syncEngine.snapshot()
    }

    func syncPendingChanges() async throws -> BackendSyncResult {
        try await syncEngine.sync()
    }

    func stage(_ mutations: CareTapSyncMutationBatch) async {
        await syncEngine.stage(mutations)
    }

    func redeemInvitation(
        token: String,
        caregiverUserID: UUID
    ) async throws -> CareTapInvitationRedemption {
        if let remoteTransport {
            struct RedemptionRequest: Encodable {
                let pInviteToken: String

                enum CodingKeys: String, CodingKey {
                    case pInviteToken = "p_invite_token"
                }
            }

            struct RedemptionResponse: Decodable {
                let careProfileID: UUID
                let relationshipID: UUID
                let invitationID: UUID
                let alertPolicyID: UUID

                enum CodingKeys: String, CodingKey {
                    case careProfileID = "care_profile_id"
                    case relationshipID = "relationship_id"
                    case invitationID = "invitation_id"
                    case alertPolicyID = "alert_policy_id"
                }
            }

            let responseRows: [RedemptionResponse] = try await remoteTransport.rpc(
                function: "caretap_redeem_invitation",
                body: RedemptionRequest(pInviteToken: token)
            )
            guard let response = responseRows.first else {
                throw CareTapServiceError.invalidInvite
            }
            _ = try await syncPendingChanges()
            return CareTapInvitationRedemption(
                careProfileID: response.careProfileID,
                relationshipID: response.relationshipID,
                invitationID: response.invitationID,
                alertPolicyID: response.alertPolicyID
            )
        }

        guard let invitation = try await localRepositories.invitations.invitation(token: token),
              invitation.status == .pending,
              invitation.expiresAt > .now else {
            throw CareTapServiceError.invalidInvite
        }

        let existingRelationship = try await localRepositories.careRelationships
            .relationships(for: caregiverUserID)
            .first { $0.careProfileID == invitation.careProfileID }

        let relationship = CareRelationship(
            id: existingRelationship?.id ?? UUID(),
            caregiverUserID: caregiverUserID,
            careProfileID: invitation.careProfileID,
            label: invitation.relationshipLabel,
            status: .active,
            permissions: [.viewAdherence, .logDose, .manageMedication, .manageAlerts],
            receivesMissedDoseAlerts: true,
            receivesRefillAlerts: true,
            createdAt: existingRelationship?.createdAt ?? .now,
            updatedAt: .now,
            acceptedAt: .now,
            syncState: .localOnly
        )
        let storedRelationship = try await localRepositories.careRelationships.upsert(relationship)

        let acceptedInvitation = Invitation(
            id: invitation.id,
            careProfileID: invitation.careProfileID,
            createdByUserID: invitation.createdByUserID,
            recipientDisplayName: invitation.recipientDisplayName,
            recipientContact: invitation.recipientContact,
            offeredRole: invitation.offeredRole,
            relationshipLabel: invitation.relationshipLabel,
            status: .accepted,
            inviteToken: invitation.inviteToken,
            expiresAt: invitation.expiresAt,
            acceptedAt: .now,
            createdAt: invitation.createdAt,
            updatedAt: .now,
            syncState: .localOnly
        )
        let storedInvitation = try await localRepositories.invitations.upsert(acceptedInvitation)

        let alertPolicy = AlertPolicy(
            id: UUID(),
            careRelationshipID: storedRelationship.id,
            notifyOnMissedDose: true,
            missedDoseDelayMinutes: 45,
            notifyOnLateDose: true,
            lateDoseDelayMinutes: 20,
            notifyOnSkippedDose: true,
            notifyOnRefillRisk: true,
            refillRiskThresholdDays: 4,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let storedPolicy = try await localRepositories.alertPolicies.upsert(alertPolicy)

        return CareTapInvitationRedemption(
            careProfileID: invitation.careProfileID,
            relationshipID: storedRelationship.id,
            invitationID: storedInvitation.id,
            alertPolicyID: storedPolicy.id
        )
    }

    func declineInvitation(token: String) async throws {
        if let remoteTransport {
            struct DeclineRequest: Encodable {
                let pInviteToken: String

                enum CodingKeys: String, CodingKey {
                    case pInviteToken = "p_invite_token"
                }
            }

            struct DeclineResponse: Decodable {
                let invitationID: UUID

                enum CodingKeys: String, CodingKey {
                    case invitationID = "invitation_id"
                }
            }

            let responseRows: [DeclineResponse] = try await remoteTransport.rpc(
                function: "caretap_decline_invitation",
                body: DeclineRequest(pInviteToken: token)
            )
            guard !responseRows.isEmpty else {
                throw CareTapServiceError.invalidInvite
            }
            _ = try await syncPendingChanges()
            return
        }

        guard let invitation = try await localRepositories.invitations.invitation(token: token),
              invitation.status == .pending,
              invitation.expiresAt > .now else {
            throw CareTapServiceError.invalidInvite
        }

        _ = try await localRepositories.invitations.upsert(
            Invitation(
                id: invitation.id,
                careProfileID: invitation.careProfileID,
                createdByUserID: invitation.createdByUserID,
                recipientDisplayName: invitation.recipientDisplayName,
                recipientContact: invitation.recipientContact,
                offeredRole: invitation.offeredRole,
                relationshipLabel: invitation.relationshipLabel,
                status: .declined,
                inviteToken: invitation.inviteToken,
                expiresAt: invitation.expiresAt,
                acceptedAt: nil,
                createdAt: invitation.createdAt,
                updatedAt: .now,
                syncState: .localOnly
            )
        )
    }
}

struct RepositoryBackedCaregiverRelationshipService: CaregiverRelationshipProviding, Sendable {
    let relationshipsRepository: any CareRelationshipRepositoryAccessing
    let invitationsRepository: any InvitationRepositoryAccessing

    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship] {
        try await relationshipsRepository.relationships(for: caregiverUserID)
    }

    func invitations(for careProfileID: UUID) async throws -> [Invitation] {
        try await invitationsRepository.invitations(for: careProfileID)
    }
}

extension CareTapSyncBatchPayload {
    static var phaseThreePreviewSeed: CareTapSyncBatchPayload {
        CareTapSyncBatchPayload(
            users: [UserRow(domainModel: CareTapPhaseThreePreviewScenarios.user)],
            careProfiles: [CareProfileRow(domainModel: CareTapPhaseThreePreviewScenarios.careProfile)],
            careRelationships: [CareRelationshipRow(domainModel: CareTapPhaseThreePreviewScenarios.careRelationship)],
            medications: [MedicationRow(domainModel: CareTapPhaseThreePreviewScenarios.medication)],
            scheduleRules: [ScheduleRuleRow(domainModel: CareTapPhaseThreePreviewScenarios.scheduleRule)],
            doseOccurrences: [
                DoseOccurrenceRow(domainModel: CareTapPhaseThreePreviewScenarios.dueNowOccurrence),
                DoseOccurrenceRow(domainModel: CareTapPhaseThreePreviewScenarios.overdueOccurrence),
                DoseOccurrenceRow(domainModel: CareTapPhaseThreePreviewScenarios.snoozedOccurrence),
                DoseOccurrenceRow(domainModel: CareTapPhaseThreePreviewScenarios.completedOccurrence)
            ],
            doseLogs: [DoseLogRow(domainModel: CareTapPhaseThreePreviewScenarios.acceptedDoseLog)],
            nfcTags: [NfcTagRow(domainModel: CareTapPhaseThreePreviewScenarios.nfcTag)],
            reminderPreferences: [ReminderPreferenceRow(domainModel: CareTapPhaseThreePreviewScenarios.reminderPreference)],
            alertPolicies: [AlertPolicyRow(domainModel: CareTapPhaseThreePreviewScenarios.alertPolicy)],
            refillStates: [RefillStateRow(domainModel: CareTapPhaseThreePreviewScenarios.refillState)],
            invitations: [InvitationRow(domainModel: CareTapPhaseThreePreviewScenarios.invitation)]
        )
    }
}
