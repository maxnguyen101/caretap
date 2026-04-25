import Foundation

struct SupabaseTableRepository<Row: CareTapSupabaseRow>: @unchecked Sendable {
    let transport: SupabaseTransporting

    func fetch(id: UUID, includeDeleted: Bool = false) async throws -> Row? {
        try await list(filters: [
            SupabaseFilter(column: "id", operator: .equal, value: .uuid(id))
        ], limit: 1, includeDeleted: includeDeleted).first
    }

    func list(
        filters: [SupabaseFilter] = [],
        orderBy: SupabaseSort? = nil,
        limit: Int? = nil,
        includeDeleted: Bool = false
    ) async throws -> [Row] {
        let rows: [Row] = try await transport.select(from: Row.table, filters: filters, orderBy: orderBy, limit: limit)
        return includeDeleted ? rows : rows.filter { $0.deletedAt == nil }
    }

    func fetchModified(since date: Date?) async throws -> [Row] {
        var filters: [SupabaseFilter] = []
        if let date {
            filters.append(SupabaseFilter(column: "updated_at", operator: .greaterThanOrEqual, value: .date(date)))
        }

        return try await list(
            filters: filters,
            orderBy: SupabaseSort(column: "updated_at", ascending: true),
            includeDeleted: true
        )
    }

    func upsert(_ row: Row) async throws -> Row {
        let response = try await transport.upsert([row], into: Row.table, onConflict: ["id"])
        guard let stored = response.first else {
            throw CareTapServiceError.unavailable
        }
        return stored
    }

    func upsert(_ rows: [Row]) async throws -> [Row] {
        try await transport.upsert(rows, into: Row.table, onConflict: ["id"])
    }
}

struct SupabaseUserRepository: UserRepositoryAccessing {
    let table: SupabaseTableRepository<UserRow>

    func fetch(id: UUID) async throws -> User? {
        try await table.fetch(id: id)?.toDomainModel()
    }

    func fetchByAuthUserID(_ authUserID: UUID) async throws -> User? {
        try await table.list(
            filters: [SupabaseFilter(column: "auth_user_id", operator: .equal, value: .uuid(authUserID))],
            limit: 1
        ).first?.toDomainModel()
    }

    func upsert(_ user: User) async throws -> User {
        try await table.upsert(UserRow(domainModel: user)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [User] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseCareProfileRepository: CareProfileRepositoryAccessing {
    let table: SupabaseTableRepository<CareProfileRow>

    func fetch(id: UUID) async throws -> CareProfile? {
        try await table.fetch(id: id)?.toDomainModel()
    }

    func profiles(createdBy userID: UUID) async throws -> [CareProfile] {
        try await table.list(filters: [
            SupabaseFilter(column: "created_by_user_id", operator: .equal, value: .uuid(userID))
        ], orderBy: SupabaseSort(column: "updated_at", ascending: false)).map { $0.toDomainModel() }
    }

    func upsert(_ profile: CareProfile) async throws -> CareProfile {
        try await table.upsert(CareProfileRow(domainModel: profile)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [CareProfile] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseCareRelationshipRepository: CareRelationshipRepositoryAccessing {
    let table: SupabaseTableRepository<CareRelationshipRow>

    func relationships(for caregiverUserID: UUID) async throws -> [CareRelationship] {
        try await table.list(filters: [
            SupabaseFilter(column: "caregiver_user_id", operator: .equal, value: .uuid(caregiverUserID))
        ], orderBy: SupabaseSort(column: "updated_at", ascending: false)).map { $0.toDomainModel() }
    }

    func relationships(forCareProfileID careProfileID: UUID) async throws -> [CareRelationship] {
        try await table.list(filters: [
            SupabaseFilter(column: "care_profile_id", operator: .equal, value: .uuid(careProfileID))
        ], orderBy: SupabaseSort(column: "updated_at", ascending: false)).map { $0.toDomainModel() }
    }

    func upsert(_ relationship: CareRelationship) async throws -> CareRelationship {
        try await table.upsert(CareRelationshipRow(domainModel: relationship)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [CareRelationship] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseMedicationRepository: MedicationRepositoryAccessing {
    let table: SupabaseTableRepository<MedicationRow>

    func medications(for careProfileID: UUID) async throws -> [Medication] {
        try await table.list(filters: [
            SupabaseFilter(column: "care_profile_id", operator: .equal, value: .uuid(careProfileID))
        ], orderBy: SupabaseSort(column: "updated_at", ascending: false)).map { $0.toDomainModel() }
    }

    func upsert(_ medication: Medication) async throws -> Medication {
        try await table.upsert(MedicationRow(domainModel: medication)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [Medication] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseScheduleRuleRepository: ScheduleRuleRepositoryAccessing {
    let table: SupabaseTableRepository<ScheduleRuleRow>

    func rules(for medicationID: UUID) async throws -> [ScheduleRule] {
        try await table.list(filters: [
            SupabaseFilter(column: "medication_id", operator: .equal, value: .uuid(medicationID))
        ], orderBy: SupabaseSort(column: "starts_on", ascending: true)).map { $0.toDomainModel() }
    }

    func upsert(_ rule: ScheduleRule) async throws -> ScheduleRule {
        try await table.upsert(ScheduleRuleRow(domainModel: rule)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [ScheduleRule] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseDoseOccurrenceRepository: DoseOccurrenceRepositoryAccessing {
    let table: SupabaseTableRepository<DoseOccurrenceRow>

    func occurrences(for careProfileID: UUID, within interval: DateInterval) async throws -> [DoseOccurrence] {
        try await table.list(filters: [
            SupabaseFilter(column: "care_profile_id", operator: .equal, value: .uuid(careProfileID)),
            SupabaseFilter(column: "scheduled_at", operator: .greaterThanOrEqual, value: .date(interval.start)),
            SupabaseFilter(column: "scheduled_at", operator: .lessThanOrEqual, value: .date(interval.end))
        ], orderBy: SupabaseSort(column: "scheduled_at", ascending: true)).map { $0.toDomainModel() }
    }

    func upsert(_ occurrence: DoseOccurrence) async throws -> DoseOccurrence {
        try await table.upsert(DoseOccurrenceRow(domainModel: occurrence)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [DoseOccurrence] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseDoseLogRepository: DoseLogRepositoryAccessing {
    let table: SupabaseTableRepository<DoseLogRow>

    func logs(for occurrenceID: UUID) async throws -> [DoseLog] {
        try await table.list(filters: [
            SupabaseFilter(column: "occurrence_id", operator: .equal, value: .uuid(occurrenceID))
        ], orderBy: SupabaseSort(column: "logged_at", ascending: true)).map { $0.toDomainModel() }
    }

    func upsert(_ log: DoseLog) async throws -> DoseLog {
        try await table.upsert(DoseLogRow(domainModel: log)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [DoseLog] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseNFCTagRepository: NFCTagRepositoryAccessing {
    let table: SupabaseTableRepository<NfcTagRow>

    func tag(stableUID: String) async throws -> NfcTag? {
        try await table.list(filters: [
            SupabaseFilter(column: "stable_uid", operator: .equal, value: .string(stableUID))
        ], limit: 1).first?.toDomainModel()
    }

    func tag(payloadIdentifier: String) async throws -> NfcTag? {
        try await table.list(filters: [
            SupabaseFilter(column: "payload_identifier", operator: .equal, value: .string(payloadIdentifier))
        ], limit: 1).first?.toDomainModel()
    }

    func upsert(_ tag: NfcTag) async throws -> NfcTag {
        try await table.upsert(NfcTagRow(domainModel: tag)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [NfcTag] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseReminderPreferenceRepository: ReminderPreferenceRepositoryAccessing {
    let table: SupabaseTableRepository<ReminderPreferenceRow>

    func preference(for userID: UUID, careProfileID: UUID) async throws -> ReminderPreference? {
        try await table.list(filters: [
            SupabaseFilter(column: "user_id", operator: .equal, value: .uuid(userID)),
            SupabaseFilter(column: "care_profile_id", operator: .equal, value: .uuid(careProfileID))
        ], limit: 1).first?.toDomainModel()
    }

    func upsert(_ preference: ReminderPreference) async throws -> ReminderPreference {
        try await table.upsert(ReminderPreferenceRow(domainModel: preference)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [ReminderPreference] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseAlertPolicyRepository: AlertPolicyRepositoryAccessing {
    let table: SupabaseTableRepository<AlertPolicyRow>

    func policies(for relationshipID: UUID) async throws -> [AlertPolicy] {
        try await table.list(filters: [
            SupabaseFilter(column: "care_relationship_id", operator: .equal, value: .uuid(relationshipID))
        ], orderBy: SupabaseSort(column: "updated_at", ascending: false)).map { $0.toDomainModel() }
    }

    func upsert(_ policy: AlertPolicy) async throws -> AlertPolicy {
        try await table.upsert(AlertPolicyRow(domainModel: policy)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [AlertPolicy] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseRefillStateRepository: RefillStateRepositoryAccessing {
    let table: SupabaseTableRepository<RefillStateRow>

    func refillState(for medicationID: UUID) async throws -> RefillState? {
        try await table.list(filters: [
            SupabaseFilter(column: "medication_id", operator: .equal, value: .uuid(medicationID))
        ], limit: 1).first?.toDomainModel()
    }

    func upsert(_ state: RefillState) async throws -> RefillState {
        try await table.upsert(RefillStateRow(domainModel: state)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [RefillState] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct SupabaseInvitationRepository: InvitationRepositoryAccessing {
    let table: SupabaseTableRepository<InvitationRow>

    func invitations(for careProfileID: UUID) async throws -> [Invitation] {
        try await table.list(filters: [
            SupabaseFilter(column: "care_profile_id", operator: .equal, value: .uuid(careProfileID))
        ], orderBy: SupabaseSort(column: "created_at", ascending: false)).map { $0.toDomainModel() }
    }

    func invitation(token: String) async throws -> Invitation? {
        try await table.list(
            filters: [SupabaseFilter(column: "invite_token", operator: .equal, value: .string(token))],
            limit: 1,
            includeDeleted: false
        ).first?.toDomainModel()
    }

    func upsert(_ invitation: Invitation) async throws -> Invitation {
        try await table.upsert(InvitationRow(domainModel: invitation)).toDomainModel()
    }

    func fetchModified(since date: Date?) async throws -> [Invitation] {
        try await table.fetchModified(since: date).map { $0.toDomainModel() }
    }
}

struct CareTapSupabaseRepositorySet: @unchecked Sendable {
    let usersTable: SupabaseTableRepository<UserRow>
    let careProfilesTable: SupabaseTableRepository<CareProfileRow>
    let careRelationshipsTable: SupabaseTableRepository<CareRelationshipRow>
    let medicationsTable: SupabaseTableRepository<MedicationRow>
    let scheduleRulesTable: SupabaseTableRepository<ScheduleRuleRow>
    let doseOccurrencesTable: SupabaseTableRepository<DoseOccurrenceRow>
    let doseLogsTable: SupabaseTableRepository<DoseLogRow>
    let nfcTagsTable: SupabaseTableRepository<NfcTagRow>
    let reminderPreferencesTable: SupabaseTableRepository<ReminderPreferenceRow>
    let alertPoliciesTable: SupabaseTableRepository<AlertPolicyRow>
    let refillStatesTable: SupabaseTableRepository<RefillStateRow>
    let invitationsTable: SupabaseTableRepository<InvitationRow>

    let users: any UserRepositoryAccessing
    let careProfiles: any CareProfileRepositoryAccessing
    let careRelationships: any CareRelationshipRepositoryAccessing
    let medications: any MedicationRepositoryAccessing
    let scheduleRules: any ScheduleRuleRepositoryAccessing
    let doseOccurrences: any DoseOccurrenceRepositoryAccessing
    let doseLogs: any DoseLogRepositoryAccessing
    let nfcTags: any NFCTagRepositoryAccessing
    let reminderPreferences: any ReminderPreferenceRepositoryAccessing
    let alertPolicies: any AlertPolicyRepositoryAccessing
    let refillStates: any RefillStateRepositoryAccessing
    let invitations: any InvitationRepositoryAccessing

    init(transport: SupabaseTransporting) {
        let usersTable = SupabaseTableRepository<UserRow>(transport: transport)
        let careProfilesTable = SupabaseTableRepository<CareProfileRow>(transport: transport)
        let careRelationshipsTable = SupabaseTableRepository<CareRelationshipRow>(transport: transport)
        let medicationsTable = SupabaseTableRepository<MedicationRow>(transport: transport)
        let scheduleRulesTable = SupabaseTableRepository<ScheduleRuleRow>(transport: transport)
        let doseOccurrencesTable = SupabaseTableRepository<DoseOccurrenceRow>(transport: transport)
        let doseLogsTable = SupabaseTableRepository<DoseLogRow>(transport: transport)
        let nfcTagsTable = SupabaseTableRepository<NfcTagRow>(transport: transport)
        let reminderPreferencesTable = SupabaseTableRepository<ReminderPreferenceRow>(transport: transport)
        let alertPoliciesTable = SupabaseTableRepository<AlertPolicyRow>(transport: transport)
        let refillStatesTable = SupabaseTableRepository<RefillStateRow>(transport: transport)
        let invitationsTable = SupabaseTableRepository<InvitationRow>(transport: transport)

        self.usersTable = usersTable
        self.careProfilesTable = careProfilesTable
        self.careRelationshipsTable = careRelationshipsTable
        self.medicationsTable = medicationsTable
        self.scheduleRulesTable = scheduleRulesTable
        self.doseOccurrencesTable = doseOccurrencesTable
        self.doseLogsTable = doseLogsTable
        self.nfcTagsTable = nfcTagsTable
        self.reminderPreferencesTable = reminderPreferencesTable
        self.alertPoliciesTable = alertPoliciesTable
        self.refillStatesTable = refillStatesTable
        self.invitationsTable = invitationsTable

        users = SupabaseUserRepository(table: usersTable)
        careProfiles = SupabaseCareProfileRepository(table: careProfilesTable)
        careRelationships = SupabaseCareRelationshipRepository(table: careRelationshipsTable)
        medications = SupabaseMedicationRepository(table: medicationsTable)
        scheduleRules = SupabaseScheduleRuleRepository(table: scheduleRulesTable)
        doseOccurrences = SupabaseDoseOccurrenceRepository(table: doseOccurrencesTable)
        doseLogs = SupabaseDoseLogRepository(table: doseLogsTable)
        nfcTags = SupabaseNFCTagRepository(table: nfcTagsTable)
        reminderPreferences = SupabaseReminderPreferenceRepository(table: reminderPreferencesTable)
        alertPolicies = SupabaseAlertPolicyRepository(table: alertPoliciesTable)
        refillStates = SupabaseRefillStateRepository(table: refillStatesTable)
        invitations = SupabaseInvitationRepository(table: invitationsTable)
    }
}
