import Foundation

enum CareTapServiceError: Error {
    case unavailable
    case invalidTag
    case missingRecord
    case notAuthorized
    case authenticationFailed
    case invalidInvite
    case notificationPermissionDenied
}

struct NFCTagWriteRequest: Hashable {
    let careProfileID: UUID
    let medicationID: UUID
    let label: String
    let stableUID: String
    let payloadIdentifier: String
}

struct NFCTagReadResult: Hashable {
    let tag: NfcTag
    let matchedMedicationID: UUID?
}

struct NFCTagWriteResult: Hashable {
    let tag: NfcTag
    let pairingState: NFCPairingPhase
}

protocol NFCTagServicing: Sendable {
    func scanTag() async throws -> NFCTagReadResult
    func readTag(stableUID: String) async throws -> NFCTagReadResult
    func writeTag(_ request: NFCTagWriteRequest) async throws -> NFCTagWriteResult
}

struct DoseLoggingRequest: Hashable {
    let actorUserID: UUID?
    let source: DoseLogSource
    let action: DoseLogAction
    let loggedAt: Date
    let note: String?
    let resolutionReason: String?
    let undoesLogID: UUID?
    let nfcTagID: UUID?

    init(
        actorUserID: UUID?,
        source: DoseLogSource,
        action: DoseLogAction,
        loggedAt: Date,
        note: String?,
        resolutionReason: String? = nil,
        undoesLogID: UUID? = nil,
        nfcTagID: UUID?
    ) {
        self.actorUserID = actorUserID
        self.source = source
        self.action = action
        self.loggedAt = loggedAt
        self.note = note
        self.resolutionReason = resolutionReason
        self.undoesLogID = undoesLogID
        self.nfcTagID = nfcTagID
    }
}

struct DoseLoggingResult: Hashable {
    let occurrence: DoseOccurrence
    let log: DoseLog
}

protocol DoseLoggingServicing: Sendable {
    func logDose(for occurrence: DoseOccurrence, request: DoseLoggingRequest) async throws -> DoseLoggingResult
}

struct ReminderSchedulePlan: Identifiable, Codable, Hashable {
    let id: UUID
    let occurrenceID: UUID
    let channel: ReminderChannel
    let fireDate: Date
    let title: String
    let body: String
    let primaryActionLabel: String

    init(
        id: UUID = UUID(),
        occurrenceID: UUID,
        channel: ReminderChannel,
        fireDate: Date,
        title: String,
        body: String,
        primaryActionLabel: String
    ) {
        self.id = id
        self.occurrenceID = occurrenceID
        self.channel = channel
        self.fireDate = fireDate
        self.title = title
        self.body = body
        self.primaryActionLabel = primaryActionLabel
    }
}

protocol ReminderScheduling: Sendable {
    func scheduleReminders(
        for occurrence: DoseOccurrence,
        medication: Medication,
        preference: ReminderPreference
    ) async throws -> [ReminderSchedulePlan]

    func cancelReminders(for occurrenceID: UUID) async throws
}

enum AuthenticationSessionState: String, Hashable {
    case signedOut = "signed_out"
    case locallyAuthorized = "locally_authorized"
    case linkedForSync = "linked_for_sync"
}

struct AuthenticationSessionSnapshot: Hashable {
    let state: AuthenticationSessionState
    let user: User?
    let lastUpdatedAt: Date
}

struct AppleIdentityTokenPayload: Hashable {
    let idToken: String
    let rawNonce: String
    let authorizationCode: String?
    let appleSubject: String
    let email: String?
    let givenName: String?
    let familyName: String?
}

struct EmailPasswordCredential: Hashable {
    let email: String
    let password: String
    let displayName: String?
}

protocol AuthCoordinating: Sendable {
    func sessionSnapshot() async -> AuthenticationSessionSnapshot
    func signInWithApple(with payload: AppleIdentityTokenPayload, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot
    func signUpWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot
    func signInWithEmail(_ credential: EmailPasswordCredential, preferredRole: CareTapRole) async throws -> AuthenticationSessionSnapshot
    func signOut() async
    func deleteAccount() async throws
}

typealias AppleSignInAuthCoordinating = AuthCoordinating

struct BackendSyncConflict: Identifiable, Codable, Hashable {
    let id: UUID
    let entityName: String
    let entityID: UUID
    let summary: String

    init(id: UUID = UUID(), entityName: String, entityID: UUID, summary: String) {
        self.id = id
        self.entityName = entityName
        self.entityID = entityID
        self.summary = summary
    }
}

struct BackendSyncSnapshot: Hashable {
    let lastSyncAt: Date?
    let pendingUploadCount: Int
    let conflictCount: Int
}

struct BackendSyncResult: Hashable {
    let uploadedCount: Int
    let downloadedCount: Int
    let conflicts: [BackendSyncConflict]
}

protocol BackendRepositoryAccessing: Sendable {
    func fetchCareProfile(id: UUID) async throws -> CareProfile?
    func fetchMedications(careProfileID: UUID) async throws -> [Medication]
    func fetchDoseOccurrences(careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence]
    func fetchDoseLogs(occurrenceID: UUID) async throws -> [DoseLog]
    func syncSnapshot() async -> BackendSyncSnapshot
    func syncPendingChanges() async throws -> BackendSyncResult
}

protocol CaregiverRelationshipProviding: Sendable {
    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship]
    func invitations(for careProfileID: UUID) async throws -> [Invitation]
}

protocol MedicationScheduleGenerating: Sendable {
    func generateOccurrences(
        for medication: Medication,
        rules: [ScheduleRule],
        within interval: DateInterval
    ) -> [DoseOccurrence]
}

protocol RefillEstimating: Sendable {
    func estimateRefillState(
        for medication: Medication,
        rules: [ScheduleRule],
        asOf referenceDate: Date
    ) -> RefillState
}

protocol PremiumSubscriptionServicing: Sendable {
    func prepare() async
    func snapshot() async -> CareTapPremiumSnapshot
    func purchase(plan: CareTapPremiumPlan) async throws -> CareTapPremiumPurchaseOutcome
    func restorePurchases() async throws -> CareTapPremiumSnapshot
}
