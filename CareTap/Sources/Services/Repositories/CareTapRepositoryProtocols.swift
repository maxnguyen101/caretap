import Foundation

protocol UserRepositoryAccessing: Sendable {
    func fetch(id: UUID) async throws -> User?
    func fetchByAuthUserID(_ authUserID: UUID) async throws -> User?
    func upsert(_ user: User) async throws -> User
    func fetchModified(since date: Date?) async throws -> [User]
}

protocol CareProfileRepositoryAccessing: Sendable {
    func fetch(id: UUID) async throws -> CareProfile?
    func profiles(createdBy userID: UUID) async throws -> [CareProfile]
    func upsert(_ profile: CareProfile) async throws -> CareProfile
    func fetchModified(since date: Date?) async throws -> [CareProfile]
}

protocol CareRelationshipRepositoryAccessing: Sendable {
    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship]
    func relationships(forCareProfileID careProfileID: UUID) async throws -> [CareRelationship]
    func upsert(_ relationship: CareRelationship) async throws -> CareRelationship
    func fetchModified(since date: Date?) async throws -> [CareRelationship]
}

protocol MedicationRepositoryAccessing: Sendable {
    func medications(for careProfileID: UUID) async throws -> [Medication]
    func upsert(_ medication: Medication) async throws -> Medication
    func fetchModified(since date: Date?) async throws -> [Medication]
}

protocol ScheduleRuleRepositoryAccessing: Sendable {
    func rules(for medicationID: UUID) async throws -> [ScheduleRule]
    func upsert(_ rule: ScheduleRule) async throws -> ScheduleRule
    func fetchModified(since date: Date?) async throws -> [ScheduleRule]
}

protocol DoseOccurrenceRepositoryAccessing: Sendable {
    func occurrences(for careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence]
    func upsert(_ occurrence: DoseOccurrence) async throws -> DoseOccurrence
    func fetchModified(since date: Date?) async throws -> [DoseOccurrence]
}

protocol DoseLogRepositoryAccessing: Sendable {
    func logs(for occurrenceID: UUID) async throws -> [DoseLog]
    func upsert(_ log: DoseLog) async throws -> DoseLog
    func fetchModified(since date: Date?) async throws -> [DoseLog]
}

protocol NFCTagRepositoryAccessing: Sendable {
    func tag(stableUID: String) async throws -> NfcTag?
    func tag(payloadIdentifier: String) async throws -> NfcTag?
    func upsert(_ tag: NfcTag) async throws -> NfcTag
    func fetchModified(since date: Date?) async throws -> [NfcTag]
}

protocol ReminderPreferenceRepositoryAccessing: Sendable {
    func preference(for userID: UUID, careProfileID: UUID) async throws -> ReminderPreference?
    func upsert(_ preference: ReminderPreference) async throws -> ReminderPreference
    func fetchModified(since date: Date?) async throws -> [ReminderPreference]
}

protocol AlertPolicyRepositoryAccessing: Sendable {
    func policies(for relationshipID: UUID) async throws -> [AlertPolicy]
    func upsert(_ policy: AlertPolicy) async throws -> AlertPolicy
    func fetchModified(since date: Date?) async throws -> [AlertPolicy]
}

protocol RefillStateRepositoryAccessing: Sendable {
    func refillState(for medicationID: UUID) async throws -> RefillState?
    func upsert(_ state: RefillState) async throws -> RefillState
    func fetchModified(since date: Date?) async throws -> [RefillState]
}

protocol InvitationRepositoryAccessing: Sendable {
    func invitations(for careProfileID: UUID) async throws -> [Invitation]
    func invitation(token: String) async throws -> Invitation?
    func upsert(_ invitation: Invitation) async throws -> Invitation
    func fetchModified(since date: Date?) async throws -> [Invitation]
}

protocol CareTapSyncGateway: Sendable {
    func pull(since cursor: CareTapSyncCursor?) async throws -> CareTapSyncPullResponse
    func push(_ request: CareTapSyncPushRequest) async throws -> CareTapSyncPushResponse
}
