import Foundation

protocol CareTapRecord: Identifiable, Codable, Hashable {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var syncState: CareTapSyncState { get }
}

enum CareTapSyncState: String, Codable, Hashable, CaseIterable {
    case localOnly = "local_only"
    case pendingUpload = "pending_upload"
    case synced
    case pendingDeletion = "pending_deletion"
    case conflict
}

enum CareRelationshipLabel: String, Codable, Hashable, CaseIterable {
    case selfManaged = "self_managed"
    case spouse
    case parent
    case child
    case sibling
    case friend
    case neighbor
    case professionalCarePartner = "professional_care_partner"
}

enum CareRelationshipStatus: String, Codable, Hashable, CaseIterable {
    case invited
    case active
    case paused
    case revoked
}

enum CareRelationshipPermission: String, Codable, Hashable, CaseIterable {
    case viewAdherence = "view_adherence"
    case logDose = "log_dose"
    case manageMedication = "manage_medication"
    case manageAlerts = "manage_alerts"
    case manageInvitations = "manage_invitations"
}

enum MedicationForm: String, Codable, Hashable, CaseIterable {
    case bottle
    case pillOrganizer = "pill_organizer"
    case blisterPack = "blister_pack"
    case liquid
    case injection
    case inhaler
    case other
}

enum MedicationCategory: String, Codable, Hashable, CaseIterable {
    case prescription
    case otc
    case supplement

    var title: String {
        switch self {
        case .prescription:
            return "Prescription"
        case .otc:
            return "Everyday"
        case .supplement:
            return "Supplement"
        }
    }
}

enum ContainerKind: String, Codable, Hashable, CaseIterable {
    case bottle
    case organizer
    case tray
    case packet

    var title: String {
        switch self {
        case .bottle:
            return "Bottle"
        case .organizer:
            return "Organizer"
        case .tray:
            return "Tray"
        case .packet:
            return "Packet"
        }
    }

    var symbolName: String {
        switch self {
        case .bottle:
            return "waterbottle.fill"
        case .organizer:
            return "square.grid.2x2.fill"
        case .tray:
            return "tray.full.fill"
        case .packet:
            return "shippingbox.fill"
        }
    }
}

enum ScheduleRuleType: String, Codable, Hashable, CaseIterable {
    case daily
    case weekly
    case interval
    case asNeeded = "as_needed"
}

enum ScheduleWeekday: Int, Codable, Hashable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

struct ScheduleTimeOfDay: Identifiable, Codable, Hashable {
    let id: UUID
    let hour: Int
    let minute: Int
    let label: String?

    init(id: UUID = UUID(), hour: Int, minute: Int, label: String? = nil) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
    }
}

enum DoseOccurrenceStatus: String, Codable, Hashable, CaseIterable {
    case scheduled
    case dueNow = "due_now"
    case overdue
    case snoozed
    case completed
    case late
    case missed
    case skipped
    case resolved
}

enum DoseOccurrenceFlag: String, Codable, Hashable, CaseIterable {
    case late
    case missed
    case duplicate
    case tooEarly = "too_early"
    case skipped
    case resolved
}

enum ReminderEngagementState: String, Codable, Hashable, CaseIterable {
    case notScheduled = "not_scheduled"
    case scheduled
    case delivered
    case dismissed
    case actionTaken = "action_taken"
    case escalated
}

enum DoseLogSource: String, Codable, Hashable, CaseIterable {
    case nfcTap = "nfc_tap"
    case manualPatientConfirmation = "manual_patient_confirmation"
    case caregiverLogged = "caregiver_logged"
    case laterCorrection = "later_correction"
}

enum DoseLogAction: String, Codable, Hashable, CaseIterable {
    case confirmTaken = "confirm_taken"
    case markSkipped = "mark_skipped"
    case correctEntry = "correct_entry"
}

enum DoseLogResolutionKind: String, Codable, Hashable, CaseIterable {
    case standard
    case lateConfirmation = "late_confirmation"
    case skippedWithReason = "skipped_with_reason"
    case correctedEntry = "corrected_entry"
    case undo = "undo"
}

enum DoseLogValidationState: String, Codable, Hashable, CaseIterable {
    case accepted
    case duplicate
    case tooEarly = "too_early"
    case superseded
    case rejected
}

enum NfcTagStatus: String, Codable, Hashable, CaseIterable {
    case ready
    case paired
    case retired
    case error
}

enum ReminderChannel: String, Codable, Hashable, CaseIterable {
    case localNotification = "local_notification"
    case liveActivity = "live_activity"
    case caregiverEscalation = "caregiver_escalation"
}

enum RefillRiskLevel: String, Codable, Hashable, CaseIterable {
    case onTrack = "on_track"
    case watch
    case urgent
    case depleted
}

enum InvitationStatus: String, Codable, Hashable, CaseIterable {
    case pending
    case accepted
    case declined
    case expired
    case revoked
}

struct QuietHours: Codable, Hashable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
}

struct User: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct CareProfile: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct CareRelationship: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct Medication: CareTapRecord {
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
    let syncState: CareTapSyncState

    init(
        id: UUID,
        careProfileID: UUID,
        nfcTagID: UUID?,
        name: String,
        category: MedicationCategory = .prescription,
        dosage: String,
        doseQuantity: Double?,
        doseQuantityUnit: String?,
        instructions: String?,
        bottleLabel: String,
        bottlePhotoLocalPath: String?,
        form: MedicationForm,
        containerKind: ContainerKind = .bottle,
        scheduleSummary: String,
        isActive: Bool,
        supplyCount: Double?,
        createdAt: Date,
        updatedAt: Date,
        archivedAt: Date?,
        syncState: CareTapSyncState
    ) {
        self.id = id
        self.careProfileID = careProfileID
        self.nfcTagID = nfcTagID
        self.name = name
        self.category = category
        self.dosage = dosage
        self.doseQuantity = doseQuantity
        self.doseQuantityUnit = doseQuantityUnit
        self.instructions = instructions
        self.bottleLabel = bottleLabel
        self.bottlePhotoLocalPath = bottlePhotoLocalPath
        self.form = form
        self.containerKind = containerKind
        self.scheduleSummary = scheduleSummary
        self.isActive = isActive
        self.supplyCount = supplyCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
        self.syncState = syncState
    }

    var displayTitle: String {
        "\(name) \(dosage)"
    }
}

struct ScheduleRule: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct DoseOccurrence: CareTapRecord {
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
    let syncState: CareTapSyncState

    var isResolved: Bool {
        switch status {
        case .completed, .late, .missed, .skipped, .resolved:
            return true
        case .scheduled, .dueNow, .overdue, .snoozed:
            return false
        }
    }

    var reminderDismissalDoesNotCountAsTaken: Bool {
        reminderState == .dismissed && !isResolved
    }
}

struct DoseLog: CareTapRecord {
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
    let syncState: CareTapSyncState

    init(
        id: UUID,
        careProfileID: UUID,
        medicationID: UUID,
        occurrenceID: UUID?,
        actorUserID: UUID?,
        source: DoseLogSource,
        action: DoseLogAction,
        validationState: DoseLogValidationState,
        effectiveAt: Date,
        loggedAt: Date,
        note: String?,
        resolutionKind: DoseLogResolutionKind = .standard,
        resolutionReason: String? = nil,
        undoesLogID: UUID? = nil,
        supersedesLogID: UUID?,
        nfcTagID: UUID?,
        createdAt: Date,
        updatedAt: Date,
        syncState: CareTapSyncState
    ) {
        self.id = id
        self.careProfileID = careProfileID
        self.medicationID = medicationID
        self.occurrenceID = occurrenceID
        self.actorUserID = actorUserID
        self.source = source
        self.action = action
        self.validationState = validationState
        self.effectiveAt = effectiveAt
        self.loggedAt = loggedAt
        self.note = note
        self.resolutionKind = resolutionKind
        self.resolutionReason = resolutionReason
        self.undoesLogID = undoesLogID
        self.supersedesLogID = supersedesLogID
        self.nfcTagID = nfcTagID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncState = syncState
    }

    var provesMedicationTaken: Bool {
        action == .confirmTaken && validationState == .accepted
    }
}

struct NfcTag: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct ReminderPreference: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct AlertPolicy: CareTapRecord {
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
    let syncState: CareTapSyncState
}

struct RefillState: CareTapRecord {
    let id: UUID
    let medicationID: UUID
    let quantityOnHand: Double?
    let dosesRemainingEstimate: Int
    let estimatedRunOutDate: Date?
    let riskLevel: RefillRiskLevel
    let lastCalculatedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let syncState: CareTapSyncState
}

struct Invitation: CareTapRecord {
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
    let syncState: CareTapSyncState
}
