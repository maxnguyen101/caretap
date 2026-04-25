import Foundation

struct PreviewHomeSnapshotService: HomeSnapshotProviding {
    func patientHomeState() -> PatientHomeState {
        CareTapPreviewScenarios.patientDueNow
    }

    func caregiverHomeState() -> CaregiverHomeState {
        CareTapPreviewScenarios.caregiverAttentionNeeded
    }

    func bestNextStepSnapshot() -> BestNextStepSnapshot {
        BestNextStepSnapshot(
            title: "Tap Tag",
            subtitle: "Lisinopril 10mg due now",
            state: .dueNow
        )
    }

    func todaySnapshotWidgetState() -> TodaySnapshotWidgetState {
        TodaySnapshotWidgetState(
            title: "3 of 4 done today",
            adherenceText: "One item still needs confirmation",
            nextDoseText: "Metformin at 12:30 PM",
            progressFraction: 0.75
        )
    }
}
