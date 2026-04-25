import Foundation

struct CareTapMedicationScheduleGenerator: MedicationScheduleGenerating, Sendable {
    private let nowProvider: @Sendable () -> Date

    init(nowProvider: @escaping @Sendable () -> Date = { .now }) {
        self.nowProvider = nowProvider
    }

    func generateOccurrences(
        for medication: Medication,
        rules: [ScheduleRule],
        within interval: DateInterval
    ) -> [DoseOccurrence] {
        var generated: [DoseOccurrence] = []

        for rule in rules where rule.isActive && rule.medicationID == medication.id {
            switch rule.type {
            case .daily, .weekly:
                generated.append(contentsOf: generateDayBasedOccurrences(medication: medication, rule: rule, interval: interval))
            case .interval:
                generated.append(contentsOf: generateIntervalOccurrences(medication: medication, rule: rule, interval: interval))
            case .asNeeded:
                continue
            }
        }

        return generated.sorted { lhs, rhs in
            lhs.scheduledAt == rhs.scheduledAt
                ? lhs.windowClosesAt < rhs.windowClosesAt
                : lhs.scheduledAt < rhs.scheduledAt
        }
    }

    private func generateDayBasedOccurrences(
        medication: Medication,
        rule: ScheduleRule,
        interval: DateInterval
    ) -> [DoseOccurrence] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: rule.timezoneIdentifier) ?? .current

        let startDay = calendar.startOfDay(for: max(interval.start, rule.startsOn))
        let endDate = min(interval.end, rule.endsOn ?? interval.end)
        let allowedWeekdays = Set(rule.daysOfWeek.map(\.rawValue))
        var cursor = startDay
        var occurrences: [DoseOccurrence] = []

        while cursor <= endDate {
            let weekday = calendar.component(.weekday, from: cursor)
            let isAllowedDay: Bool

            if rule.type == .weekly {
                isAllowedDay = allowedWeekdays.contains(weekday)
            } else {
                isAllowedDay = allowedWeekdays.isEmpty || allowedWeekdays.contains(weekday)
            }

            if isAllowedDay {
                for time in rule.timesOfDay {
                    var components = calendar.dateComponents([.year, .month, .day], from: cursor)
                    components.hour = time.hour
                    components.minute = time.minute

                    if let scheduledAt = calendar.date(from: components),
                       interval.contains(scheduledAt) {
                        occurrences.append(makeOccurrence(for: medication, rule: rule, scheduledAt: scheduledAt))
                    }
                }
            }

            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? endDate.addingTimeInterval(1)
        }

        return occurrences
    }

    private func generateIntervalOccurrences(
        medication: Medication,
        rule: ScheduleRule,
        interval: DateInterval
    ) -> [DoseOccurrence] {
        guard let intervalHours = rule.intervalHours, intervalHours > 0 else {
            return []
        }

        var scheduledAt = rule.startsOn
        let endDate = min(interval.end, rule.endsOn ?? interval.end)
        var occurrences: [DoseOccurrence] = []

        while scheduledAt <= endDate {
            if interval.contains(scheduledAt) {
                occurrences.append(makeOccurrence(for: medication, rule: rule, scheduledAt: scheduledAt))
            }

            scheduledAt = scheduledAt.addingTimeInterval(TimeInterval(intervalHours * 60 * 60))
        }

        return occurrences
    }

    private func makeOccurrence(for medication: Medication, rule: ScheduleRule, scheduledAt: Date) -> DoseOccurrence {
        let windowOpensAt = scheduledAt.addingTimeInterval(-15 * 60)
        let windowClosesAt = scheduledAt.addingTimeInterval(TimeInterval(rule.gracePeriodMinutes * 60))
        let status: DoseOccurrenceStatus
        let evaluationDate = nowProvider()

        if evaluationDate < scheduledAt {
            status = .scheduled
        } else if evaluationDate <= windowClosesAt {
            status = .dueNow
        } else {
            status = .overdue
        }

        return DoseOccurrence(
            id: UUID(),
            careProfileID: medication.careProfileID,
            medicationID: medication.id,
            scheduleRuleID: rule.id,
            scheduledAt: scheduledAt,
            windowOpensAt: windowOpensAt,
            windowClosesAt: windowClosesAt,
            snoozedUntil: nil,
            status: status,
            reminderState: .scheduled,
            flags: [],
            resolvedByLogID: nil,
            resolvedAt: nil,
            createdAt: scheduledAt,
            updatedAt: scheduledAt,
            syncState: .localOnly
        )
    }
}
