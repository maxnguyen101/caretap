import Foundation

struct CareTapRefillEstimator: RefillEstimating, Sendable {
    func estimateRefillState(
        for medication: Medication,
        rules: [ScheduleRule],
        asOf referenceDate: Date
    ) -> RefillState {
        let doseQuantity = max(medication.doseQuantity ?? 1, 1)
        let quantityOnHand = medication.supplyCount
        let dosesRemaining = quantityOnHand.map { Int(floor($0 / doseQuantity)) } ?? 0
        let dailyDoses = max(estimatedDailyDoses(from: rules), 1)
        let daysRemaining = Int(floor(Double(dosesRemaining) / dailyDoses))
        let estimatedRunOutDate = quantityOnHand == nil
            ? nil
            : referenceDate.addingTimeInterval(TimeInterval(daysRemaining * 24 * 60 * 60))

        let riskLevel: RefillRiskLevel
        switch daysRemaining {
        case ..<1:
            riskLevel = .depleted
        case 1...3:
            riskLevel = .urgent
        case 4...7:
            riskLevel = .watch
        default:
            riskLevel = .onTrack
        }

        return RefillState(
            id: UUID(),
            medicationID: medication.id,
            quantityOnHand: quantityOnHand,
            dosesRemainingEstimate: dosesRemaining,
            estimatedRunOutDate: estimatedRunOutDate,
            riskLevel: riskLevel,
            lastCalculatedAt: referenceDate,
            createdAt: referenceDate,
            updatedAt: referenceDate,
            syncState: .localOnly
        )
    }

    private func estimatedDailyDoses(from rules: [ScheduleRule]) -> Double {
        rules
            .filter(\.isActive)
            .reduce(0) { partialResult, rule in
                switch rule.type {
                case .daily:
                    return partialResult + Double(max(rule.timesOfDay.count, 1))
                case .weekly:
                    let activeDays = max(rule.daysOfWeek.count, 1)
                    let dailyTimes = max(rule.timesOfDay.count, 1)
                    return partialResult + (Double(activeDays * dailyTimes) / 7.0)
                case .interval:
                    guard let intervalHours = rule.intervalHours, intervalHours > 0 else {
                        return partialResult
                    }
                    return partialResult + (24.0 / Double(intervalHours))
                case .asNeeded:
                    return partialResult
                }
            }
    }
}
