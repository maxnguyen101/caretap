import ActivityKit
import Foundation

enum CareTapLiveActivityStatus: String, Codable, Hashable, CaseIterable {
    case dueNow = "due_now"
    case overdue
    case snoozed
    case completed

    var focusState: DoseFocusState {
        switch self {
        case .dueNow:
            return .dueNow
        case .overdue:
            return .overdue
        case .snoozed:
            return .snoozed
        case .completed:
            return .completed
        }
    }

    var tone: CareTapTone {
        focusState.tone
    }

    var badgeText: String {
        focusState.chipText
    }
}

struct CareTapDoseActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var medicationName: String
        var dosage: String
        var dueTime: Date
        var status: CareTapLiveActivityStatus
        var primaryActionLabel: String
    }

    var careProfileName: String
    var medicationID: UUID
    var occurrenceID: UUID
}

struct CareTapDoseActivityViewState: Hashable {
    let medicationName: String
    let dosage: String
    let dueTimeText: String
    let statusText: String
    let statusTone: CareTapTone
    let primaryActionLabel: String

    init(contentState: CareTapDoseActivityAttributes.ContentState) {
        medicationName = contentState.medicationName
        dosage = contentState.dosage
        dueTimeText = contentState.dueTime.formatted(date: .omitted, time: .shortened)
        statusText = contentState.status.badgeText
        statusTone = contentState.status.tone
        primaryActionLabel = contentState.primaryActionLabel
    }
}
