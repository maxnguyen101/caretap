import Foundation

final class RepositoryBackedDoseLoggingService: DoseLoggingServicing, @unchecked Sendable {
    private let recordStore: any CareTapRecordStoring

    init(recordStore: any CareTapRecordStoring) {
        self.recordStore = recordStore
    }

    func logDose(for occurrence: DoseOccurrence, request: DoseLoggingRequest) async throws -> DoseLoggingResult {
        let validationState = validationState(for: occurrence, request: request)
        let now = request.loggedAt
        let resolutionReason = request.resolutionReason ?? request.note
        let log = DoseLog(
            id: UUID(),
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            occurrenceID: occurrence.id,
            actorUserID: request.actorUserID,
            source: request.source,
            action: request.action,
            validationState: validationState,
            effectiveAt: now,
            loggedAt: now,
            note: request.note,
            resolutionKind: resolutionKind(for: occurrence, request: request),
            resolutionReason: resolutionReason,
            undoesLogID: request.undoesLogID,
            supersedesLogID: request.action == .correctEntry ? (request.undoesLogID ?? occurrence.resolvedByLogID) : nil,
            nfcTagID: request.nfcTagID,
            createdAt: now,
            updatedAt: now,
            syncState: .pendingUpload
        )

        var updatedOccurrence = occurrence
        var flags = Set(occurrence.flags)

        switch validationState {
        case .accepted:
            switch request.action {
            case .confirmTaken:
                updatedOccurrence = DoseOccurrence(
                    id: occurrence.id,
                    careProfileID: occurrence.careProfileID,
                    medicationID: occurrence.medicationID,
                    scheduleRuleID: occurrence.scheduleRuleID,
                    scheduledAt: occurrence.scheduledAt,
                    windowOpensAt: occurrence.windowOpensAt,
                    windowClosesAt: occurrence.windowClosesAt,
                    snoozedUntil: nil,
                    status: now > occurrence.windowClosesAt ? .late : .completed,
                    reminderState: .actionTaken,
                    flags: Array(flags.union([.resolved]).union(now > occurrence.windowClosesAt ? [.late] : [])),
                    resolvedByLogID: log.id,
                    resolvedAt: now,
                    createdAt: occurrence.createdAt,
                    updatedAt: now,
                    syncState: .pendingUpload
                )
            case .markSkipped:
                flags.formUnion([.skipped, .resolved])
                updatedOccurrence = DoseOccurrence(
                    id: occurrence.id,
                    careProfileID: occurrence.careProfileID,
                    medicationID: occurrence.medicationID,
                    scheduleRuleID: occurrence.scheduleRuleID,
                    scheduledAt: occurrence.scheduledAt,
                    windowOpensAt: occurrence.windowOpensAt,
                    windowClosesAt: occurrence.windowClosesAt,
                    snoozedUntil: nil,
                    status: .skipped,
                    reminderState: .actionTaken,
                    flags: Array(flags),
                    resolvedByLogID: log.id,
                    resolvedAt: now,
                    createdAt: occurrence.createdAt,
                    updatedAt: now,
                    syncState: .pendingUpload
                )
            case .correctEntry:
                if request.undoesLogID != nil {
                    updatedOccurrence = reopenedOccurrence(from: occurrence, updatedAt: now)
                } else {
                    flags.insert(.resolved)
                    updatedOccurrence = DoseOccurrence(
                        id: occurrence.id,
                        careProfileID: occurrence.careProfileID,
                        medicationID: occurrence.medicationID,
                        scheduleRuleID: occurrence.scheduleRuleID,
                        scheduledAt: occurrence.scheduledAt,
                        windowOpensAt: occurrence.windowOpensAt,
                        windowClosesAt: occurrence.windowClosesAt,
                        snoozedUntil: occurrence.snoozedUntil,
                        status: .resolved,
                        reminderState: .actionTaken,
                        flags: Array(flags),
                        resolvedByLogID: log.id,
                        resolvedAt: now,
                        createdAt: occurrence.createdAt,
                        updatedAt: now,
                        syncState: .pendingUpload
                    )
                }
            }
        case .duplicate:
            flags.insert(.duplicate)
            updatedOccurrence = copy(occurrence, flags: Array(flags), updatedAt: now)
        case .tooEarly:
            flags.insert(.tooEarly)
            updatedOccurrence = copy(occurrence, flags: Array(flags), updatedAt: now)
        case .superseded, .rejected:
            break
        }

        let storedLog = try await recordStore.upsertDoseLog(log)
        let storedOccurrence = try await recordStore.upsertDoseOccurrence(updatedOccurrence)
        return DoseLoggingResult(occurrence: storedOccurrence, log: storedLog)
    }

    private func validationState(for occurrence: DoseOccurrence, request: DoseLoggingRequest) -> DoseLogValidationState {
        if request.action == .confirmTaken && request.loggedAt < occurrence.windowOpensAt {
            return .tooEarly
        }

        if occurrence.isResolved && request.action != .correctEntry {
            return .duplicate
        }

        return .accepted
    }

    private func resolutionKind(for occurrence: DoseOccurrence, request: DoseLoggingRequest) -> DoseLogResolutionKind {
        switch request.action {
        case .confirmTaken:
            return request.loggedAt > occurrence.windowClosesAt ? .lateConfirmation : .standard
        case .markSkipped:
            return .skippedWithReason
        case .correctEntry:
            return request.undoesLogID == nil ? .correctedEntry : .undo
        }
    }

    private func copy(_ occurrence: DoseOccurrence, flags: [DoseOccurrenceFlag], updatedAt: Date) -> DoseOccurrence {
        DoseOccurrence(
            id: occurrence.id,
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            scheduleRuleID: occurrence.scheduleRuleID,
            scheduledAt: occurrence.scheduledAt,
            windowOpensAt: occurrence.windowOpensAt,
            windowClosesAt: occurrence.windowClosesAt,
            snoozedUntil: occurrence.snoozedUntil,
            status: occurrence.status,
            reminderState: occurrence.reminderState,
            flags: flags,
            resolvedByLogID: occurrence.resolvedByLogID,
            resolvedAt: occurrence.resolvedAt,
            createdAt: occurrence.createdAt,
            updatedAt: updatedAt,
            syncState: .pendingUpload
        )
    }

    private func reopenedOccurrence(from occurrence: DoseOccurrence, updatedAt: Date) -> DoseOccurrence {
        var flags = Set(occurrence.flags)
        flags.subtract([.resolved, .skipped, .late, .missed])

        let nextStatus: DoseOccurrenceStatus
        if let snoozedUntil = occurrence.snoozedUntil, snoozedUntil > updatedAt {
            nextStatus = .snoozed
        } else if updatedAt < occurrence.scheduledAt {
            nextStatus = .scheduled
        } else if updatedAt <= occurrence.windowClosesAt {
            nextStatus = .dueNow
        } else if updatedAt > occurrence.windowClosesAt.addingTimeInterval(4 * 60 * 60) {
            flags.insert(.missed)
            nextStatus = .missed
        } else {
            nextStatus = .overdue
        }

        return DoseOccurrence(
            id: occurrence.id,
            careProfileID: occurrence.careProfileID,
            medicationID: occurrence.medicationID,
            scheduleRuleID: occurrence.scheduleRuleID,
            scheduledAt: occurrence.scheduledAt,
            windowOpensAt: occurrence.windowOpensAt,
            windowClosesAt: occurrence.windowClosesAt,
            snoozedUntil: occurrence.snoozedUntil,
            status: nextStatus,
            reminderState: .scheduled,
            flags: Array(flags),
            resolvedByLogID: nil,
            resolvedAt: nil,
            createdAt: occurrence.createdAt,
            updatedAt: updatedAt,
            syncState: .pendingUpload
        )
    }
}
