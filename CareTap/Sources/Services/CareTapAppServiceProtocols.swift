import Foundation

protocol CareTapRecordStoring: Sendable {
    func syncSnapshot() async -> BackendSyncSnapshot
    func syncPendingChanges() async throws -> BackendSyncResult

    func fetchUser(id: UUID) async throws -> User?
    func fetchUser(authUserID: UUID) async throws -> User?
    func upsertUser(_ user: User) async throws -> User

    func fetchCareProfile(id: UUID) async throws -> CareProfile?
    func careProfiles(createdBy userID: UUID) async throws -> [CareProfile]
    func upsertCareProfile(_ profile: CareProfile) async throws -> CareProfile

    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship]
    func relationships(forCareProfileID careProfileID: UUID) async throws -> [CareRelationship]
    func upsertCareRelationship(_ relationship: CareRelationship) async throws -> CareRelationship

    func medications(for careProfileID: UUID) async throws -> [Medication]
    func upsertMedication(_ medication: Medication) async throws -> Medication

    func rules(for medicationID: UUID) async throws -> [ScheduleRule]
    func upsertScheduleRule(_ rule: ScheduleRule) async throws -> ScheduleRule

    func occurrences(for careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence]
    func upsertDoseOccurrence(_ occurrence: DoseOccurrence) async throws -> DoseOccurrence

    func logs(for occurrenceID: UUID) async throws -> [DoseLog]
    func upsertDoseLog(_ log: DoseLog) async throws -> DoseLog

    func tag(stableUID: String) async throws -> NfcTag?
    func tag(payloadIdentifier: String) async throws -> NfcTag?
    func upsertNfcTag(_ tag: NfcTag) async throws -> NfcTag

    func preference(for userID: UUID, careProfileID: UUID) async throws -> ReminderPreference?
    func upsertReminderPreference(_ preference: ReminderPreference) async throws -> ReminderPreference

    func policies(for relationshipID: UUID) async throws -> [AlertPolicy]
    func upsertAlertPolicy(_ policy: AlertPolicy) async throws -> AlertPolicy

    func refillState(for medicationID: UUID) async throws -> RefillState?
    func upsertRefillState(_ state: RefillState) async throws -> RefillState

    func invitations(for careProfileID: UUID) async throws -> [Invitation]
    func invitation(token: String) async throws -> Invitation?
    func redeemInvitation(token: String, caregiverUserID: UUID) async throws -> CareTapInvitationRedemption
    func declineInvitation(token: String) async throws
    func upsertInvitation(_ invitation: Invitation) async throws -> Invitation
}

struct CareTapInvitationRedemption: Hashable, Sendable {
    let careProfileID: UUID
    let relationshipID: UUID
    let invitationID: UUID
    let alertPolicyID: UUID
}
