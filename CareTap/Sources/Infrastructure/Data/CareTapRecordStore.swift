import Foundation

final class RepositoryBackedCareTapRecordStore: CareTapRecordStoring, @unchecked Sendable {
    private let backend: SupabaseBackendRepository

    init(backend: SupabaseBackendRepository) {
        self.backend = backend
    }

    private var repositories: CareTapSupabaseRepositorySet {
        backend.localRepositories
    }

    func syncSnapshot() async -> BackendSyncSnapshot {
        await backend.syncSnapshot()
    }

    func syncPendingChanges() async throws -> BackendSyncResult {
        try await backend.syncPendingChanges()
    }

    func fetchUser(id: UUID) async throws -> User? {
        try await repositories.users.fetch(id: id)
    }

    func fetchUser(authUserID: UUID) async throws -> User? {
        try await repositories.users.fetchByAuthUserID(authUserID)
    }

    func upsertUser(_ user: User) async throws -> User {
        let stored = try await repositories.users.upsert(user)
        await backend.stage(
            CareTapSyncMutationBatch(
                users: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: UserRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func fetchCareProfile(id: UUID) async throws -> CareProfile? {
        try await repositories.careProfiles.fetch(id: id)
    }

    func careProfiles(createdBy userID: UUID) async throws -> [CareProfile] {
        try await repositories.careProfiles.profiles(createdBy: userID)
    }

    func upsertCareProfile(_ profile: CareProfile) async throws -> CareProfile {
        let stored = try await repositories.careProfiles.upsert(profile)
        await backend.stage(
            CareTapSyncMutationBatch(
                careProfiles: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: CareProfileRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship] {
        try await repositories.careRelationships.relationships(for: caregiverUserID)
    }

    func relationships(forCareProfileID careProfileID: UUID) async throws -> [CareRelationship] {
        try await repositories.careRelationships.relationships(forCareProfileID: careProfileID)
    }

    func upsertCareRelationship(_ relationship: CareRelationship) async throws -> CareRelationship {
        let stored = try await repositories.careRelationships.upsert(relationship)
        await backend.stage(
            CareTapSyncMutationBatch(
                careRelationships: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: CareRelationshipRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func medications(for careProfileID: UUID) async throws -> [Medication] {
        try await repositories.medications.medications(for: careProfileID)
    }

    func upsertMedication(_ medication: Medication) async throws -> Medication {
        let stored = try await repositories.medications.upsert(medication)
        await backend.stage(
            CareTapSyncMutationBatch(
                medications: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: MedicationRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func rules(for medicationID: UUID) async throws -> [ScheduleRule] {
        try await repositories.scheduleRules.rules(for: medicationID)
    }

    func upsertScheduleRule(_ rule: ScheduleRule) async throws -> ScheduleRule {
        let stored = try await repositories.scheduleRules.upsert(rule)
        await backend.stage(
            CareTapSyncMutationBatch(
                scheduleRules: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: ScheduleRuleRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func occurrences(for careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence] {
        try await repositories.doseOccurrences.occurrences(for: careProfileID, within: interval)
    }

    func upsertDoseOccurrence(_ occurrence: DoseOccurrence) async throws -> DoseOccurrence {
        let stored = try await repositories.doseOccurrences.upsert(occurrence)
        await backend.stage(
            CareTapSyncMutationBatch(
                doseOccurrences: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: DoseOccurrenceRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func logs(for occurrenceID: UUID) async throws -> [DoseLog] {
        try await repositories.doseLogs.logs(for: occurrenceID)
    }

    func upsertDoseLog(_ log: DoseLog) async throws -> DoseLog {
        let stored = try await repositories.doseLogs.upsert(log)
        await backend.stage(
            CareTapSyncMutationBatch(
                doseLogs: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: DoseLogRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func tag(stableUID: String) async throws -> NfcTag? {
        try await repositories.nfcTags.tag(stableUID: stableUID)
    }

    func tag(payloadIdentifier: String) async throws -> NfcTag? {
        try await repositories.nfcTags.tag(payloadIdentifier: payloadIdentifier)
    }

    func upsertNfcTag(_ tag: NfcTag) async throws -> NfcTag {
        let stored = try await repositories.nfcTags.upsert(tag)
        await backend.stage(
            CareTapSyncMutationBatch(
                nfcTags: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: NfcTagRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func preference(for userID: UUID, careProfileID: UUID) async throws -> ReminderPreference? {
        try await repositories.reminderPreferences.preference(for: userID, careProfileID: careProfileID)
    }

    func upsertReminderPreference(_ preference: ReminderPreference) async throws -> ReminderPreference {
        let stored = try await repositories.reminderPreferences.upsert(preference)
        await backend.stage(
            CareTapSyncMutationBatch(
                reminderPreferences: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: ReminderPreferenceRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func policies(for relationshipID: UUID) async throws -> [AlertPolicy] {
        try await repositories.alertPolicies.policies(for: relationshipID)
    }

    func upsertAlertPolicy(_ policy: AlertPolicy) async throws -> AlertPolicy {
        let stored = try await repositories.alertPolicies.upsert(policy)
        await backend.stage(
            CareTapSyncMutationBatch(
                alertPolicies: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: AlertPolicyRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func refillState(for medicationID: UUID) async throws -> RefillState? {
        try await repositories.refillStates.refillState(for: medicationID)
    }

    func upsertRefillState(_ state: RefillState) async throws -> RefillState {
        let stored = try await repositories.refillStates.upsert(state)
        await backend.stage(
            CareTapSyncMutationBatch(
                refillStates: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: RefillStateRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }

    func invitations(for careProfileID: UUID) async throws -> [Invitation] {
        try await repositories.invitations.invitations(for: careProfileID)
    }

    func invitation(token: String) async throws -> Invitation? {
        try await repositories.invitations.invitation(token: token)
    }

    func redeemInvitation(token: String, caregiverUserID: UUID) async throws -> CareTapInvitationRedemption {
        try await backend.redeemInvitation(token: token, caregiverUserID: caregiverUserID)
    }

    func declineInvitation(token: String) async throws {
        try await backend.declineInvitation(token: token)
    }

    func upsertInvitation(_ invitation: Invitation) async throws -> Invitation {
        let stored = try await repositories.invitations.upsert(invitation)
        await backend.stage(
            CareTapSyncMutationBatch(
                invitations: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: stored.updatedAt,
                        row: InvitationRow(domainModel: stored)
                    )
                ]
            )
        )
        return stored
    }
}
