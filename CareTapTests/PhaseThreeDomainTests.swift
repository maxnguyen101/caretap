import XCTest
@testable import CareTap

final class PhaseThreeDomainTests: XCTestCase {
    func testDismissedReminderDoesNotResolveOccurrence() {
        let occurrence = CareTapPhaseThreePreviewScenarios.overdueOccurrence

        XCTAssertFalse(occurrence.isResolved)
        XCTAssertTrue(occurrence.reminderDismissalDoesNotCountAsTaken)
    }

    func testLiveActivityStatusMapsToDoseFocusState() {
        XCTAssertEqual(CareTapLiveActivityStatus.overdue.focusState, .overdue)
        XCTAssertEqual(CareTapLiveActivityStatus.completed.badgeText, "Taken")
    }

    func testScheduleGeneratorCreatesDayOccurrences() {
        let interval = DateInterval(
            start: CareTapPhaseThreePreviewScenarios.referenceDate.addingTimeInterval(-8 * 60 * 60),
            end: CareTapPhaseThreePreviewScenarios.referenceDate.addingTimeInterval(16 * 60 * 60)
        )
        let generator = CareTapMedicationScheduleGenerator(nowProvider: { CareTapPhaseThreePreviewScenarios.referenceDate })

        let occurrences = generator.generateOccurrences(
            for: CareTapPhaseThreePreviewScenarios.medication,
            rules: [CareTapPhaseThreePreviewScenarios.scheduleRule],
            within: interval
        )

        XCTAssertEqual(occurrences.count, 2)
        XCTAssertEqual(occurrences.first?.status, .dueNow)
        XCTAssertEqual(occurrences.last?.status, .scheduled)
    }

    func testDoseLoggingServiceFlagsTooEarlyAttempts() async throws {
        let service = StubDoseLoggingService()
        let occurrence = CareTapPhaseThreePreviewScenarios.dueNowOccurrence
        let request = DoseLoggingRequest(
            actorUserID: nil,
            source: .manualPatientConfirmation,
            action: .confirmTaken,
            loggedAt: occurrence.windowOpensAt.addingTimeInterval(-60),
            note: "Tapped too early",
            nfcTagID: nil
        )

        let result = try await service.logDose(for: occurrence, request: request)

        XCTAssertEqual(result.log.validationState, .tooEarly)
        XCTAssertTrue(result.occurrence.flags.contains(.tooEarly))
        XCTAssertEqual(result.occurrence.status, occurrence.status)
        XCTAssertFalse(result.log.provesMedicationTaken)
    }

    func testRefillEstimatorMarksLowSupplyAsUrgent() {
        let medication = Medication(
            id: CareTapPhaseThreePreviewScenarios.medication.id,
            careProfileID: CareTapPhaseThreePreviewScenarios.medication.careProfileID,
            nfcTagID: CareTapPhaseThreePreviewScenarios.medication.nfcTagID,
            name: CareTapPhaseThreePreviewScenarios.medication.name,
            dosage: CareTapPhaseThreePreviewScenarios.medication.dosage,
            doseQuantity: 1,
            doseQuantityUnit: "tablet",
            instructions: CareTapPhaseThreePreviewScenarios.medication.instructions,
            bottleLabel: CareTapPhaseThreePreviewScenarios.medication.bottleLabel,
            bottlePhotoLocalPath: CareTapPhaseThreePreviewScenarios.medication.bottlePhotoLocalPath,
            form: CareTapPhaseThreePreviewScenarios.medication.form,
            scheduleSummary: CareTapPhaseThreePreviewScenarios.medication.scheduleSummary,
            isActive: CareTapPhaseThreePreviewScenarios.medication.isActive,
            supplyCount: 2,
            createdAt: CareTapPhaseThreePreviewScenarios.medication.createdAt,
            updatedAt: CareTapPhaseThreePreviewScenarios.medication.updatedAt,
            archivedAt: CareTapPhaseThreePreviewScenarios.medication.archivedAt,
            syncState: .localOnly
        )
        let estimator = CareTapRefillEstimator()

        let result = estimator.estimateRefillState(
            for: medication,
            rules: [CareTapPhaseThreePreviewScenarios.scheduleRule],
            asOf: CareTapPhaseThreePreviewScenarios.referenceDate
        )

        XCTAssertEqual(result.riskLevel, .urgent)
        XCTAssertEqual(result.dosesRemainingEstimate, 2)
    }
}
