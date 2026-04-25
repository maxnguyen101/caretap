import Foundation

enum CareTapStateBuilder {
    static func patientHomeState(
        user: User,
        careProfile: CareProfile,
        relationships: [CareRelationship],
        medications: [Medication],
        occurrences: [DoseOccurrence],
        destination: CareTapDestination
    ) -> PatientHomeState {
        let medicationLookup = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })
        let currentOccurrence = currentDoseOccurrence(in: occurrences)
        let currentMedication = currentOccurrence.flatMap { medicationLookup[$0.medicationID] }
        let upcomingOccurrence = nextUpcomingOccurrence(in: occurrences, excluding: currentOccurrence?.id)
        let upcomingMedication = upcomingOccurrence.flatMap { medicationLookup[$0.medicationID] }
        let todayOccurrences = occurrences.filter { Calendar.current.isDateInToday($0.scheduledAt) }
        let caregiverCount = relationships.filter { $0.status == .active }.count

        let heroMedication = currentMedication ?? medications.first
        let heroOccurrence = currentOccurrence ?? occurrences.sorted { $0.scheduledAt < $1.scheduledAt }.first

        let excludedIDs: Set<UUID> = [currentOccurrence?.id, upcomingOccurrence?.id].compactMap { $0 }.reduce(into: Set<UUID>()) { $0.insert($1) }
        let nextItems = occurrences
            .filter { !$0.isResolved && !excludedIDs.contains($0.id) }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(4)
            .map { occ -> UpcomingMedicationState in
                let med = medicationLookup[occ.medicationID]
                return UpcomingMedicationState(
                    title: med?.displayTitle ?? "Unknown item",
                    timeText: occ.scheduledAt.formatted(date: .omitted, time: .shortened),
                    contextLabel: contextLabel(for: occ)
                )
            }

        return PatientHomeState(
            profile: personProfile(from: careProfile, fallbackName: user.displayName),
            currentDose: PatientDoseCardState(
                medicationName: heroMedication?.displayTitle ?? "Add an item",
                scheduledText: scheduledText(for: heroOccurrence, medication: heroMedication),
                bottlePhotoLocalPath: heroMedication?.bottlePhotoLocalPath,
                focusState: focusState(for: heroOccurrence),
                primaryActionTitle: heroPrimaryActionTitle(
                    for: heroOccurrence,
                    medication: heroMedication
                ),
                primaryActionSymbol: heroPrimaryActionSymbol(
                    for: heroOccurrence,
                    medication: heroMedication
                ),
                secondaryActions: heroSecondaryActions(for: heroOccurrence)
            ),
            progress: DailyProgress(
                completedCount: todayOccurrences.filter(\.isResolved).count,
                totalCount: todayOccurrences.count
            ),
            upcomingMedication: UpcomingMedicationState(
                title: upcomingMedication?.displayTitle ?? "You’re clear",
                timeText: upcomingOccurrence.map { $0.scheduledAt.formatted(date: .abbreviated, time: .shortened) } ?? "Nothing else is scheduled",
                contextLabel: upcomingOccurrence.map { contextLabel(for: $0) } ?? "All caught up"
            ),
            upcomingItems: Array(nextItems),
            careTeamBanner: CareTeamBannerState(
                title: caregiverCount == 0
                    ? "Private on this phone"
                    : caregiverCount == 1
                        ? "Shared with 1 caregiver"
                        : "Shared with \(caregiverCount) caregivers",
                message: caregiverCount == 0
                    ? "Invite someone later if you want shared support."
                    : "Only confirmed logs are shared with the care circle.",
                memberInitials: [],
                memberCount: caregiverCount
            ),
            selectedDestination: destination
        )
    }

    static func caregiverHomeState(
        caregiver: User,
        lovedOne: CareProfile,
        linkedProfiles: [CareProfile],
        activeProfileRelationships: [CareRelationship],
        medications: [Medication],
        occurrences: [DoseOccurrence],
        refillStates: [RefillState],
        destination: CareTapDestination
    ) -> CaregiverHomeState {
        let medicationLookup = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })
        let timelineEvents = occurrences
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(5)
            .compactMap { occurrence -> CaregiverTimelineEvent? in
                guard let medication = medicationLookup[occurrence.medicationID] else {
                    return nil
                }

                return CaregiverTimelineEvent(
                    title: medication.displayTitle,
                    scheduledText: occurrence.scheduledAt.formatted(date: .omitted, time: .shortened),
                    status: caregiverTimelineStatus(for: occurrence),
                    detailText: occurrence.resolvedAt.map { "Resolved \($0.formatted(date: .omitted, time: .shortened))" }
                )
            }

        let refillRisk = refillStates
            .sorted { lhs, rhs in lhs.riskLevel.sortOrder > rhs.riskLevel.sortOrder }
            .first
        let overdueCount = occurrences.filter { $0.status == .overdue || $0.status == .missed }.count
        let sevenDayWindowStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentOccurrences = occurrences.filter { $0.scheduledAt >= sevenDayWindowStart }
        let resolvedRecentCount = recentOccurrences.filter(\.isResolved).count
        let recentAdherence = recentOccurrences.isEmpty ? 1 : Double(resolvedRecentCount) / Double(recentOccurrences.count)
        let orderedProfiles = linkedProfiles
            .sorted { lhs, rhs in
                if lhs.id == lovedOne.id { return true }
                if rhs.id == lovedOne.id { return false }
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
        let linkedPeople = orderedProfiles.map { profile in
            CaregiverLinkedPersonState(
                id: profile.id,
                displayName: profile.displayName,
                initials: profile.initials,
                showsAttention: profile.id == lovedOne.id && overdueCount > 0,
                isSelected: profile.id == lovedOne.id
            )
        }
        let careCircleCount = max(activeProfileRelationships.count, 1)

        let alertLevel: CaregiverAlertLevel
        let alertDetail: String
        if overdueCount > 0,
           let occurrence = occurrences.first(where: { $0.status == .overdue || $0.status == .missed }),
           let medication = medicationLookup[occurrence.medicationID] {
            alertLevel = .needsAttention
            alertDetail = "Needs attention: \(medication.displayTitle)"
        } else if let refillRisk, refillRisk.riskLevel != .onTrack {
            let medication = medicationLookup[refillRisk.medicationID]
            alertLevel = .refillRisk
            alertDetail = "\(medication?.displayTitle ?? "This item") needs a refill plan"
        } else {
            alertLevel = .onTrack
            alertDetail = "Everything important is on track right now"
        }

        return CaregiverHomeState(
            caregiverProfile: personProfile(from: caregiver),
            lovedOne: personProfile(from: lovedOne, fallbackName: lovedOne.displayName),
            linkedPeople: linkedPeople,
            householdSummary: orderedProfiles.count == 1
                ? "1 person linked"
                : "\(orderedProfiles.count) people linked",
            careCircleSummary: careCircleCount == 1
                ? "1 caregiver on this care circle"
                : "\(careCircleCount) caregivers on this care circle",
            alertLevel: alertLevel,
            alertDetail: alertDetail,
            statusCards: [
                CaregiverStatusCardState(
                    title: "Status",
                    message: overdueCount > 0
                        ? "\(overdueCount) unresolved check-in\(overdueCount == 1 ? "" : "s")"
                        : "No unresolved check-ins right now",
                    tone: overdueCount > 0 ? .alert : .success
                ),
                CaregiverStatusCardState(
                    title: "Sharing",
                    message: orderedProfiles.count == 1
                        ? careCircleSummary(for: careCircleCount)
                        : "\(orderedProfiles.count) linked people • \(careCircleSummary(for: careCircleCount))",
                    tone: orderedProfiles.count > 1 ? .sage : .neutral
                ),
                CaregiverStatusCardState(
                    title: "Trend",
                    message: recentOccurrences.isEmpty
                        ? "Trend builds after the first few logged doses"
                        : "\(Int((recentAdherence * 100).rounded()))% resolved over the last 7 days",
                    tone: recentAdherence >= 0.85 ? .success : (recentAdherence >= 0.6 ? .warm : .alert)
                )
            ],
            quickActions: {
                let hasLogPermission = activeProfileRelationships.contains { $0.permissions.contains(.logDose) }
                var actions = [
                    QuickActionState(title: "Call", systemImage: "phone.fill", tone: .sage, kind: .call),
                    QuickActionState(title: "Message", systemImage: "message.fill", tone: .mist, kind: .message),
                    QuickActionState(title: "Review Meds", systemImage: "pills.fill", tone: .neutral, kind: .reviewMedications)
                ]
                if hasLogPermission && occurrences.contains(where: { !$0.isResolved }) {
                    actions.insert(
                        QuickActionState(title: "Log Dose", systemImage: "checkmark.circle.fill", tone: .success, kind: .resolveDose),
                        at: 0
                    )
                }
                return actions
            }(),
            timelineDateLabel: Date.now.formatted(date: .abbreviated, time: .omitted),
            timelineEvents: Array(timelineEvents),
            selectedDestination: destination
        )
    }

    static func patientMedicationRows(
        medications: [Medication],
        occurrences: [DoseOccurrence],
        refillStates: [UUID: RefillState],
        logsByOccurrenceID: [UUID: [DoseLog]],
        relationships: [CareRelationship]
    ) -> [PatientMedicationRowState] {
        medications.map { medication in
            let medicationOccurrences = occurrences
                .filter { $0.medicationID == medication.id }
                .sorted { $0.scheduledAt < $1.scheduledAt }
            let recentOccurrences = medicationOccurrences.suffix(10)
            let resolvedCount = recentOccurrences.filter(\.isResolved).count
            let adherencePercent = recentOccurrences.isEmpty ? 0 : Int((Double(resolvedCount) / Double(recentOccurrences.count) * 100).rounded())
            let currentOccurrence = medicationOccurrences.first { occurrence in
                !occurrence.isResolved && (.dueNow == occurrence.status || .overdue == occurrence.status || .missed == occurrence.status || .snoozed == occurrence.status)
            }
            let nextOccurrence = medicationOccurrences.first { occurrence in
                !occurrence.isResolved && occurrence.id != currentOccurrence?.id && (occurrence.status == .scheduled || occurrence.status == .dueNow || occurrence.status == .snoozed || occurrence.status == .overdue)
            }
            let refillLabel = refillStates[medication.id].map { refillState in
                switch refillState.riskLevel {
                case .onTrack:
                    return "Refill on track"
                case .watch:
                    return "Refill watch"
                case .urgent:
                    return "Refill urgent"
                case .depleted:
                    return "Refill depleted"
                }
            } ?? "Refill estimate pending"

            let refillStatus = refillStates[medication.id].map { refillState in
                PatientRefillStatusState(
                    headline: refillHeadline(for: refillState),
                    detail: refillState.estimatedRunOutDate.map {
                        "Estimated run out \($0.formatted(date: .abbreviated, time: .omitted))"
                    } ?? "Supply estimate updates as check-ins are resolved.",
                    quantityText: refillState.quantityOnHand.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) on hand" }
                        ?? "\(refillState.dosesRemainingEstimate) doses estimated",
                    thresholdText: refillThresholdText(for: refillState),
                    tone: tone(for: refillState.riskLevel)
                )
            }

            return PatientMedicationRowState(
                id: medication.id,
                title: medication.name,
                category: medication.category,
                dosage: medication.dosage,
                formText: formLabel(for: medication.form),
                containerKind: medication.containerKind,
                scheduleSummary: medication.scheduleSummary,
                bottleLabel: medication.bottleLabel,
                refillLabel: refillLabel,
                nfcLabel: medication.nfcTagID == nil ? "Manual confirmation available" : "Bottle tap paired",
                bottlePhotoLocalPath: medication.bottlePhotoLocalPath,
                currentDoseText: occurrenceDescription(for: currentOccurrence, empty: "No current dose needs attention"),
                hasCurrentOpenDose: currentOccurrence != nil,
                upcomingDoseText: occurrenceDescription(for: nextOccurrence, empty: "No more scheduled doses in view"),
                adherenceSummary: recentOccurrences.isEmpty
                    ? "Adherence history will appear after the first resolved dose."
                    : "\(adherencePercent)% of recent check-ins resolved",
                adherencePercent: recentOccurrences.isEmpty ? nil : adherencePercent,
                foodSummary: medication.instructions?.localizedCaseInsensitiveContains("food") == true
                    ? medication.instructions ?? "Meal guidance available"
                    : "No meal guidance saved",
                noteSummary: medication.instructions ?? "No extra notes saved",
                ownershipSummary: relationships.isEmpty ? "Managed on this phone" : "Visible to linked supporters",
                isActive: medication.isActive,
                isTagPaired: medication.nfcTagID != nil,
                hasRefillRisk: refillStates[medication.id].map { $0.riskLevel != .onTrack } ?? false,
                dosesRemainingEstimate: refillStates[medication.id]?.dosesRemainingEstimate,
                scheduleItems: medicationOccurrences
                    .filter { $0.scheduledAt >= Calendar.current.startOfDay(for: .now).addingTimeInterval(-4 * 60 * 60) }
                    .prefix(5)
                    .map {
                        PatientMedicationScheduleItemState(
                            id: $0.id,
                            title: scheduleItemTitle(for: $0),
                            detail: $0.scheduledAt.formatted(date: .abbreviated, time: .shortened),
                            statusText: historyStatusText(for: $0),
                            tone: historyTone(for: $0)
                        )
                    },
                historyItems: medicationOccurrences
                    .sorted { $0.scheduledAt > $1.scheduledAt }
                    .prefix(5)
                    .map { occurrence in
                        historyRow(for: occurrence, medication: medication, log: latestLog(for: occurrence.id, logsByOccurrenceID: logsByOccurrenceID))
                    },
                refillStatus: refillStatus
            )
        }
    }

    static func patientHistoryRows(
        occurrences: [DoseOccurrence],
        medications: [UUID: Medication],
        logsByOccurrenceID: [UUID: [DoseLog]]
    ) -> [PatientHistoryRowState] {
        occurrences
            .sorted { $0.scheduledAt > $1.scheduledAt }
            .prefix(12)
            .map { occurrence in
                let medicationTitle = medications[occurrence.medicationID]?.displayTitle ?? "Item"
                let medication = medications[occurrence.medicationID] ?? Medication(
                    id: occurrence.medicationID,
                    careProfileID: occurrence.careProfileID,
                    nfcTagID: nil,
                    name: medicationTitle,
                    dosage: "",
                    doseQuantity: nil,
                    doseQuantityUnit: nil,
                    instructions: nil,
                    bottleLabel: "",
                    bottlePhotoLocalPath: nil,
                    form: .bottle,
                    scheduleSummary: "",
                    isActive: true,
                    supplyCount: nil,
                    createdAt: occurrence.createdAt,
                    updatedAt: occurrence.updatedAt,
                    archivedAt: nil,
                    syncState: .localOnly
                )
                return historyRow(
                    for: occurrence,
                    medication: medication,
                    log: latestLog(for: occurrence.id, logsByOccurrenceID: logsByOccurrenceID)
                )
            }
    }

    static func caregiverRelationshipRows(
        relationships: [CareRelationship],
        profiles: [UUID: CareProfile],
        selectedCareProfileID: UUID?
    ) -> [CaregiverRelationshipRowState] {
        relationships.map { relationship in
            let lovedOneName = profiles[relationship.careProfileID]?.displayName ?? "Loved one"
            let permissionsSummary = relationship.permissions
                .map(\.rawValue)
                .map { $0.replacingOccurrences(of: "_", with: " ") }
                .joined(separator: ", ")

            let alertSummary = relationship.receivesMissedDoseAlerts
                ? "Missed dose alerts on"
                : "Missed dose alerts off"

            return CaregiverRelationshipRowState(
                id: relationship.id,
                careProfileID: relationship.careProfileID,
                lovedOneName: lovedOneName,
                statusText: relationship.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                accessLevelTitle: relationshipAccessLevelTitle(for: relationship),
                permissionsSummary: permissionsSummary,
                permissionTags: relationship.permissions.map { permissionLabel(for: $0) },
                alertSummary: alertSummary,
                alertPreferencesText: alertPreferencesText(for: relationship),
                receivesMissedDoseAlerts: relationship.receivesMissedDoseAlerts,
                receivesRefillAlerts: relationship.receivesRefillAlerts,
                showsAttention: relationship.status != .active,
                isSelected: relationship.careProfileID == selectedCareProfileID
            )
        }
    }

    static func caregiverInvitationRows(_ invitations: [Invitation]) -> [CaregiverInvitationRowState] {
        invitations.map { invitation in
            CaregiverInvitationRowState(
                id: invitation.id,
                recipient: invitation.recipientDisplayName ?? invitation.recipientContact,
                inviteCode: invitation.inviteToken,
                statusText: invitation.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                detail: invitation.expiresAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    static func settingsState(
        user: User,
        profile: PersonProfile,
        selectedRole: CareTapRole,
        reminderPreference: ReminderPreference?,
        relationships: [CareRelationship],
        invitations: [Invitation],
        isNotificationAuthorized: Bool,
        syncSnapshot: BackendSyncSnapshot
    ) -> SettingsViewState {
        let roleSummary = selectedRole == .patient ? "Personal view" : "Support view"
        let notificationStatus = isNotificationAuthorized ? "Enabled" : "Needs permission"
        let isLocalOnly = user.authUserID == nil || user.syncState == .localOnly
        let sharingSummary = relationships.isEmpty
            ? "No shared access yet"
            : "\(relationships.count) active connection\(relationships.count == 1 ? "" : "s")"

        return SettingsViewState(
            profile: profile,
            title: "Settings",
            subtitle: "Preferences and device tools.",
            hero: SettingsHeroState(
                title: roleSummary,
                subtitle: user.displayName,
                summary: isLocalOnly ? "Local on this iPhone. Add sync when you want recovery or sharing." : syncSummary(from: syncSnapshot)
            ),
            loadState: .loaded,
            sections: [
                SettingsSectionState(
                    title: "Profile",
                    footer: "Make this device easy to recognize at a glance.",
                    rows: [
                        SettingsRowState(symbolName: "person.crop.circle.fill", tone: .sage, title: "Name", subtitle: user.displayName, accessory: .chevron, actionKind: .accountInfo),
                        SettingsRowState(symbolName: "person.2.fill", tone: .mist, title: "Mode", subtitle: roleSummary, accessory: .label(roleSummary), actionKind: .currentRole),
                        SettingsRowState(
                            symbolName: "trash.fill",
                            tone: .alert,
                            title: isLocalOnly ? "Delete local profile" : "Delete account",
                            subtitle: isLocalOnly ? "Remove this on-device TapCare setup." : "Remove this account and its synced data.",
                            accessory: .chevron,
                            actionKind: .deleteAccount
                        )
                    ]
                ),
                SettingsSectionState(
                    title: "Notifications & Live Activities",
                    footer: "Closing a reminder never counts as a check-in.",
                    rows: [
                        SettingsRowState(
                            symbolName: "bell.badge.fill",
                            tone: .alert,
                            title: "Reminders",
                            subtitle: notificationStatus,
                            accessory: .toggle(reminderPreference?.channels.contains(.localNotification) ?? false),
                            actionKind: .remindersToggle
                        ),
                        SettingsRowState(symbolName: "clock.badge.exclamationmark", tone: .warm, title: "Lead time", subtitle: reminderPreference.map { "\($0.leadTimeMinutes) min early" } ?? "Right on time", accessory: .chevron, actionKind: .manageReminderLeadTime)
                    ]
                ),
                SettingsSectionState(
                    title: "Shared Access",
                    footer: "Only the people you connect here can see shared routine updates.",
                    rows: [
                        SettingsRowState(symbolName: "person.badge.shield.checkmark.fill", tone: .success, title: "Shared access", subtitle: sharingSummary, accessory: .chevron, actionKind: .sharedAccess),
                        SettingsRowState(symbolName: "square.and.arrow.up", tone: .mist, title: "Pending invitations", subtitle: "\(invitations.count) waiting", accessory: .chevron, actionKind: .pendingInvitations)
                    ]
                ),
                SettingsSectionState(
                    title: "NFC & Automation",
                    footer: "Tags are optional, but they make the quickest check-in flow possible.",
                    rows: [
                        SettingsRowState(symbolName: "bag.fill", tone: .warm, title: "Tap Kit", subtitle: "Order TapCare-ready NFC stickers.", accessory: .chevron, actionKind: .openTapKitShop),
                        SettingsRowState(symbolName: "dot.radiowaves.left.and.right", tone: .sage, title: "Pair or replace tag", subtitle: "Link an NFC sticker to your container.", accessory: .chevron, actionKind: .rePairCurrentTag),
                        SettingsRowState(symbolName: "wave.3.forward.circle", tone: .neutral, title: "Test tag", subtitle: "Quick scan to make sure it works.", accessory: .chevron, actionKind: .testCurrentTag)
                    ]
                ),
                SettingsSectionState(
                    title: "Data & Privacy",
                    rows: [
                        SettingsRowState(symbolName: "lock.fill", tone: .neutral, title: "Local storage", subtitle: "Your routine stays available offline on this iPhone.", accessory: .none),
                        SettingsRowState(symbolName: "square.and.arrow.up.on.square", tone: .mist, title: "Export data", subtitle: "Make a backup copy.", accessory: .chevron, actionKind: .exportSupportPackage)
                    ]
                ),
                SettingsSectionState(
                    title: "Support",
                    rows: [
                        SettingsRowState(symbolName: "questionmark.circle.fill", tone: .warm, title: "How logging works", subtitle: "See the difference between taps, manual logging, and reminders.", accessory: .chevron, actionKind: .showSupportGuide),
                        SettingsRowState(symbolName: "rectangle.portrait.and.arrow.right", tone: .alert, title: isLocalOnly ? "Leave local profile" : "Sign out", subtitle: "Return to the start screen on this iPhone.", accessory: .chevron, actionKind: .signOut)
                    ]
                )
            ]
        )
    }

    private static func syncSummary(from snapshot: BackendSyncSnapshot) -> String {
        if snapshot.pendingUploadCount == 0 && snapshot.conflictCount == 0 {
            return "Everything is up to date."
        }

        if snapshot.conflictCount == 0 {
            return "\(snapshot.pendingUploadCount) change\(snapshot.pendingUploadCount == 1 ? "" : "s") waiting to sync."
        }

        return "\(snapshot.pendingUploadCount) waiting • \(snapshot.conflictCount) conflict\(snapshot.conflictCount == 1 ? "" : "s")"
    }

    static func bestNextStepSnapshot(from homeState: PatientHomeState) -> BestNextStepSnapshot {
        BestNextStepSnapshot(
            title: homeState.currentDose.primaryActionTitle,
            subtitle: "\(homeState.currentDose.medicationName) \(homeState.currentDose.focusState.chipText.lowercased())",
            state: homeState.currentDose.focusState
        )
    }

    static func todaySnapshotWidgetState(from homeState: PatientHomeState) -> TodaySnapshotWidgetState {
        TodaySnapshotWidgetState(
            title: "\(homeState.progress.completedCount) of \(homeState.progress.totalCount) done today",
            adherenceText: {
                switch homeState.currentDose.focusState {
                case .completed:
                    return "Everything important is resolved right now"
                case .upcoming:
                    return "Nothing is due right now"
                case .dueNow, .overdue, .snoozed:
                    return "One item still needs confirmation"
                }
            }(),
            nextDoseText: "\(homeState.upcomingMedication.title) • \(homeState.upcomingMedication.timeText)",
            progressFraction: homeState.progress.fractionComplete
        )
    }

    private static func personProfile(from user: User) -> PersonProfile {
        PersonProfile(
            id: user.id,
            displayName: user.displayName,
            initials: user.initials,
            style: user.preferredRole == .patient ? .patient : .caregiver
        )
    }

    private static func personProfile(from careProfile: CareProfile, fallbackName: String) -> PersonProfile {
        PersonProfile(
            id: careProfile.id,
            displayName: careProfile.preferredName ?? careProfile.displayName,
            initials: careProfile.initials,
            style: careProfile.avatarStyle
        )
    }

    private static func currentDoseOccurrence(in occurrences: [DoseOccurrence]) -> DoseOccurrence? {
        occurrences
            .filter { isActionable($0) }
            .sorted(by: preferredOccurrenceOrder(lhs:rhs:))
            .first
    }

    private static func nextUpcomingOccurrence(in occurrences: [DoseOccurrence], excluding excludedID: UUID?) -> DoseOccurrence? {
        occurrences
            .filter { occurrence in
                occurrence.id != excludedID && !occurrence.isResolved
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    private static func preferredOccurrenceOrder(lhs: DoseOccurrence, rhs: DoseOccurrence) -> Bool {
        let lhsPriority = priority(for: lhs)
        let rhsPriority = priority(for: rhs)
        guard lhsPriority == rhsPriority else {
            return lhsPriority < rhsPriority
        }

        switch lhsPriority {
        case 0, 1, 3:
            return lhs.scheduledAt > rhs.scheduledAt
        case 2:
            return lhs.scheduledAt < rhs.scheduledAt
        default:
            return lhs.scheduledAt > rhs.scheduledAt
        }
    }

    private static func priority(for occurrence: DoseOccurrence) -> Int {
        let now = Date()

        if let snoozedUntil = occurrence.snoozedUntil, snoozedUntil > now {
            return 0
        }

        if occurrence.windowOpensAt <= now, occurrence.windowClosesAt >= now {
            return 0
        }

        if occurrence.windowClosesAt < now {
            return now.timeIntervalSince(occurrence.windowClosesAt) <= 12 * 60 * 60 ? 1 : 3
        }

        if occurrence.scheduledAt > now {
            return 2
        }

        return 3
    }

    private static func isActionable(_ occurrence: DoseOccurrence, now: Date = .now) -> Bool {
        guard !occurrence.isResolved else {
            return false
        }

        switch occurrence.status {
        case .dueNow, .overdue, .missed, .snoozed:
            return true
        case .scheduled:
            return occurrence.windowOpensAt <= now
        case .completed, .late, .skipped, .resolved:
            return false
        }
    }

    private static func focusState(for occurrence: DoseOccurrence?) -> DoseFocusState {
        guard let occurrence else {
            return .upcoming
        }

        switch occurrence.status {
        case .overdue, .missed:
            return .overdue
        case .snoozed:
            return .snoozed
        case .completed, .late, .resolved:
            return .completed
        case .dueNow:
            return .dueNow
        case .scheduled:
            return isActionable(occurrence) ? .dueNow : .upcoming
        case .skipped:
            return .completed
        }
    }

    private static func scheduledText(for occurrence: DoseOccurrence?, medication: Medication?) -> String {
        guard let occurrence else {
            return medication == nil ? "Set up your first item to start daily tracking" : "Nothing needs confirmation right now"
        }

        switch occurrence.status {
        case .snoozed:
            return "Snoozed until \((occurrence.snoozedUntil ?? occurrence.scheduledAt).formatted(date: .omitted, time: .shortened))"
        case .completed, .late, .resolved:
            return "Confirmed \((occurrence.resolvedAt ?? occurrence.scheduledAt).formatted(date: .omitted, time: .shortened))"
        case .missed:
            return "Missed from \(occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened))"
        case .dueNow:
            return "Due now • scheduled for \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        case .overdue:
            return "Due since \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        case .scheduled:
            return isActionable(occurrence)
                ? "Ready at \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
                : "Opens at \(occurrence.windowOpensAt.formatted(date: .omitted, time: .shortened))"
        case .skipped:
            return "Scheduled for \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        }
    }

    private static func heroPrimaryActionTitle(
        for occurrence: DoseOccurrence?,
        medication: Medication?
    ) -> String {
        guard let occurrence else {
            return medication == nil ? "Add Item" : "See Schedule"
        }

        if occurrence.isResolved {
            return "All Done"
        }

        if !isActionable(occurrence) {
            return "See Schedule"
        }

        return medication?.nfcTagID != nil ? "Tap Tag to Log" : "Log Dose"
    }

    private static func heroPrimaryActionSymbol(
        for occurrence: DoseOccurrence?,
        medication: Medication?
    ) -> String {
        guard let occurrence else {
            return medication == nil ? "plus.circle.fill" : "calendar"
        }

        if occurrence.isResolved {
            return "checkmark.circle.fill"
        }

        if !isActionable(occurrence) {
            return "calendar"
        }

        return medication?.nfcTagID != nil ? "dot.radiowaves.left.and.right" : "checkmark.circle.fill"
    }

    private static func heroSecondaryActions(for occurrence: DoseOccurrence?) -> [SecondaryActionState] {
        guard let occurrence, !occurrence.isResolved, isActionable(occurrence) else {
            return [
                SecondaryActionState(title: "History", tone: .mist, kind: .openHistory),
                SecondaryActionState(title: "Meds", tone: .mist, kind: .openItems),
                SecondaryActionState(title: "Settings", tone: .neutral, kind: .openSettings)
            ]
        }

        return [
            SecondaryActionState(title: "Manual", tone: .mist, kind: .manualCheckIn),
            SecondaryActionState(title: "Snooze", tone: .mist, kind: .snooze),
            SecondaryActionState(title: "Skip", tone: .alert, kind: .skip)
        ]
    }

    private static func contextLabel(for occurrence: DoseOccurrence) -> String {
        switch occurrence.status {
        case .snoozed:
            return "Snoozed"
        case .overdue, .missed:
            return "Urgent"
        case .completed, .late, .resolved:
            return "Done"
        case .dueNow:
            return "Now"
        case .scheduled:
            return isActionable(occurrence) ? "Now" : "Later"
        case .skipped:
            return "Next"
        }
    }

    private static func caregiverTimelineStatus(for occurrence: DoseOccurrence) -> CareTimelineStatus {
        switch occurrence.status {
        case .missed, .overdue:
            return .missed
        case .scheduled, .dueNow, .snoozed:
            return .upcoming
        case .completed, .late, .resolved:
            return .completed
        case .skipped:
            return .bedtime
        }
    }

    private static func historyStatusText(for occurrence: DoseOccurrence) -> String {
        switch occurrence.status {
        case .completed:
            return "Taken"
        case .late:
            return "Late"
        case .missed:
            return "Missed"
        case .skipped:
            return "Skipped"
        case .snoozed:
            return "Snoozed"
        case .dueNow:
            return "Due now"
        case .overdue:
            return "Overdue"
        case .scheduled:
            return "Scheduled"
        case .resolved:
            return "Resolved"
        }
    }

    private static func historyTone(for occurrence: DoseOccurrence) -> CareTapTone {
        switch occurrence.status {
        case .completed, .late, .resolved:
            return .success
        case .missed, .overdue:
            return .alert
        case .skipped, .snoozed:
            return .warm
        case .scheduled, .dueNow:
            return .mist
        }
    }

    private static func historyRow(
        for occurrence: DoseOccurrence,
        medication: Medication,
        log: DoseLog?
    ) -> PatientHistoryRowState {
        let confidence = confidenceLevel(for: log)
        let sourceText = log.map(sourceLabel(for:)) ?? "No confirmation yet"
        let secondaryDetail = log
            .map { "Logged \($0.loggedAt.formatted(date: .omitted, time: .shortened))" }
            ?? detailText(for: occurrence)

        return PatientHistoryRowState(
            id: occurrence.id,
            title: medication.displayTitle,
            detail: occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened),
            secondaryDetail: historySecondaryDetail(for: occurrence, log: log, fallback: secondaryDetail),
            scheduledAt: occurrence.scheduledAt,
            loggedAt: log?.loggedAt,
            statusText: historyStatusText(for: occurrence),
            sourceText: sourceText,
            confidenceText: confidence.title,
            resolutionReason: log?.resolutionReason,
            isCorrection: log?.resolutionKind == .correctedEntry || log?.resolutionKind == .undo,
            tone: historyTone(for: occurrence)
        )
    }

    private static func latestLog(
        for occurrenceID: UUID,
        logsByOccurrenceID: [UUID: [DoseLog]]
    ) -> DoseLog? {
        logsByOccurrenceID[occurrenceID]?
            .sorted { $0.loggedAt > $1.loggedAt }
            .first
    }

    private static func confidenceLevel(for log: DoseLog?) -> DoseConfirmationConfidenceLevel {
        guard let log else {
            return .unresolved
        }

        switch log.source {
        case .nfcTap:
            return .bottleTap
        case .manualPatientConfirmation:
            return .selfConfirmed
        case .caregiverLogged:
            return .caregiverLogged
        case .laterCorrection:
            return .correctedLater
        }
    }

    private static func sourceLabel(for log: DoseLog) -> String {
        switch log.source {
        case .nfcTap:
            return "Confirmed by tag tap"
        case .manualPatientConfirmation:
            return "Confirmed manually"
        case .caregiverLogged:
            return "Logged by support person"
        case .laterCorrection:
            return "Corrected later"
        }
    }

    private static func historySecondaryDetail(
        for occurrence: DoseOccurrence,
        log: DoseLog?,
        fallback: String
    ) -> String {
        guard let log else {
            return fallback
        }

        if let resolutionReason = log.resolutionReason,
           !resolutionReason.isEmpty {
            return resolutionReason
        }

        switch log.resolutionKind {
        case .lateConfirmation:
            return "Confirmed after the original window"
        case .skippedWithReason:
            return "Skipped intentionally"
        case .correctedEntry:
            return "Adjusted after the original event"
        case .undo:
            return "Previous confirmation was undone"
        case .standard:
            return fallback
        }
    }

    private static func detailText(for occurrence: DoseOccurrence) -> String {
        switch occurrence.status {
        case .snoozed:
            return "Snoozed until \((occurrence.snoozedUntil ?? occurrence.scheduledAt).formatted(date: .omitted, time: .shortened))"
        case .completed, .late, .resolved:
            return occurrence.resolvedAt.map { "Resolved \($0.formatted(date: .omitted, time: .shortened))" } ?? "Resolved"
        case .missed:
            return "Missed after the response window closed"
        case .overdue:
            return "Still waiting for confirmation"
        case .scheduled:
            return "Scheduled but not due yet"
        case .dueNow:
            return "Currently due"
        case .skipped:
            return "Marked skipped"
        }
    }

    private static func occurrenceDescription(for occurrence: DoseOccurrence?, empty: String) -> String {
        guard let occurrence else {
            return empty
        }

        switch occurrence.status {
        case .snoozed:
            return "Snoozed until \((occurrence.snoozedUntil ?? occurrence.scheduledAt).formatted(date: .omitted, time: .shortened))"
        case .completed, .late, .resolved:
            return "Resolved at \((occurrence.resolvedAt ?? occurrence.scheduledAt).formatted(date: .omitted, time: .shortened))"
        case .missed:
            return "Missed from \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        case .overdue:
            return "Overdue since \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        case .dueNow:
            return "Due now at \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        case .scheduled:
            return isActionable(occurrence)
                ? "Ready now for \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
                : "Opens at \(occurrence.windowOpensAt.formatted(date: .omitted, time: .shortened))"
        case .skipped:
            return "Skipped at \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        }
    }

    private static func scheduleItemTitle(for occurrence: DoseOccurrence) -> String {
        switch occurrence.status {
        case .dueNow:
            return "Due now"
        case .overdue:
            return "Overdue"
        case .missed:
            return "Missed"
        case .snoozed:
            return "Snoozed dose"
        case .completed, .late, .resolved:
            return "Resolved dose"
        case .scheduled:
            return "Upcoming dose"
        case .skipped:
            return "Skipped dose"
        }
    }

    private static func refillHeadline(for refillState: RefillState) -> String {
        switch refillState.riskLevel {
        case .onTrack:
            return "Refill is on track"
        case .watch:
            return "Refill watch"
        case .urgent:
            return "Refill soon"
        case .depleted:
            return "Out of supply"
        }
    }

    private static func refillThresholdText(for refillState: RefillState) -> String {
        switch refillState.riskLevel {
        case .onTrack:
            return "Plenty of doses remain"
        case .watch:
            return "Start planning the next refill"
        case .urgent:
            return "Contact the pharmacy or caregiver now"
        case .depleted:
            return "No doses are estimated to remain"
        }
    }

    private static func formLabel(for form: MedicationForm) -> String {
        switch form {
        case .bottle:
            return "Bottle"
        case .pillOrganizer:
            return "Organizer"
        case .blisterPack:
            return "Blister pack"
        case .liquid:
            return "Liquid"
        case .injection:
            return "Injection"
        case .inhaler:
            return "Inhaler"
        case .other:
            return "Item"
        }
    }

    private static func careCircleSummary(for count: Int) -> String {
        count == 1 ? "1 person in this support circle" : "\(count) people in this support circle"
    }

    private static func permissionLabel(for permission: CareRelationshipPermission) -> String {
        switch permission {
        case .viewAdherence:
            return "Monitor only"
        case .logDose:
            return "Can log doses"
        case .manageMedication:
            return "Manage meds"
        case .manageAlerts:
            return "Alert access"
        case .manageInvitations:
            return "Share access"
        }
    }

    private static func relationshipAccessLevelTitle(for relationship: CareRelationship) -> String {
        let canLog = relationship.permissions.contains(.logDose)
        let canManageMedication = relationship.permissions.contains(.manageMedication)

        if canManageMedication {
            return "Can help manage items"
        }

        if canLog {
            return "Can log on behalf"
        }

        return "Monitor only"
    }

    private static func alertPreferencesText(for relationship: CareRelationship) -> String {
        var parts: [String] = []
        if relationship.receivesMissedDoseAlerts {
            parts.append("Missed doses")
        }
        if relationship.receivesRefillAlerts {
            parts.append("Refill watch")
        }
        return parts.isEmpty ? "Alerts off" : parts.joined(separator: " • ")
    }

    private static func tone(for riskLevel: RefillRiskLevel) -> CareTapTone {
        switch riskLevel {
        case .onTrack:
            return .success
        case .watch:
            return .warm
        case .urgent, .depleted:
            return .alert
        }
    }
}

private extension RefillRiskLevel {
    var sortOrder: Int {
        switch self {
        case .depleted:
            return 3
        case .urgent:
            return 2
        case .watch:
            return 1
        case .onTrack:
            return 0
        }
    }
}
