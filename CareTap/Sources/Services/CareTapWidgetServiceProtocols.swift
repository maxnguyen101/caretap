import Foundation

protocol CareTapWidgetSnapshotStoring: Sendable {
    func loadBestNextStep() throws -> BestNextStepSnapshot?
    func loadTodaySnapshot() throws -> TodaySnapshotWidgetState?
    func save(bestNextStep: BestNextStepSnapshot, todaySnapshot: TodaySnapshotWidgetState) throws
}

protocol CareTapDoseActivityManaging: Sendable {
    func updateCurrentDoseActivity(
        profileName: String,
        medication: Medication,
        occurrence: DoseOccurrence
    ) async

    func endAllActivities() async
}
