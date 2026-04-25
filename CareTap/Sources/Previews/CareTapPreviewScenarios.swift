import Foundation

enum CareTapPreviewScenarios {
    static let patientDueNow = PatientHomeState(
        profile: PersonProfile(displayName: "Maya", initials: "MY", style: .patient),
        currentDose: PatientDoseCardState(
            medicationName: "Lisinopril 10mg",
            scheduledText: "Scheduled for 8:00 AM",
            bottlePhotoLocalPath: nil,
            focusState: .dueNow,
            primaryActionTitle: "Tap Tag to Log",
            primaryActionSymbol: "dot.radiowaves.left.and.right",
            secondaryActions: [
                SecondaryActionState(title: "Manual", tone: .mist, kind: .manualCheckIn),
                SecondaryActionState(title: "Snooze", tone: .mist, kind: .snooze),
                SecondaryActionState(title: "Skip", tone: .alert, kind: .skip)
            ]
        ),
        progress: DailyProgress(completedCount: 3, totalCount: 4),
        upcomingMedication: UpcomingMedicationState(
            title: "Metformin 500mg",
            timeText: "Today at 12:30 PM",
            contextLabel: "Lunch"
        ),
        upcomingItems: [
            UpcomingMedicationState(title: "Atorvastatin 20mg", timeText: "6:00 PM", contextLabel: "Later"),
            UpcomingMedicationState(title: "Vitamin D 2000 IU", timeText: "9:00 PM", contextLabel: "Later")
        ],
        careTeamBanner: CareTeamBannerState(
            title: "Shared with 2 caregivers",
            message: "Only confirmed doses are shared with the care circle.",
            memberInitials: [],
            memberCount: 2
        ),
        selectedDestination: .home
    )

    static let patientSnoozed = PatientHomeState(
        profile: PersonProfile(displayName: "Maya", initials: "MY", style: .patient),
        currentDose: PatientDoseCardState(
            medicationName: "Lisinopril 10mg",
            scheduledText: "Snoozed until 8:20 AM",
            bottlePhotoLocalPath: nil,
            focusState: .snoozed,
            primaryActionTitle: "Tap When Ready",
            primaryActionSymbol: "hourglass",
            secondaryActions: [
                SecondaryActionState(title: "Manual", tone: .mist, kind: .manualCheckIn),
                SecondaryActionState(title: "Snooze", tone: .mist, kind: .snooze),
                SecondaryActionState(title: "Skip", tone: .alert, kind: .skip)
            ]
        ),
        progress: DailyProgress(completedCount: 2, totalCount: 4),
        upcomingMedication: UpcomingMedicationState(
            title: "Metformin 500mg",
            timeText: "Today at 12:30 PM",
            contextLabel: "Lunch"
        ),
        upcomingItems: [
            UpcomingMedicationState(title: "Atorvastatin 20mg", timeText: "6:00 PM", contextLabel: "Later")
        ],
        careTeamBanner: CareTeamBannerState(
            title: "Shared with 2 caregivers",
            message: "Only confirmed doses are shared with the care circle.",
            memberInitials: [],
            memberCount: 2
        ),
        selectedDestination: .home
    )

    static let patientCompleted = PatientHomeState(
        profile: PersonProfile(displayName: "Maya", initials: "MY", style: .patient),
        currentDose: PatientDoseCardState(
            medicationName: "Lisinopril 10mg",
            scheduledText: "Confirmed at 8:03 AM",
            bottlePhotoLocalPath: nil,
            focusState: .completed,
            primaryActionTitle: "All Done",
            primaryActionSymbol: "checkmark.circle.fill",
            secondaryActions: [
                SecondaryActionState(title: "History", tone: .mist, kind: .openHistory),
                SecondaryActionState(title: "Meds", tone: .mist, kind: .openItems),
                SecondaryActionState(title: "Settings", tone: .neutral, kind: .openSettings)
            ]
        ),
        progress: DailyProgress(completedCount: 4, totalCount: 4),
        upcomingMedication: UpcomingMedicationState(
            title: "Atorvastatin 20mg",
            timeText: "Tonight at 9:00 PM",
            contextLabel: "Bedtime"
        ),
        upcomingItems: [],
        careTeamBanner: CareTeamBannerState(
            title: "Private on this phone",
            message: "Invite someone later if you want shared support.",
            memberInitials: [],
            memberCount: 0
        ),
        selectedDestination: .home
    )

    static let caregiverAttentionNeeded = CaregiverHomeState(
        caregiverProfile: PersonProfile(displayName: "Ella", initials: "EL", style: .caregiver),
        lovedOne: PersonProfile(displayName: "Arthur", initials: "AN", style: .lovedOne, showsAlertDot: true),
        linkedPeople: [
            CaregiverLinkedPersonState(id: UUID(), displayName: "Arthur", initials: "AN", showsAttention: true, isSelected: true),
            CaregiverLinkedPersonState(id: UUID(), displayName: "Maya", initials: "MY", showsAttention: false, isSelected: false),
            CaregiverLinkedPersonState(id: UUID(), displayName: "Leo", initials: "LE", showsAttention: false, isSelected: false)
        ],
        householdSummary: "3 people linked",
        careCircleSummary: "2 caregivers on this care circle",
        alertLevel: .needsAttention,
        alertDetail: "Missed: Lisinopril 10mg at 8:00 AM",
        statusCards: [
            CaregiverStatusCardState(
                title: "Status",
                message: "Last confirmed: yesterday at 8:03 PM via tag tap",
                tone: .neutral
            ),
            CaregiverStatusCardState(
                title: "Logistics",
                message: "Refill left: 4 days",
                tone: .alert
            )
        ],
        quickActions: [
            QuickActionState(title: "Call Arthur", systemImage: "phone.fill", tone: .sage, kind: .call),
            QuickActionState(title: "Message", systemImage: "message", tone: .neutral, kind: .message)
        ],
        timelineDateLabel: "Oct 24",
        timelineEvents: [
            CaregiverTimelineEvent(title: "Lisinopril 10mg", scheduledText: "Scheduled for 8:00 AM", status: .missed),
            CaregiverTimelineEvent(title: "Metformin 500mg", scheduledText: "Scheduled for 1:00 PM", status: .upcoming),
            CaregiverTimelineEvent(title: "Atorvastatin 20mg", scheduledText: "Scheduled for 9:00 PM", status: .bedtime),
            CaregiverTimelineEvent(title: "Vitamins (Daily)", scheduledText: "Logged at 7:45 AM", status: .completed, detailText: "via tag tap")
        ],
        selectedDestination: .home
    )

    static let caregiverRefillRisk = CaregiverHomeState(
        caregiverProfile: PersonProfile(displayName: "Ella", initials: "EL", style: .caregiver),
        lovedOne: PersonProfile(displayName: "Arthur", initials: "AN", style: .lovedOne),
        linkedPeople: [
            CaregiverLinkedPersonState(id: UUID(), displayName: "Arthur", initials: "AN", showsAttention: false, isSelected: true),
            CaregiverLinkedPersonState(id: UUID(), displayName: "Maya", initials: "MY", showsAttention: false, isSelected: false)
        ],
        householdSummary: "2 people linked",
        careCircleSummary: "2 caregivers on this care circle",
        alertLevel: .refillRisk,
        alertDetail: "Refill risk: only 2 days left on Metformin 500mg",
        statusCards: [
            CaregiverStatusCardState(
                title: "Status",
                message: "All doses confirmed so far today",
                tone: .success
            ),
            CaregiverStatusCardState(
                title: "Logistics",
                message: "Pharmacy pickup still needs coordination",
                tone: .warm
            )
        ],
        quickActions: [
            QuickActionState(title: "Call Arthur", systemImage: "phone.fill", tone: .sage, kind: .call),
            QuickActionState(title: "Review Meds", systemImage: "pills.fill", tone: .neutral, kind: .reviewMedications)
        ],
        timelineDateLabel: "Oct 24",
        timelineEvents: [
            CaregiverTimelineEvent(title: "Lisinopril 10mg", scheduledText: "Logged at 8:03 AM", status: .completed),
            CaregiverTimelineEvent(title: "Metformin 500mg", scheduledText: "Scheduled for 1:00 PM", status: .upcoming),
            CaregiverTimelineEvent(title: "Atorvastatin 20mg", scheduledText: "Scheduled for 9:00 PM", status: .bedtime)
        ],
        selectedDestination: .home
    )

    static let caregiverOnTrack = CaregiverHomeState(
        caregiverProfile: PersonProfile(displayName: "Ella", initials: "EL", style: .caregiver),
        lovedOne: PersonProfile(displayName: "Arthur", initials: "AN", style: .lovedOne),
        linkedPeople: [
            CaregiverLinkedPersonState(id: UUID(), displayName: "Arthur", initials: "AN", showsAttention: false, isSelected: true),
            CaregiverLinkedPersonState(id: UUID(), displayName: "Maya", initials: "MY", showsAttention: false, isSelected: false)
        ],
        householdSummary: "2 people linked",
        careCircleSummary: "3 caregivers on this care circle",
        alertLevel: .onTrack,
        alertDetail: "All scheduled doses have been confirmed today",
        statusCards: [
            CaregiverStatusCardState(
                title: "Status",
                message: "Last confirmed: today at 1:02 PM via tag tap",
                tone: .success
            ),
            CaregiverStatusCardState(
                title: "Logistics",
                message: "Refill left: 12 days",
                tone: .neutral
            )
        ],
        quickActions: [
            QuickActionState(title: "Call Arthur", systemImage: "phone.fill", tone: .sage, kind: .call),
            QuickActionState(title: "Message", systemImage: "message", tone: .neutral, kind: .message)
        ],
        timelineDateLabel: "Oct 24",
        timelineEvents: [
            CaregiverTimelineEvent(title: "Lisinopril 10mg", scheduledText: "Logged at 8:03 AM", status: .completed),
            CaregiverTimelineEvent(title: "Metformin 500mg", scheduledText: "Logged at 1:02 PM", status: .completed),
            CaregiverTimelineEvent(title: "Atorvastatin 20mg", scheduledText: "Scheduled for 9:00 PM", status: .bedtime)
        ],
        selectedDestination: .home
    )
}
