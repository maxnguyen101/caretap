import Foundation
import UserNotifications

final class LocalNotificationReminderScheduler: ReminderScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let key = "com.maxnguyen.caretap.reminder-identifiers"

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.defaults = defaults
    }

    func scheduleReminders(
        for occurrence: DoseOccurrence,
        medication: Medication,
        preference: ReminderPreference
    ) async throws -> [ReminderSchedulePlan] {
        let settings = await center.notificationSettings()
        let authorized = try await ensureAuthorization(from: settings)
        guard authorized else {
            throw CareTapServiceError.notificationPermissionDenied
        }

        let dueDate = occurrence.snoozedUntil ?? occurrence.scheduledAt
        var plans: [ReminderSchedulePlan] = []

        for channel in preference.channels where channel == .localNotification {
            let firstFireDate = dueDate.addingTimeInterval(TimeInterval(-preference.leadTimeMinutes * 60))
            let isAdvanceReminder = preference.leadTimeMinutes > 0
            let initialPlan = ReminderSchedulePlan(
                occurrenceID: occurrence.id,
                channel: channel,
                fireDate: firstFireDate,
                title: isAdvanceReminder ? "\(medication.name) coming up" : "\(medication.name) due now",
                body: isAdvanceReminder
                    ? "This is an early reminder. A reminder can prompt the check-in, but it does not confirm anything by itself."
                    : "A reminder can prompt the check-in, but it does not confirm anything by itself.",
                primaryActionLabel: medication.nfcTagID == nil ? "Check In" : "Tap Tag"
            )
            plans.append(initialPlan)

            if let followUpAfterMinutes = preference.followUpAfterMinutes,
               preference.maxFollowUps > 0 {
                for followUpIndex in 1...preference.maxFollowUps {
                    plans.append(
                        ReminderSchedulePlan(
                            occurrenceID: occurrence.id,
                            channel: channel,
                            fireDate: dueDate.addingTimeInterval(TimeInterval((followUpAfterMinutes * 60) * followUpIndex)),
                            title: "\(medication.name) still needs confirmation",
                            body: "TapCare does not treat a dismissed reminder as a completed check-in.",
                            primaryActionLabel: medication.nfcTagID == nil ? "Manual Check-In" : "Tap Tag"
                        )
                    )
                }
            }
        }

        let identifiers = plans.enumerated().map { index, plan in
            "caretap.reminder.\(occurrence.id.uuidString).\(index)"
        }

        try await cancelReminders(for: occurrence.id)

        for (index, plan) in plans.enumerated() {
            guard plan.fireDate > .now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default
            content.categoryIdentifier = "CARETAP_DOSE_REMINDER"
            content.userInfo = [
                "occurrenceID": occurrence.id.uuidString,
                "primaryActionLabel": plan.primaryActionLabel
            ]

            let interval = max(plan.fireDate.timeIntervalSinceNow, 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: identifiers[index], content: content, trigger: trigger)
            try await center.add(request)
        }

        persistIdentifiers(identifiers, for: occurrence.id)
        return plans.sorted { $0.fireDate < $1.fireDate }
    }

    func cancelReminders(for occurrenceID: UUID) async throws {
        let identifiers = loadIdentifiers()[occurrenceID.uuidString] ?? []
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        removeIdentifiers(for: occurrenceID)
    }

    private func ensureAuthorization(from settings: UNNotificationSettings) async throws -> Bool {
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        @unknown default:
            return false
        }
    }

    private func persistIdentifiers(_ identifiers: [String], for occurrenceID: UUID) {
        var mapping = loadIdentifiers()
        mapping[occurrenceID.uuidString] = identifiers
        defaults.set(mapping, forKey: key)
    }

    private func removeIdentifiers(for occurrenceID: UUID) {
        var mapping = loadIdentifiers()
        mapping.removeValue(forKey: occurrenceID.uuidString)
        defaults.set(mapping, forKey: key)
    }

    private func loadIdentifiers() -> [String: [String]] {
        defaults.dictionary(forKey: key) as? [String: [String]] ?? [:]
    }
}
