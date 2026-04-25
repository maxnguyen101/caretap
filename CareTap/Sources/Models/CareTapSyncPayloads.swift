import Foundation

enum CareTapSyncOperation: String, Codable, Hashable {
    case upsert
    case delete
}

struct CareTapSyncCursor: Codable, Hashable {
    let schemaVersion: Int
    let lastSyncedAt: Date?

    init(schemaVersion: Int = CareTapSupabaseSchema.currentVersion, lastSyncedAt: Date?) {
        self.schemaVersion = schemaVersion
        self.lastSyncedAt = lastSyncedAt
    }
}

struct CareTapSyncMutation<Row: Codable & Hashable>: Identifiable, Codable, Hashable {
    let id: UUID
    let operation: CareTapSyncOperation
    let queuedAt: Date
    let clientUpdatedAt: Date
    let row: Row

    init(
        id: UUID = UUID(),
        operation: CareTapSyncOperation,
        queuedAt: Date = .now,
        clientUpdatedAt: Date,
        row: Row
    ) {
        self.id = id
        self.operation = operation
        self.queuedAt = queuedAt
        self.clientUpdatedAt = clientUpdatedAt
        self.row = row
    }
}

struct CareTapSyncMutationBatch: Codable, Hashable {
    var users: [CareTapSyncMutation<UserRow>] = []
    var careProfiles: [CareTapSyncMutation<CareProfileRow>] = []
    var careRelationships: [CareTapSyncMutation<CareRelationshipRow>] = []
    var medications: [CareTapSyncMutation<MedicationRow>] = []
    var scheduleRules: [CareTapSyncMutation<ScheduleRuleRow>] = []
    var doseOccurrences: [CareTapSyncMutation<DoseOccurrenceRow>] = []
    var doseLogs: [CareTapSyncMutation<DoseLogRow>] = []
    var nfcTags: [CareTapSyncMutation<NfcTagRow>] = []
    var reminderPreferences: [CareTapSyncMutation<ReminderPreferenceRow>] = []
    var alertPolicies: [CareTapSyncMutation<AlertPolicyRow>] = []
    var refillStates: [CareTapSyncMutation<RefillStateRow>] = []
    var invitations: [CareTapSyncMutation<InvitationRow>] = []

    static var empty: CareTapSyncMutationBatch { CareTapSyncMutationBatch() }

    var isEmpty: Bool {
        totalMutationCount == 0
    }

    var totalMutationCount: Int {
        users.count
            + careProfiles.count
            + careRelationships.count
            + medications.count
            + scheduleRules.count
            + doseOccurrences.count
            + doseLogs.count
            + nfcTags.count
            + reminderPreferences.count
            + alertPolicies.count
            + refillStates.count
            + invitations.count
    }
}

struct CareTapSyncBatchPayload: Codable, Hashable {
    var users: [UserRow] = []
    var careProfiles: [CareProfileRow] = []
    var careRelationships: [CareRelationshipRow] = []
    var medications: [MedicationRow] = []
    var scheduleRules: [ScheduleRuleRow] = []
    var doseOccurrences: [DoseOccurrenceRow] = []
    var doseLogs: [DoseLogRow] = []
    var nfcTags: [NfcTagRow] = []
    var reminderPreferences: [ReminderPreferenceRow] = []
    var alertPolicies: [AlertPolicyRow] = []
    var refillStates: [RefillStateRow] = []
    var invitations: [InvitationRow] = []

    static var empty: CareTapSyncBatchPayload { CareTapSyncBatchPayload() }

    var isEmpty: Bool {
        totalRowCount == 0
    }

    var totalRowCount: Int {
        users.count
            + careProfiles.count
            + careRelationships.count
            + medications.count
            + scheduleRules.count
            + doseOccurrences.count
            + doseLogs.count
            + nfcTags.count
            + reminderPreferences.count
            + alertPolicies.count
            + refillStates.count
            + invitations.count
    }
}

struct CareTapSyncConflictPayload: Identifiable, Codable, Hashable {
    let id: UUID
    let table: CareTapSupabaseTable
    let recordID: UUID
    let summary: String
    let serverUpdatedAt: Date?
    let clientUpdatedAt: Date?

    init(
        id: UUID = UUID(),
        table: CareTapSupabaseTable,
        recordID: UUID,
        summary: String,
        serverUpdatedAt: Date? = nil,
        clientUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.table = table
        self.recordID = recordID
        self.summary = summary
        self.serverUpdatedAt = serverUpdatedAt
        self.clientUpdatedAt = clientUpdatedAt
    }
}

struct CareTapSyncPushRequest: Codable, Hashable {
    let cursor: CareTapSyncCursor?
    let mutations: CareTapSyncMutationBatch
}

struct CareTapSyncPushResponse: Codable, Hashable {
    let cursor: CareTapSyncCursor
    let acceptedMutationCount: Int
    let appliedChanges: CareTapSyncBatchPayload
    let conflicts: [CareTapSyncConflictPayload]
}

struct CareTapSyncPullResponse: Codable, Hashable {
    let cursor: CareTapSyncCursor
    let changes: CareTapSyncBatchPayload
    let conflicts: [CareTapSyncConflictPayload]
}
