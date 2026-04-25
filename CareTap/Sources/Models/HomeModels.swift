import Foundation

enum CareTapTone: String, Codable, Hashable {
    case sage
    case neutral
    case mist
    case warm
    case alert
    case success
}

enum AvatarStyle: String, Codable, Hashable {
    case patient
    case caregiver
    case lovedOne
    case helper
}

struct PersonProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let initials: String
    let style: AvatarStyle
    var showsAlertDot: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        initials: String,
        style: AvatarStyle,
        showsAlertDot: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.initials = initials
        self.style = style
        self.showsAlertDot = showsAlertDot
    }
}

enum DoseFocusState: String, Codable, Hashable, CaseIterable {
    case upcoming
    case dueNow
    case overdue
    case snoozed
    case completed

    var chipText: String {
        switch self {
        case .upcoming:
            return "Next"
        case .dueNow:
            return "Due Now"
        case .overdue:
            return "Overdue"
        case .snoozed:
            return "Snoozed"
        case .completed:
            return "Taken"
        }
    }

    var heroTitle: String {
        switch self {
        case .upcoming:
            return "Your next check-in opens later"
        case .dueNow:
            return "Your next check-in is due now"
        case .overdue:
            return "This check-in is running late"
        case .snoozed:
            return "This check-in is snoozed for now"
        case .completed:
            return "You're set until the next check-in"
        }
    }

    var tone: CareTapTone {
        switch self {
        case .upcoming:
            return .mist
        case .dueNow:
            return .alert
        case .overdue:
            return .alert
        case .snoozed:
            return .warm
        case .completed:
            return .success
        }
    }
}

enum PatientSecondaryActionKind: String, Codable, Hashable, CaseIterable {
    case manualCheckIn
    case snooze
    case skip
    case openHistory
    case openItems
    case openSettings
}

struct SecondaryActionState: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let tone: CareTapTone
    let kind: PatientSecondaryActionKind?

    init(
        id: UUID = UUID(),
        title: String,
        tone: CareTapTone,
        kind: PatientSecondaryActionKind? = nil
    ) {
        self.id = id
        self.title = title
        self.tone = tone
        self.kind = kind
    }
}

struct PatientDoseCardState: Codable, Hashable {
    let medicationName: String
    let scheduledText: String
    let bottlePhotoLocalPath: String?
    let focusState: DoseFocusState
    let primaryActionTitle: String
    let primaryActionSymbol: String
    let secondaryActions: [SecondaryActionState]
}

struct DailyProgress: Codable, Hashable {
    let completedCount: Int
    let totalCount: Int

    var fractionComplete: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}

struct UpcomingMedicationState: Codable, Hashable {
    let title: String
    let timeText: String
    let contextLabel: String
}

struct CareTeamBannerState: Codable, Hashable {
    let title: String
    let message: String
    let memberInitials: [String]
    let memberCount: Int
}

struct PatientHomeState: Codable, Hashable {
    let profile: PersonProfile
    let currentDose: PatientDoseCardState
    let progress: DailyProgress
    let upcomingMedication: UpcomingMedicationState
    let upcomingItems: [UpcomingMedicationState]
    let careTeamBanner: CareTeamBannerState
    let selectedDestination: CareTapDestination
}

enum CaregiverAlertLevel: String, Codable, Hashable {
    case needsAttention
    case refillRisk
    case onTrack

    func headline(for lovedOneName: String) -> String {
        switch self {
        case .needsAttention:
            return "\(lovedOneName) needs attention"
        case .refillRisk:
            return "\(lovedOneName) needs a refill plan"
        case .onTrack:
            return "\(lovedOneName) is on track today"
        }
    }

    var tone: CareTapTone {
        switch self {
        case .needsAttention:
            return .alert
        case .refillRisk:
            return .warm
        case .onTrack:
            return .success
        }
    }
}

struct CaregiverStatusCardState: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let tone: CareTapTone

    init(id: UUID = UUID(), title: String, message: String, tone: CareTapTone) {
        self.id = id
        self.title = title
        self.message = message
        self.tone = tone
    }
}

enum CareTapQuickActionKind: String, Codable, Hashable, CaseIterable {
    case call
    case message
    case reviewMedications
    case reviewTimeline
    case openSharing
    case resolveDose
}

struct QuickActionState: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let systemImage: String
    let tone: CareTapTone
    let kind: CareTapQuickActionKind?

    init(
        id: UUID = UUID(),
        title: String,
        systemImage: String,
        tone: CareTapTone,
        kind: CareTapQuickActionKind? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
        self.kind = kind
    }
}

enum CareTimelineStatus: String, Codable, Hashable {
    case missed
    case upcoming
    case bedtime
    case completed

    var label: String {
        switch self {
        case .missed:
            return "Missed"
        case .upcoming:
            return "Upcoming"
        case .bedtime:
            return "Bedtime"
        case .completed:
            return "Done"
        }
    }

    var tone: CareTapTone {
        switch self {
        case .missed:
            return .alert
        case .upcoming:
            return .warm
        case .bedtime:
            return .neutral
        case .completed:
            return .success
        }
    }
}

struct CaregiverTimelineEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let scheduledText: String
    let status: CareTimelineStatus
    let detailText: String?

    init(
        id: UUID = UUID(),
        title: String,
        scheduledText: String,
        status: CareTimelineStatus,
        detailText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.scheduledText = scheduledText
        self.status = status
        self.detailText = detailText
    }
}

struct CaregiverLinkedPersonState: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let initials: String
    let showsAttention: Bool
    let isSelected: Bool
}

struct CaregiverHomeState: Codable, Hashable {
    let caregiverProfile: PersonProfile
    let lovedOne: PersonProfile
    let linkedPeople: [CaregiverLinkedPersonState]
    let householdSummary: String
    let careCircleSummary: String
    let alertLevel: CaregiverAlertLevel
    let alertDetail: String
    let statusCards: [CaregiverStatusCardState]
    let quickActions: [QuickActionState]
    let timelineDateLabel: String
    let timelineEvents: [CaregiverTimelineEvent]
    let selectedDestination: CareTapDestination
}
