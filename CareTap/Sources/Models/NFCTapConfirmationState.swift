import Foundation

/// State model for the rich NFC tap confirmation sheet. Drives the single place
/// where TapCare acknowledges a physical tap, so the day-to-day feel is:
/// tap the bottle → immediately see a clear, calm confirmation of what happened.
struct NFCTapConfirmationState: Identifiable, Hashable {
    enum Outcome: Hashable {
        /// The tap landed inside an open window and the dose was logged.
        case logged(LoggedDetails)
        /// The same item was already logged recently — show the duplicate guard.
        case alreadyLogged(DuplicateDetails)
        /// The tap happened before the scheduled window opens.
        case tooEarly(TimingDetails)
        /// No scheduled dose is active; the user can still log it as a one-off.
        case noActiveDose(IdleDetails)
        /// The scanned tag is not paired to any active medication.
        case unknownTag(UnknownTagDetails)
    }

    struct LoggedDetails: Hashable {
        let medicationName: String
        let dosage: String
        let loggedAt: Date
        let nextDoseLabel: String?
        /// Whether the user has configured the Shortcuts automation so taps run
        /// without opening TapCare. Drives the automation hint banner.
        let isAutomationConfigured: Bool
    }

    struct DuplicateDetails: Hashable {
        let medicationName: String
        let dosage: String
        let previousLoggedAt: Date
        let minutesAgo: Int
    }

    struct TimingDetails: Hashable {
        let medicationName: String
        let dosage: String
        let windowOpensAt: Date
    }

    struct IdleDetails: Hashable {
        let medicationName: String
        let dosage: String
        let nextScheduledAt: Date?
    }

    struct UnknownTagDetails: Hashable {
        let message: String
    }

    let id: UUID
    let outcome: Outcome
    /// Whether TapCare recognized an NFC-sourced tap. Manual confirmations reuse
    /// the same sheet, but hide the automation hint banner so the UI stays clean.
    let isNFCSource: Bool

    init(id: UUID = UUID(), outcome: Outcome, isNFCSource: Bool) {
        self.id = id
        self.outcome = outcome
        self.isNFCSource = isNFCSource
    }
}

extension NFCTapConfirmationState {
    /// Minutes of silence before a new NFC tap is treated as a genuine new dose
    /// instead of a reflexive double tap.
    static let doubleTapGuardMinutes: Int = 4
}
