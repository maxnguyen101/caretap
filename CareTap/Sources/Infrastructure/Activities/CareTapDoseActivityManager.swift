import ActivityKit
import Foundation

struct CareTapDoseActivityManager: CareTapDoseActivityManaging {
    func updateCurrentDoseActivity(
        profileName: String,
        medication: Medication,
        occurrence: DoseOccurrence
    ) async {
        for activity in Activity<CareTapDoseActivityAttributes>.activities where activity.attributes.occurrenceID != occurrence.id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let attributes = CareTapDoseActivityAttributes(
            careProfileName: profileName,
            medicationID: medication.id,
            occurrenceID: occurrence.id
        )
        let contentState = CareTapDoseActivityAttributes.ContentState(
            medicationName: medication.name,
            dosage: medication.dosage,
            dueTime: occurrence.snoozedUntil ?? occurrence.scheduledAt,
            status: liveActivityStatus(for: occurrence),
            primaryActionLabel: primaryActionLabel(for: occurrence)
        )

        if let existing = Activity<CareTapDoseActivityAttributes>.activities.first(where: { activity in
            activity.attributes.occurrenceID == occurrence.id
        }) {
            await existing.update(ActivityContent(state: contentState, staleDate: occurrence.windowClosesAt))
            return
        }

        do {
            _ = try Activity<CareTapDoseActivityAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: contentState, staleDate: occurrence.windowClosesAt)
            )
        } catch {
            // Activity requests are best-effort so the app remains usable even if authorization is unavailable.
        }
    }

    func endAllActivities() async {
        for activity in Activity<CareTapDoseActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func liveActivityStatus(for occurrence: DoseOccurrence) -> CareTapLiveActivityStatus {
        switch occurrence.status {
        case .completed, .late, .resolved:
            return .completed
        case .snoozed:
            return .snoozed
        case .overdue, .missed:
            return .overdue
        case .scheduled, .dueNow, .skipped:
            return .dueNow
        }
    }

    private func primaryActionLabel(for occurrence: DoseOccurrence) -> String {
        switch occurrence.status {
        case .completed, .late, .resolved:
            return "View log"
        case .snoozed:
            return "Resume"
        case .overdue, .missed, .dueNow:
            return "Log now"
        case .scheduled, .skipped:
            return "Open app"
        }
    }
}
