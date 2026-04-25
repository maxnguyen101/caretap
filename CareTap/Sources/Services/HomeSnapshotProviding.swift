import Foundation

protocol HomeSnapshotProviding {
    func patientHomeState() -> PatientHomeState
    func caregiverHomeState() -> CaregiverHomeState
    func bestNextStepSnapshot() -> BestNextStepSnapshot
    func todaySnapshotWidgetState() -> TodaySnapshotWidgetState
}

