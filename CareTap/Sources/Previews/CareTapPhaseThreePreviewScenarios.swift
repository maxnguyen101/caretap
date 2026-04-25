import Foundation

enum CareTapPhaseThreePreviewScenarios {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        return calendar
    }()

    static let referenceDate = date(year: 2026, month: 4, day: 3, hour: 8, minute: 10)

    static let user = User(
        id: UUID(),
        authUserID: UUID(),
        appleSubject: "apple-preview-subject",
        preferredRole: .caregiver,
        displayName: "Ella Nguyen",
        initials: "EN",
        timezoneIdentifier: "America/Los_Angeles",
        localeIdentifier: "en_US",
        isSignInWithAppleLinked: false,
        createdAt: date(year: 2026, month: 1, day: 6, hour: 9, minute: 0),
        updatedAt: referenceDate,
        lastActiveAt: referenceDate,
        syncState: .localOnly
    )

    static let careProfile = CareProfile(
        id: UUID(),
        createdByUserID: user.id,
        patientUserID: nil,
        displayName: "Arthur Nguyen",
        preferredName: "Arthur",
        initials: "AN",
        avatarStyle: .lovedOne,
        timezoneIdentifier: "America/Los_Angeles",
        notes: "Lives with family. Prefers calm reminders and simple bottle-tap confirmation.",
        createdAt: date(year: 2026, month: 1, day: 6, hour: 9, minute: 15),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let careRelationship = CareRelationship(
        id: UUID(),
        caregiverUserID: user.id,
        careProfileID: careProfile.id,
        label: .child,
        status: .active,
        permissions: [.viewAdherence, .logDose, .manageMedication, .manageAlerts],
        receivesMissedDoseAlerts: true,
        receivesRefillAlerts: true,
        createdAt: date(year: 2026, month: 1, day: 6, hour: 9, minute: 20),
        updatedAt: referenceDate,
        acceptedAt: date(year: 2026, month: 1, day: 6, hour: 9, minute: 25),
        syncState: .localOnly
    )

    static let nfcTag = NfcTag(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: nil,
        stableUID: "04:A1:C2:EF:99",
        payloadIdentifier: "caretap-lisinopril-bathroom",
        label: "Bathroom bottle",
        status: .paired,
        pairedAt: date(year: 2026, month: 2, day: 10, hour: 11, minute: 0),
        lastReadAt: referenceDate,
        lastWrittenAt: date(year: 2026, month: 2, day: 10, hour: 11, minute: 0),
        createdAt: date(year: 2026, month: 2, day: 10, hour: 10, minute: 58),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let medication = Medication(
        id: UUID(),
        careProfileID: careProfile.id,
        nfcTagID: nfcTag.id,
        name: "Lisinopril",
        dosage: "10 mg",
        doseQuantity: 1,
        doseQuantityUnit: "tablet",
        instructions: "Take with breakfast.",
        bottleLabel: "Bathroom bottle",
        bottlePhotoLocalPath: nil,
        form: .bottle,
        scheduleSummary: "Every day at 8:00 AM and 8:00 PM",
        isActive: true,
        supplyCount: 18,
        createdAt: date(year: 2026, month: 2, day: 10, hour: 10, minute: 55),
        updatedAt: referenceDate,
        archivedAt: nil,
        syncState: .localOnly
    )

    static let scheduleRule = ScheduleRule(
        id: UUID(),
        medicationID: medication.id,
        careProfileID: careProfile.id,
        type: .daily,
        timezoneIdentifier: "America/Los_Angeles",
        startsOn: date(year: 2026, month: 2, day: 10, hour: 0, minute: 0),
        endsOn: nil,
        daysOfWeek: ScheduleWeekday.allCases,
        timesOfDay: [
            ScheduleTimeOfDay(hour: 8, minute: 0, label: "Morning"),
            ScheduleTimeOfDay(hour: 20, minute: 0, label: "Evening")
        ],
        intervalHours: nil,
        gracePeriodMinutes: 45,
        snoozeDurationMinutes: 20,
        isActive: true,
        createdAt: date(year: 2026, month: 2, day: 10, hour: 10, minute: 56),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let dueNowOccurrence = DoseOccurrence(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: medication.id,
        scheduleRuleID: scheduleRule.id,
        scheduledAt: date(year: 2026, month: 4, day: 3, hour: 8, minute: 0),
        windowOpensAt: date(year: 2026, month: 4, day: 3, hour: 7, minute: 45),
        windowClosesAt: date(year: 2026, month: 4, day: 3, hour: 8, minute: 45),
        snoozedUntil: nil,
        status: .dueNow,
        reminderState: .delivered,
        flags: [],
        resolvedByLogID: nil,
        resolvedAt: nil,
        createdAt: date(year: 2026, month: 4, day: 2, hour: 20, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let overdueOccurrence = DoseOccurrence(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: medication.id,
        scheduleRuleID: scheduleRule.id,
        scheduledAt: date(year: 2026, month: 4, day: 2, hour: 20, minute: 0),
        windowOpensAt: date(year: 2026, month: 4, day: 2, hour: 19, minute: 45),
        windowClosesAt: date(year: 2026, month: 4, day: 2, hour: 20, minute: 45),
        snoozedUntil: nil,
        status: .overdue,
        reminderState: .dismissed,
        flags: [],
        resolvedByLogID: nil,
        resolvedAt: nil,
        createdAt: date(year: 2026, month: 4, day: 2, hour: 6, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let snoozedOccurrence = DoseOccurrence(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: medication.id,
        scheduleRuleID: scheduleRule.id,
        scheduledAt: date(year: 2026, month: 4, day: 3, hour: 8, minute: 0),
        windowOpensAt: date(year: 2026, month: 4, day: 3, hour: 7, minute: 45),
        windowClosesAt: date(year: 2026, month: 4, day: 3, hour: 8, minute: 45),
        snoozedUntil: date(year: 2026, month: 4, day: 3, hour: 8, minute: 25),
        status: .snoozed,
        reminderState: .actionTaken,
        flags: [],
        resolvedByLogID: nil,
        resolvedAt: nil,
        createdAt: date(year: 2026, month: 4, day: 2, hour: 20, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let completedOccurrence = DoseOccurrence(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: medication.id,
        scheduleRuleID: scheduleRule.id,
        scheduledAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 0),
        windowOpensAt: date(year: 2026, month: 4, day: 2, hour: 7, minute: 45),
        windowClosesAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 45),
        snoozedUntil: nil,
        status: .completed,
        reminderState: .actionTaken,
        flags: [.resolved],
        resolvedByLogID: nil,
        resolvedAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 3),
        createdAt: date(year: 2026, month: 4, day: 1, hour: 20, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let acceptedDoseLog = DoseLog(
        id: UUID(),
        careProfileID: careProfile.id,
        medicationID: medication.id,
        occurrenceID: completedOccurrence.id,
        actorUserID: nil,
        source: .nfcTap,
        action: .confirmTaken,
        validationState: .accepted,
        effectiveAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 3),
        loggedAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 3),
        note: "Bottle tap from patient phone",
        supersedesLogID: nil,
        nfcTagID: nfcTag.id,
        createdAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 3),
        updatedAt: date(year: 2026, month: 4, day: 2, hour: 8, minute: 3),
        syncState: .localOnly
    )

    static let reminderPreference = ReminderPreference(
        id: UUID(),
        userID: user.id,
        careProfileID: careProfile.id,
        channels: [.localNotification, .liveActivity, .caregiverEscalation],
        leadTimeMinutes: 0,
        followUpAfterMinutes: 20,
        maxFollowUps: 1,
        quietHours: QuietHours(startHour: 22, startMinute: 0, endHour: 7, endMinute: 0),
        enablesLiveActivity: true,
        createdAt: date(year: 2026, month: 2, day: 10, hour: 11, minute: 5),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let alertPolicy = AlertPolicy(
        id: UUID(),
        careRelationshipID: careRelationship.id,
        notifyOnMissedDose: true,
        missedDoseDelayMinutes: 60,
        notifyOnLateDose: true,
        lateDoseDelayMinutes: 20,
        notifyOnSkippedDose: true,
        notifyOnRefillRisk: true,
        refillRiskThresholdDays: 4,
        createdAt: date(year: 2026, month: 2, day: 10, hour: 11, minute: 8),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let refillState = RefillState(
        id: UUID(),
        medicationID: medication.id,
        quantityOnHand: 18,
        dosesRemainingEstimate: 18,
        estimatedRunOutDate: date(year: 2026, month: 4, day: 12, hour: 8, minute: 0),
        riskLevel: .watch,
        lastCalculatedAt: referenceDate,
        createdAt: date(year: 2026, month: 3, day: 28, hour: 10, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let invitation = Invitation(
        id: UUID(),
        careProfileID: careProfile.id,
        createdByUserID: user.id,
        recipientDisplayName: "Maya Nguyen",
        recipientContact: "maya@example.com",
        offeredRole: .caregiver,
        relationshipLabel: .sibling,
        status: .pending,
        inviteToken: "preview-invite-token",
        expiresAt: date(year: 2026, month: 4, day: 10, hour: 17, minute: 0),
        acceptedAt: nil,
        createdAt: date(year: 2026, month: 4, day: 3, hour: 7, minute: 0),
        updatedAt: referenceDate,
        syncState: .localOnly
    )

    static let liveActivityDueNow = CareTapDoseActivityAttributes.ContentState(
        medicationName: medication.name,
        dosage: medication.dosage,
        dueTime: dueNowOccurrence.scheduledAt,
        status: .dueNow,
        primaryActionLabel: "Tap Bottle"
    )

    static let liveActivityOverdue = CareTapDoseActivityAttributes.ContentState(
        medicationName: medication.name,
        dosage: medication.dosage,
        dueTime: overdueOccurrence.scheduledAt,
        status: .overdue,
        primaryActionLabel: "Confirm Now"
    )

    static let liveActivitySnoozed = CareTapDoseActivityAttributes.ContentState(
        medicationName: medication.name,
        dosage: medication.dosage,
        dueTime: snoozedOccurrence.snoozedUntil ?? snoozedOccurrence.scheduledAt,
        status: .snoozed,
        primaryActionLabel: "Tap When Ready"
    )

    static let liveActivityCompleted = CareTapDoseActivityAttributes.ContentState(
        medicationName: medication.name,
        dosage: medication.dosage,
        dueTime: completedOccurrence.resolvedAt ?? completedOccurrence.scheduledAt,
        status: .completed,
        primaryActionLabel: "View Log"
    )

    private static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? .now
    }
}
