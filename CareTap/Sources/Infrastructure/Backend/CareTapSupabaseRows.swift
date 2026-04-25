import Foundation

enum CareTapSupabaseSchema {
    static let currentVersion = 2
}

enum CareTapSupabaseTable: String, Codable, Hashable, CaseIterable {
    case users
    case careProfiles = "care_profiles"
    case careRelationships = "care_relationships"
    case medications
    case scheduleRules = "schedule_rules"
    case doseOccurrences = "dose_occurrences"
    case doseLogs = "dose_logs"
    case nfcTags = "nfc_tags"
    case reminderPreferences = "reminder_preferences"
    case alertPolicies = "alert_policies"
    case refillStates = "refill_states"
    case invitations
}

protocol CareTapSupabaseRow: Codable, Hashable, Identifiable {
    associatedtype DomainModel: CareTapRecord

    static var table: CareTapSupabaseTable { get }
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var deletedAt: Date? { get }
    var syncState: CareTapSyncState { get }
    var syncVersion: Int { get }
    var lastClientUpdatedAt: Date? { get }

    init(
        domainModel: DomainModel,
        deletedAt: Date?,
        syncVersion: Int,
        lastClientUpdatedAt: Date?
    )

    func toDomainModel() -> DomainModel
}

struct UserRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .users

    let id: UUID
    let authUserID: UUID?
    let appleSubject: String?
    let preferredRole: CareTapRole
    let displayName: String
    let initials: String
    let timezoneIdentifier: String
    let localeIdentifier: String
    let isSignInWithAppleLinked: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date?
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: User,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        authUserID = domainModel.authUserID
        appleSubject = domainModel.appleSubject
        preferredRole = domainModel.preferredRole
        displayName = domainModel.displayName
        initials = domainModel.initials
        timezoneIdentifier = domainModel.timezoneIdentifier
        localeIdentifier = domainModel.localeIdentifier
        isSignInWithAppleLinked = domainModel.isSignInWithAppleLinked
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        lastActiveAt = domainModel.lastActiveAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> User {
        User(
            id: id,
            authUserID: authUserID,
            appleSubject: appleSubject,
            preferredRole: preferredRole,
            displayName: displayName,
            initials: initials,
            timezoneIdentifier: timezoneIdentifier,
            localeIdentifier: localeIdentifier,
            isSignInWithAppleLinked: isSignInWithAppleLinked,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case authUserID = "auth_user_id"
        case appleSubject = "apple_subject"
        case preferredRole = "preferred_role"
        case displayName = "display_name"
        case initials
        case timezoneIdentifier = "timezone_identifier"
        case localeIdentifier = "locale_identifier"
        case isSignInWithAppleLinked = "is_sign_in_with_apple_linked"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActiveAt = "last_active_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct CareProfileRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .careProfiles

    let id: UUID
    let createdByUserID: UUID
    let patientUserID: UUID?
    let displayName: String
    let preferredName: String?
    let initials: String
    let avatarStyle: AvatarStyle
    let timezoneIdentifier: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: CareProfile,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        createdByUserID = domainModel.createdByUserID
        patientUserID = domainModel.patientUserID
        displayName = domainModel.displayName
        preferredName = domainModel.preferredName
        initials = domainModel.initials
        avatarStyle = domainModel.avatarStyle
        timezoneIdentifier = domainModel.timezoneIdentifier
        notes = domainModel.notes
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> CareProfile {
        CareProfile(
            id: id,
            createdByUserID: createdByUserID,
            patientUserID: patientUserID,
            displayName: displayName,
            preferredName: preferredName,
            initials: initials,
            avatarStyle: avatarStyle,
            timezoneIdentifier: timezoneIdentifier,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdByUserID = "created_by_user_id"
        case patientUserID = "patient_user_id"
        case displayName = "display_name"
        case preferredName = "preferred_name"
        case initials
        case avatarStyle = "avatar_style"
        case timezoneIdentifier = "timezone_identifier"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct CareRelationshipRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .careRelationships

    let id: UUID
    let caregiverUserID: UUID
    let careProfileID: UUID
    let label: CareRelationshipLabel
    let status: CareRelationshipStatus
    let permissions: [CareRelationshipPermission]
    let receivesMissedDoseAlerts: Bool
    let receivesRefillAlerts: Bool
    let createdAt: Date
    let updatedAt: Date
    let acceptedAt: Date?
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: CareRelationship,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        caregiverUserID = domainModel.caregiverUserID
        careProfileID = domainModel.careProfileID
        label = domainModel.label
        status = domainModel.status
        permissions = domainModel.permissions
        receivesMissedDoseAlerts = domainModel.receivesMissedDoseAlerts
        receivesRefillAlerts = domainModel.receivesRefillAlerts
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        acceptedAt = domainModel.acceptedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> CareRelationship {
        CareRelationship(
            id: id,
            caregiverUserID: caregiverUserID,
            careProfileID: careProfileID,
            label: label,
            status: status,
            permissions: permissions,
            receivesMissedDoseAlerts: receivesMissedDoseAlerts,
            receivesRefillAlerts: receivesRefillAlerts,
            createdAt: createdAt,
            updatedAt: updatedAt,
            acceptedAt: acceptedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case caregiverUserID = "caregiver_user_id"
        case careProfileID = "care_profile_id"
        case label
        case status
        case permissions
        case receivesMissedDoseAlerts = "receives_missed_dose_alerts"
        case receivesRefillAlerts = "receives_refill_alerts"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case acceptedAt = "accepted_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct MedicationRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .medications

    let id: UUID
    let careProfileID: UUID
    let nfcTagID: UUID?
    let name: String
    let category: MedicationCategory
    let dosage: String
    let doseQuantity: Double?
    let doseQuantityUnit: String?
    let instructions: String?
    let bottleLabel: String
    let bottlePhotoLocalPath: String?
    let form: MedicationForm
    let containerKind: ContainerKind
    let scheduleSummary: String
    let isActive: Bool
    let supplyCount: Double?
    let createdAt: Date
    let updatedAt: Date
    let archivedAt: Date?
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: Medication,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careProfileID = domainModel.careProfileID
        nfcTagID = domainModel.nfcTagID
        name = domainModel.name
        category = domainModel.category
        dosage = domainModel.dosage
        doseQuantity = domainModel.doseQuantity
        doseQuantityUnit = domainModel.doseQuantityUnit
        instructions = domainModel.instructions
        bottleLabel = domainModel.bottleLabel
        bottlePhotoLocalPath = domainModel.bottlePhotoLocalPath
        form = domainModel.form
        containerKind = domainModel.containerKind
        scheduleSummary = domainModel.scheduleSummary
        isActive = domainModel.isActive
        supplyCount = domainModel.supplyCount
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        archivedAt = domainModel.archivedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> Medication {
        Medication(
            id: id,
            careProfileID: careProfileID,
            nfcTagID: nfcTagID,
            name: name,
            category: category,
            dosage: dosage,
            doseQuantity: doseQuantity,
            doseQuantityUnit: doseQuantityUnit,
            instructions: instructions,
            bottleLabel: bottleLabel,
            bottlePhotoLocalPath: bottlePhotoLocalPath,
            form: form,
            containerKind: containerKind,
            scheduleSummary: scheduleSummary,
            isActive: isActive,
            supplyCount: supplyCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careProfileID = "care_profile_id"
        case nfcTagID = "nfc_tag_id"
        case name
        case category
        case dosage
        case doseQuantity = "dose_quantity"
        case doseQuantityUnit = "dose_quantity_unit"
        case instructions
        case bottleLabel = "bottle_label"
        case bottlePhotoLocalPath = "bottle_photo_local_path"
        case form
        case containerKind = "container_kind"
        case scheduleSummary = "schedule_summary"
        case isActive = "is_active"
        case supplyCount = "supply_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        careProfileID = try container.decode(UUID.self, forKey: .careProfileID)
        nfcTagID = try container.decodeIfPresent(UUID.self, forKey: .nfcTagID)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(MedicationCategory.self, forKey: .category) ?? .prescription
        dosage = try container.decode(String.self, forKey: .dosage)
        doseQuantity = try container.decodeIfPresent(Double.self, forKey: .doseQuantity)
        doseQuantityUnit = try container.decodeIfPresent(String.self, forKey: .doseQuantityUnit)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        bottleLabel = try container.decode(String.self, forKey: .bottleLabel)
        bottlePhotoLocalPath = try container.decodeIfPresent(String.self, forKey: .bottlePhotoLocalPath)
        form = try container.decode(MedicationForm.self, forKey: .form)
        containerKind = try container.decodeIfPresent(ContainerKind.self, forKey: .containerKind) ?? .bottle
        scheduleSummary = try container.decode(String.self, forKey: .scheduleSummary)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        supplyCount = try container.decodeIfPresent(Double.self, forKey: .supplyCount)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        syncState = try container.decode(CareTapSyncState.self, forKey: .syncState)
        syncVersion = try container.decodeIfPresent(Int.self, forKey: .syncVersion) ?? 0
        lastClientUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastClientUpdatedAt)
    }
}

struct ScheduleRuleRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .scheduleRules

    let id: UUID
    let medicationID: UUID
    let careProfileID: UUID
    let type: ScheduleRuleType
    let timezoneIdentifier: String
    let startsOn: Date
    let endsOn: Date?
    let daysOfWeek: [ScheduleWeekday]
    let timesOfDay: [ScheduleTimeOfDay]
    let intervalHours: Int?
    let gracePeriodMinutes: Int
    let snoozeDurationMinutes: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: ScheduleRule,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        medicationID = domainModel.medicationID
        careProfileID = domainModel.careProfileID
        type = domainModel.type
        timezoneIdentifier = domainModel.timezoneIdentifier
        startsOn = domainModel.startsOn
        endsOn = domainModel.endsOn
        daysOfWeek = domainModel.daysOfWeek
        timesOfDay = domainModel.timesOfDay
        intervalHours = domainModel.intervalHours
        gracePeriodMinutes = domainModel.gracePeriodMinutes
        snoozeDurationMinutes = domainModel.snoozeDurationMinutes
        isActive = domainModel.isActive
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> ScheduleRule {
        ScheduleRule(
            id: id,
            medicationID: medicationID,
            careProfileID: careProfileID,
            type: type,
            timezoneIdentifier: timezoneIdentifier,
            startsOn: startsOn,
            endsOn: endsOn,
            daysOfWeek: daysOfWeek,
            timesOfDay: timesOfDay,
            intervalHours: intervalHours,
            gracePeriodMinutes: gracePeriodMinutes,
            snoozeDurationMinutes: snoozeDurationMinutes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case medicationID = "medication_id"
        case careProfileID = "care_profile_id"
        case type
        case timezoneIdentifier = "timezone_identifier"
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case daysOfWeek = "days_of_week"
        case timesOfDay = "times_of_day"
        case intervalHours = "interval_hours"
        case gracePeriodMinutes = "grace_period_minutes"
        case snoozeDurationMinutes = "snooze_duration_minutes"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct DoseOccurrenceRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .doseOccurrences

    let id: UUID
    let careProfileID: UUID
    let medicationID: UUID
    let scheduleRuleID: UUID
    let scheduledAt: Date
    let windowOpensAt: Date
    let windowClosesAt: Date
    let snoozedUntil: Date?
    let status: DoseOccurrenceStatus
    let reminderState: ReminderEngagementState
    let flags: [DoseOccurrenceFlag]
    let resolvedByLogID: UUID?
    let resolvedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: DoseOccurrence,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careProfileID = domainModel.careProfileID
        medicationID = domainModel.medicationID
        scheduleRuleID = domainModel.scheduleRuleID
        scheduledAt = domainModel.scheduledAt
        windowOpensAt = domainModel.windowOpensAt
        windowClosesAt = domainModel.windowClosesAt
        snoozedUntil = domainModel.snoozedUntil
        status = domainModel.status
        reminderState = domainModel.reminderState
        flags = domainModel.flags
        resolvedByLogID = domainModel.resolvedByLogID
        resolvedAt = domainModel.resolvedAt
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> DoseOccurrence {
        DoseOccurrence(
            id: id,
            careProfileID: careProfileID,
            medicationID: medicationID,
            scheduleRuleID: scheduleRuleID,
            scheduledAt: scheduledAt,
            windowOpensAt: windowOpensAt,
            windowClosesAt: windowClosesAt,
            snoozedUntil: snoozedUntil,
            status: status,
            reminderState: reminderState,
            flags: flags,
            resolvedByLogID: resolvedByLogID,
            resolvedAt: resolvedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careProfileID = "care_profile_id"
        case medicationID = "medication_id"
        case scheduleRuleID = "schedule_rule_id"
        case scheduledAt = "scheduled_at"
        case windowOpensAt = "window_opens_at"
        case windowClosesAt = "window_closes_at"
        case snoozedUntil = "snoozed_until"
        case status
        case reminderState = "reminder_state"
        case flags
        case resolvedByLogID = "resolved_by_log_id"
        case resolvedAt = "resolved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct DoseLogRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .doseLogs

    let id: UUID
    let careProfileID: UUID
    let medicationID: UUID
    let occurrenceID: UUID?
    let actorUserID: UUID?
    let source: DoseLogSource
    let action: DoseLogAction
    let validationState: DoseLogValidationState
    let effectiveAt: Date
    let loggedAt: Date
    let note: String?
    let resolutionKind: DoseLogResolutionKind
    let resolutionReason: String?
    let undoesLogID: UUID?
    let supersedesLogID: UUID?
    let nfcTagID: UUID?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: DoseLog,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careProfileID = domainModel.careProfileID
        medicationID = domainModel.medicationID
        occurrenceID = domainModel.occurrenceID
        actorUserID = domainModel.actorUserID
        source = domainModel.source
        action = domainModel.action
        validationState = domainModel.validationState
        effectiveAt = domainModel.effectiveAt
        loggedAt = domainModel.loggedAt
        note = domainModel.note
        resolutionKind = domainModel.resolutionKind
        resolutionReason = domainModel.resolutionReason
        undoesLogID = domainModel.undoesLogID
        supersedesLogID = domainModel.supersedesLogID
        nfcTagID = domainModel.nfcTagID
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> DoseLog {
        DoseLog(
            id: id,
            careProfileID: careProfileID,
            medicationID: medicationID,
            occurrenceID: occurrenceID,
            actorUserID: actorUserID,
            source: source,
            action: action,
            validationState: validationState,
            effectiveAt: effectiveAt,
            loggedAt: loggedAt,
            note: note,
            resolutionKind: resolutionKind,
            resolutionReason: resolutionReason,
            undoesLogID: undoesLogID,
            supersedesLogID: supersedesLogID,
            nfcTagID: nfcTagID,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careProfileID = "care_profile_id"
        case medicationID = "medication_id"
        case occurrenceID = "occurrence_id"
        case actorUserID = "actor_user_id"
        case source
        case action
        case validationState = "validation_state"
        case effectiveAt = "effective_at"
        case loggedAt = "logged_at"
        case note
        case resolutionKind = "resolution_kind"
        case resolutionReason = "resolution_reason"
        case undoesLogID = "undoes_log_id"
        case supersedesLogID = "supersedes_log_id"
        case nfcTagID = "nfc_tag_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        careProfileID = try container.decode(UUID.self, forKey: .careProfileID)
        medicationID = try container.decode(UUID.self, forKey: .medicationID)
        occurrenceID = try container.decodeIfPresent(UUID.self, forKey: .occurrenceID)
        actorUserID = try container.decodeIfPresent(UUID.self, forKey: .actorUserID)
        source = try container.decode(DoseLogSource.self, forKey: .source)
        action = try container.decode(DoseLogAction.self, forKey: .action)
        validationState = try container.decode(DoseLogValidationState.self, forKey: .validationState)
        effectiveAt = try container.decode(Date.self, forKey: .effectiveAt)
        loggedAt = try container.decode(Date.self, forKey: .loggedAt)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        resolutionKind = try container.decodeIfPresent(DoseLogResolutionKind.self, forKey: .resolutionKind) ?? .standard
        resolutionReason = try container.decodeIfPresent(String.self, forKey: .resolutionReason)
        undoesLogID = try container.decodeIfPresent(UUID.self, forKey: .undoesLogID)
        supersedesLogID = try container.decodeIfPresent(UUID.self, forKey: .supersedesLogID)
        nfcTagID = try container.decodeIfPresent(UUID.self, forKey: .nfcTagID)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        syncState = try container.decode(CareTapSyncState.self, forKey: .syncState)
        syncVersion = try container.decodeIfPresent(Int.self, forKey: .syncVersion) ?? 0
        lastClientUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastClientUpdatedAt)
    }
}

struct NfcTagRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .nfcTags

    let id: UUID
    let careProfileID: UUID
    let medicationID: UUID?
    let stableUID: String
    let payloadIdentifier: String
    let label: String
    let status: NfcTagStatus
    let pairedAt: Date?
    let lastReadAt: Date?
    let lastWrittenAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: NfcTag,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careProfileID = domainModel.careProfileID
        medicationID = domainModel.medicationID
        stableUID = domainModel.stableUID
        payloadIdentifier = domainModel.payloadIdentifier
        label = domainModel.label
        status = domainModel.status
        pairedAt = domainModel.pairedAt
        lastReadAt = domainModel.lastReadAt
        lastWrittenAt = domainModel.lastWrittenAt
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> NfcTag {
        NfcTag(
            id: id,
            careProfileID: careProfileID,
            medicationID: medicationID,
            stableUID: stableUID,
            payloadIdentifier: payloadIdentifier,
            label: label,
            status: status,
            pairedAt: pairedAt,
            lastReadAt: lastReadAt,
            lastWrittenAt: lastWrittenAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careProfileID = "care_profile_id"
        case medicationID = "medication_id"
        case stableUID = "stable_uid"
        case payloadIdentifier = "payload_identifier"
        case label
        case status
        case pairedAt = "paired_at"
        case lastReadAt = "last_read_at"
        case lastWrittenAt = "last_written_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct ReminderPreferenceRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .reminderPreferences

    let id: UUID
    let userID: UUID
    let careProfileID: UUID
    let channels: [ReminderChannel]
    let leadTimeMinutes: Int
    let followUpAfterMinutes: Int?
    let maxFollowUps: Int
    let quietHours: QuietHours?
    let enablesLiveActivity: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: ReminderPreference,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        userID = domainModel.userID
        careProfileID = domainModel.careProfileID
        channels = domainModel.channels
        leadTimeMinutes = domainModel.leadTimeMinutes
        followUpAfterMinutes = domainModel.followUpAfterMinutes
        maxFollowUps = domainModel.maxFollowUps
        quietHours = domainModel.quietHours
        enablesLiveActivity = domainModel.enablesLiveActivity
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> ReminderPreference {
        ReminderPreference(
            id: id,
            userID: userID,
            careProfileID: careProfileID,
            channels: channels,
            leadTimeMinutes: leadTimeMinutes,
            followUpAfterMinutes: followUpAfterMinutes,
            maxFollowUps: maxFollowUps,
            quietHours: quietHours,
            enablesLiveActivity: enablesLiveActivity,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case careProfileID = "care_profile_id"
        case channels
        case leadTimeMinutes = "lead_time_minutes"
        case followUpAfterMinutes = "follow_up_after_minutes"
        case maxFollowUps = "max_follow_ups"
        case quietHours = "quiet_hours"
        case enablesLiveActivity = "enables_live_activity"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct AlertPolicyRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .alertPolicies

    let id: UUID
    let careRelationshipID: UUID
    let notifyOnMissedDose: Bool
    let missedDoseDelayMinutes: Int
    let notifyOnLateDose: Bool
    let lateDoseDelayMinutes: Int
    let notifyOnSkippedDose: Bool
    let notifyOnRefillRisk: Bool
    let refillRiskThresholdDays: Int
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: AlertPolicy,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careRelationshipID = domainModel.careRelationshipID
        notifyOnMissedDose = domainModel.notifyOnMissedDose
        missedDoseDelayMinutes = domainModel.missedDoseDelayMinutes
        notifyOnLateDose = domainModel.notifyOnLateDose
        lateDoseDelayMinutes = domainModel.lateDoseDelayMinutes
        notifyOnSkippedDose = domainModel.notifyOnSkippedDose
        notifyOnRefillRisk = domainModel.notifyOnRefillRisk
        refillRiskThresholdDays = domainModel.refillRiskThresholdDays
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> AlertPolicy {
        AlertPolicy(
            id: id,
            careRelationshipID: careRelationshipID,
            notifyOnMissedDose: notifyOnMissedDose,
            missedDoseDelayMinutes: missedDoseDelayMinutes,
            notifyOnLateDose: notifyOnLateDose,
            lateDoseDelayMinutes: lateDoseDelayMinutes,
            notifyOnSkippedDose: notifyOnSkippedDose,
            notifyOnRefillRisk: notifyOnRefillRisk,
            refillRiskThresholdDays: refillRiskThresholdDays,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careRelationshipID = "care_relationship_id"
        case notifyOnMissedDose = "notify_on_missed_dose"
        case missedDoseDelayMinutes = "missed_dose_delay_minutes"
        case notifyOnLateDose = "notify_on_late_dose"
        case lateDoseDelayMinutes = "late_dose_delay_minutes"
        case notifyOnSkippedDose = "notify_on_skipped_dose"
        case notifyOnRefillRisk = "notify_on_refill_risk"
        case refillRiskThresholdDays = "refill_risk_threshold_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct RefillStateRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .refillStates

    let id: UUID
    let medicationID: UUID
    let quantityOnHand: Double?
    let dosesRemainingEstimate: Int
    let estimatedRunOutDate: Date?
    let riskLevel: RefillRiskLevel
    let lastCalculatedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: RefillState,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        medicationID = domainModel.medicationID
        quantityOnHand = domainModel.quantityOnHand
        dosesRemainingEstimate = domainModel.dosesRemainingEstimate
        estimatedRunOutDate = domainModel.estimatedRunOutDate
        riskLevel = domainModel.riskLevel
        lastCalculatedAt = domainModel.lastCalculatedAt
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> RefillState {
        RefillState(
            id: id,
            medicationID: medicationID,
            quantityOnHand: quantityOnHand,
            dosesRemainingEstimate: dosesRemainingEstimate,
            estimatedRunOutDate: estimatedRunOutDate,
            riskLevel: riskLevel,
            lastCalculatedAt: lastCalculatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case medicationID = "medication_id"
        case quantityOnHand = "quantity_on_hand"
        case dosesRemainingEstimate = "doses_remaining_estimate"
        case estimatedRunOutDate = "estimated_run_out_date"
        case riskLevel = "risk_level"
        case lastCalculatedAt = "last_calculated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}

struct InvitationRow: CareTapSupabaseRow {
    static let table: CareTapSupabaseTable = .invitations

    let id: UUID
    let careProfileID: UUID
    let createdByUserID: UUID
    let recipientDisplayName: String?
    let recipientContact: String
    let offeredRole: CareTapRole
    let relationshipLabel: CareRelationshipLabel
    let status: InvitationStatus
    let inviteToken: String
    let expiresAt: Date
    let acceptedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncState: CareTapSyncState
    let syncVersion: Int
    let lastClientUpdatedAt: Date?

    init(
        domainModel: Invitation,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        lastClientUpdatedAt: Date? = nil
    ) {
        id = domainModel.id
        careProfileID = domainModel.careProfileID
        createdByUserID = domainModel.createdByUserID
        recipientDisplayName = domainModel.recipientDisplayName
        recipientContact = domainModel.recipientContact
        offeredRole = domainModel.offeredRole
        relationshipLabel = domainModel.relationshipLabel
        status = domainModel.status
        inviteToken = domainModel.inviteToken
        expiresAt = domainModel.expiresAt
        acceptedAt = domainModel.acceptedAt
        createdAt = domainModel.createdAt
        updatedAt = domainModel.updatedAt
        self.deletedAt = deletedAt
        syncState = domainModel.syncState
        self.syncVersion = syncVersion
        self.lastClientUpdatedAt = lastClientUpdatedAt ?? domainModel.updatedAt
    }

    func toDomainModel() -> Invitation {
        Invitation(
            id: id,
            careProfileID: careProfileID,
            createdByUserID: createdByUserID,
            recipientDisplayName: recipientDisplayName,
            recipientContact: recipientContact,
            offeredRole: offeredRole,
            relationshipLabel: relationshipLabel,
            status: status,
            inviteToken: inviteToken,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncState: syncState
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case careProfileID = "care_profile_id"
        case createdByUserID = "created_by_user_id"
        case recipientDisplayName = "recipient_display_name"
        case recipientContact = "recipient_contact"
        case offeredRole = "offered_role"
        case relationshipLabel = "relationship_label"
        case status
        case inviteToken = "invite_token"
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncState = "sync_state"
        case syncVersion = "sync_version"
        case lastClientUpdatedAt = "last_client_updated_at"
    }
}
