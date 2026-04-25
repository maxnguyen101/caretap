import Foundation

struct BestNextStepSnapshot: Codable, Hashable {
    let title: String
    let subtitle: String
    let state: DoseFocusState
}

struct TodaySnapshotWidgetState: Codable, Hashable {
    let title: String
    let adherenceText: String
    let nextDoseText: String
    var progressFraction: Double = 0
}
