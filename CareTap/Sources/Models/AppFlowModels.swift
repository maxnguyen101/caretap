import Foundation

enum CareTapRootRoute: Hashable {
    case launching
    case onboarding(CareTapOnboardingRoute)
    case patient
    case caregiver
}

enum CareTapOnboardingRoute: Hashable {
    case roleSelection
    case patientSetup(PatientSetupStep)
    case caregiverWelcome
}

enum PatientSetupStep: String, Codable, Hashable, CaseIterable {
    case item
    case routine
    case tapSetup

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "item", "addMedication":
            self = .item
        case "routine", "schedule":
            self = .routine
        case "tapSetup", "nfcPairing", "completion":
            self = .tapSetup
        default:
            self = .item
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum PatientWorkspaceSection: String, Codable, Hashable, CaseIterable {
    case items
    case history

    var title: String {
        switch self {
        case .items:
            return "Items"
        case .history:
            return "History"
        }
    }
}

enum CaregiverWorkspaceSection: String, Codable, Hashable, CaseIterable {
    case people
    case history

    var title: String {
        switch self {
        case .people:
            return "People"
        case .history:
            return "History"
        }
    }
}

enum DoseConfirmationConfidenceLevel: String, Codable, Hashable, CaseIterable {
    case bottleTap = "bottle_tap"
    case selfConfirmed = "self_confirmed"
    case caregiverLogged = "caregiver_logged"
    case correctedLater = "corrected_later"
    case unresolved

    var title: String {
        switch self {
        case .bottleTap:
            return "Tag tap"
        case .selfConfirmed:
            return "Checked in here"
        case .caregiverLogged:
            return "Support person logged"
        case .correctedLater:
            return "Corrected later"
        case .unresolved:
            return "Unresolved"
        }
    }

    var detail: String {
        switch self {
        case .bottleTap:
            return "Highest confidence confirmation"
        case .selfConfirmed:
            return "Confirmed on this device"
        case .caregiverLogged:
            return "Logged on behalf of someone else"
        case .correctedLater:
            return "Adjusted after the original event"
        case .unresolved:
            return "No confirming log yet"
        }
    }

    var tone: CareTapTone {
        switch self {
        case .bottleTap:
            return .success
        case .selfConfirmed:
            return .sage
        case .caregiverLogged:
            return .mist
        case .correctedLater:
            return .warm
        case .unresolved:
            return .neutral
        }
    }
}

struct CareTapExactDoseTime: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let symbolName: String
    let hour: Int
    let minute: Int

    init(
        id: UUID = UUID(),
        title: String,
        symbolName: String,
        hour: Int,
        minute: Int
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.hour = hour
        self.minute = minute
    }
}

enum ScheduleFrequency: String, Codable, Hashable, CaseIterable {
    case onceDaily
    case twiceDaily
    case threeTimesDaily
    case everyXHours
    case specificWeekdays
    case asNeeded

    var displayTitle: String {
        switch self {
        case .onceDaily: "Once daily"
        case .twiceDaily: "Twice daily"
        case .threeTimesDaily: "3x daily"
        case .everyXHours: "Every X hours"
        case .specificWeekdays: "Specific days"
        case .asNeeded: "As needed"
        }
    }

    var symbolName: String {
        switch self {
        case .onceDaily: "1.circle.fill"
        case .twiceDaily: "2.circle.fill"
        case .threeTimesDaily: "3.circle.fill"
        case .everyXHours: "clock.arrow.2.circlepath"
        case .specificWeekdays: "calendar"
        case .asNeeded: "hand.tap"
        }
    }
}

struct PatientSetupDraft: Codable, Hashable {
    var medicationName: String
    var medicationCategory: MedicationCategory
    var dosage: String
    var instructions: String
    var bottleLabel: String
    var containerKind: ContainerKind
    var searchQuery: String
    var selectedSuggestionID: UUID?
    var selectedTimeTitles: [String]
    var exactTimes: [CareTapExactDoseTime]
    var startsOn: Date
    var bottlePhotoLocalPath: String?
    var reminderLeadTimeMinutes: Int
    var quietHoursEnabled: Bool
    var scheduleFrequency: ScheduleFrequency
    var intervalHours: Int
    var selectedWeekdays: [Int]
    var takeWithFood: Bool?
    var supplyCount: Int
    var lowSupplyThreshold: Int

    static func empty(referenceDate: Date = .now) -> PatientSetupDraft {
        PatientSetupDraft(
            medicationName: "",
            medicationCategory: .prescription,
            dosage: "",
            instructions: "",
            bottleLabel: "Primary bottle",
            containerKind: .bottle,
            searchQuery: "",
            selectedSuggestionID: nil,
            selectedTimeTitles: ["Morning"],
            exactTimes: [
                CareTapExactDoseTime(title: "Morning", symbolName: "sun.max.fill", hour: 8, minute: 0)
            ],
            startsOn: referenceDate,
            bottlePhotoLocalPath: nil,
            reminderLeadTimeMinutes: 0,
            quietHoursEnabled: true,
            scheduleFrequency: .onceDaily,
            intervalHours: 8,
            selectedWeekdays: [],
            takeWithFood: nil,
            supplyCount: 30,
            lowSupplyThreshold: 5
        )
    }
}

struct CareTapPersistedAppState: Codable, Hashable {
    var selectedRole: CareTapRole?
    var localUserID: UUID?
    var activeCareProfileID: UUID?
    var selectedDestination: CareTapDestination
    var patientWorkspaceSection: PatientWorkspaceSection
    var caregiverWorkspaceSection: CaregiverWorkspaceSection
    var patientSetupDraft: PatientSetupDraft
    var patientSetupStep: PatientSetupStep
    var hasCompletedPatientSetup: Bool
    var hasCompletedCaregiverSetup: Bool
    /// Tracks whether the user has run through the Shortcuts automation setup
    /// wizard at least once. Drives the automation hint banner in the tap
    /// confirmation sheet.
    var hasConfirmedNFCAutomation: Bool

    private enum CodingKeys: String, CodingKey {
        case selectedRole
        case localUserID
        case activeCareProfileID
        case selectedDestination
        case patientWorkspaceSection
        case caregiverWorkspaceSection
        case patientSetupDraft
        case patientSetupStep
        case hasCompletedPatientSetup
        case hasCompletedCaregiverSetup
        case hasConfirmedNFCAutomation
    }

    init(
        selectedRole: CareTapRole?,
        localUserID: UUID?,
        activeCareProfileID: UUID?,
        selectedDestination: CareTapDestination,
        patientWorkspaceSection: PatientWorkspaceSection,
        caregiverWorkspaceSection: CaregiverWorkspaceSection,
        patientSetupDraft: PatientSetupDraft,
        patientSetupStep: PatientSetupStep,
        hasCompletedPatientSetup: Bool,
        hasCompletedCaregiverSetup: Bool,
        hasConfirmedNFCAutomation: Bool = false
    ) {
        self.selectedRole = selectedRole
        self.localUserID = localUserID
        self.activeCareProfileID = activeCareProfileID
        self.selectedDestination = selectedDestination
        self.patientWorkspaceSection = patientWorkspaceSection
        self.caregiverWorkspaceSection = caregiverWorkspaceSection
        self.patientSetupDraft = patientSetupDraft
        self.patientSetupStep = patientSetupStep
        self.hasCompletedPatientSetup = hasCompletedPatientSetup
        self.hasCompletedCaregiverSetup = hasCompletedCaregiverSetup
        self.hasConfirmedNFCAutomation = hasConfirmedNFCAutomation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedRole = try container.decodeIfPresent(CareTapRole.self, forKey: .selectedRole)
        localUserID = try container.decodeIfPresent(UUID.self, forKey: .localUserID)
        activeCareProfileID = try container.decodeIfPresent(UUID.self, forKey: .activeCareProfileID)
        selectedDestination = try container.decodeIfPresent(CareTapDestination.self, forKey: .selectedDestination) ?? .home
        patientWorkspaceSection = try container.decodeIfPresent(PatientWorkspaceSection.self, forKey: .patientWorkspaceSection) ?? .items
        caregiverWorkspaceSection = try container.decodeIfPresent(CaregiverWorkspaceSection.self, forKey: .caregiverWorkspaceSection) ?? .people
        patientSetupDraft = try container.decodeIfPresent(PatientSetupDraft.self, forKey: .patientSetupDraft) ?? .empty()
        patientSetupStep = try container.decodeIfPresent(PatientSetupStep.self, forKey: .patientSetupStep) ?? .item
        hasCompletedPatientSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedPatientSetup) ?? false
        hasCompletedCaregiverSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedCaregiverSetup) ?? false
        hasConfirmedNFCAutomation = try container.decodeIfPresent(Bool.self, forKey: .hasConfirmedNFCAutomation) ?? false
    }

    static func `default`() -> CareTapPersistedAppState {
        CareTapPersistedAppState(
            selectedRole: nil,
            localUserID: nil,
            activeCareProfileID: nil,
            selectedDestination: .home,
            patientWorkspaceSection: .items,
            caregiverWorkspaceSection: .people,
            patientSetupDraft: .empty(),
            patientSetupStep: .item,
            hasCompletedPatientSetup: false,
            hasCompletedCaregiverSetup: false,
            hasConfirmedNFCAutomation: false
        )
    }
}

struct ScheduleSetupTimeState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let symbolName: String
    let hour: Int
    let minute: Int
    let displayTime: String

    init(id: UUID = UUID(), title: String, symbolName: String, hour: Int, minute: Int, displayTime: String) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.hour = hour
        self.minute = minute
        self.displayTime = displayTime
    }
}

struct ScheduleSetupViewState: Hashable {
    let stepText: String
    let title: String
    let message: String
    let medicationName: String
    let category: MedicationCategory
    let dosage: String
    let bottleLabel: String
    let containerKind: ContainerKind
    let instructions: String
    let dosageTitle: String
    let containerTitle: String
    let notesTitle: String
    let timingHelperText: String
    let photoSectionTitle: String
    let selectedTimes: [ScheduleSetupTimeState]
    let startDate: Date
    let startDateText: String
    let reminderSummary: String
    let hasBottlePhoto: Bool
    let photoCaption: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
    var scheduleFrequency: ScheduleFrequency = .onceDaily
    var intervalHours: Int = 8
    var selectedWeekdays: [Int] = []
    var takeWithFood: Bool? = nil
    var supplyCount: Int = 30
    var lowSupplyThreshold: Int = 5
}

struct SetupCompletionViewState: Hashable {
    let title: String
    let message: String
    let summaryItems: [String]
    let primaryActionTitle: String
}

struct CaregiverWelcomeViewState: Hashable {
    let title: String
    let message: String
    let inviteInstructions: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
}

struct CareTapNoticeItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let tone: CareTapTone
    let createdAt: Date
    var isUnread: Bool

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        tone: CareTapTone,
        createdAt: Date = .now,
        isUnread: Bool = true
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
        self.createdAt = createdAt
        self.isUnread = isUnread
    }
}

struct PatientMedicationScheduleItemState: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let detail: String
    let statusText: String
    let tone: CareTapTone
}

struct PatientRefillStatusState: Hashable, Codable {
    let headline: String
    let detail: String
    let quantityText: String
    let thresholdText: String
    let tone: CareTapTone
}

struct PatientMedicationRowState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let category: MedicationCategory
    let dosage: String
    let formText: String
    let containerKind: ContainerKind
    let scheduleSummary: String
    let bottleLabel: String
    let refillLabel: String
    let nfcLabel: String
    let bottlePhotoLocalPath: String?
    let currentDoseText: String
    let hasCurrentOpenDose: Bool
    let upcomingDoseText: String
    let adherenceSummary: String
    let adherencePercent: Int?
    let foodSummary: String
    let noteSummary: String
    let ownershipSummary: String
    let isActive: Bool
    let isTagPaired: Bool
    let hasRefillRisk: Bool
    let dosesRemainingEstimate: Int?
    let scheduleItems: [PatientMedicationScheduleItemState]
    let historyItems: [PatientHistoryRowState]
    let refillStatus: PatientRefillStatusState?
}

struct PatientHistoryRowState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let secondaryDetail: String
    let scheduledAt: Date
    let loggedAt: Date?
    let statusText: String
    let sourceText: String
    let confidenceText: String
    let resolutionReason: String?
    let isCorrection: Bool
    let tone: CareTapTone
}

struct CaregiverRelationshipRowState: Identifiable, Hashable {
    let id: UUID
    let careProfileID: UUID
    let lovedOneName: String
    let statusText: String
    let accessLevelTitle: String
    let permissionsSummary: String
    let permissionTags: [String]
    let alertSummary: String
    let alertPreferencesText: String
    let receivesMissedDoseAlerts: Bool
    let receivesRefillAlerts: Bool
    let showsAttention: Bool
    let isSelected: Bool
}

struct CaregiverInvitationRowState: Identifiable, Hashable {
    let id: UUID
    let recipient: String
    let inviteCode: String
    let statusText: String
    let detail: String
}
