import Foundation

enum CareTapPhaseTwoPreviewScenarios {
    static let addMedicationDefault = AddMedicationViewState(
        stepText: "Step 1 of 3",
        title: "Medication Details",
        message: "Let's start by identifying the medicine and setting up a basic schedule.",
        selectedCategory: .prescription,
        searchPlaceholder: "e.g. Lisinopril, Metformin...",
        searchQuery: "",
        lookupState: .suggestions([
            MedicationSuggestionState(title: "Atorvastatin", subtitle: "Cholesterol", symbolName: "pills.fill", tone: .alert),
            MedicationSuggestionState(title: "Amlodipine", subtitle: "Blood Pressure", symbolName: "heart.text.square.fill", tone: .success),
            MedicationSuggestionState(title: "Metformin", subtitle: "Diabetes", symbolName: "cross.case.fill", tone: .warm)
        ]),
        timeSlots: [
            MedicationTimeSlotState(title: "Morning", timeText: "8:00 AM", symbolName: "sun.max.fill", isSelected: true),
            MedicationTimeSlotState(title: "Noon", timeText: "12:00 PM", symbolName: "sun.max", isSelected: false),
            MedicationTimeSlotState(title: "Evening", timeText: "6:00 PM", symbolName: "sun.haze.fill", isSelected: true),
            MedicationTimeSlotState(title: "Night", timeText: "10:00 PM", symbolName: "moon.fill", isSelected: false)
        ],
        infoTitle: "Need exact timing?",
        infoMessage: "You’ll be able to refine exact times, details, and reminders in the next step.",
        primaryActionTitle: "Continue to Routine",
        secondaryActionTitle: "Cancel"
    )

    static let addMedicationLoading = AddMedicationViewState(
        stepText: "Step 1 of 3",
        title: "Medication Details",
        message: "We're checking common matches so the patient setup stays low-friction.",
        selectedCategory: .prescription,
        searchPlaceholder: "e.g. Lisinopril, Metformin...",
        searchQuery: "Lis",
        lookupState: .loading,
        timeSlots: addMedicationDefault.timeSlots,
        infoTitle: addMedicationDefault.infoTitle,
        infoMessage: addMedicationDefault.infoMessage,
        primaryActionTitle: addMedicationDefault.primaryActionTitle,
        secondaryActionTitle: addMedicationDefault.secondaryActionTitle
    )

    static let addMedicationEmpty = AddMedicationViewState(
        stepText: "Step 1 of 3",
        title: "Medication Details",
        message: "Search by the bottle label first. A caregiver can refine exact dosage later.",
        selectedCategory: .supplement,
        searchPlaceholder: "e.g. Lisinopril, Metformin...",
        searchQuery: "Herbal Mix",
        lookupState: .empty(query: "Herbal Mix"),
        timeSlots: addMedicationDefault.timeSlots,
        infoTitle: addMedicationDefault.infoTitle,
        infoMessage: addMedicationDefault.infoMessage,
        primaryActionTitle: addMedicationDefault.primaryActionTitle,
        secondaryActionTitle: addMedicationDefault.secondaryActionTitle
    )

    static let addMedicationError = AddMedicationViewState(
        stepText: "Step 1 of 3",
        title: "Medication Details",
        message: "Search still needs a local medication catalog. The guided schedule step is ready.",
        selectedCategory: .otc,
        searchPlaceholder: "e.g. Lisinopril, Metformin...",
        searchQuery: "Metformin",
        lookupState: .error(message: "Medication suggestions couldn't be refreshed right now."),
        timeSlots: addMedicationDefault.timeSlots,
        infoTitle: addMedicationDefault.infoTitle,
        infoMessage: addMedicationDefault.infoMessage,
        primaryActionTitle: addMedicationDefault.primaryActionTitle,
        secondaryActionTitle: addMedicationDefault.secondaryActionTitle
    )

    static let nfcReady = NFCPairingViewState(
        stepText: "Step 3 of 3",
        title: "Pair the bottle tag",
        message: "The patient will use the physical medication tap as the calmest way to resolve a dose event.",
        medicationName: "Lisinopril 10mg",
        bottleLabel: "Bathroom bottle",
        phase: .ready,
        helperTitle: "Before you start",
        helperMessage: "Make sure the NFC sticker is attached to the bottle or organizer the patient will actually reach for.",
        helpItems: [
            NFCHelpItemState(title: "Unlock the phone", detail: "Pairing is more reliable when the screen is awake."),
            NFCHelpItemState(title: "Tap near the top edge", detail: "Most iPhones detect tags near the upper back of the phone."),
            NFCHelpItemState(title: "Use the real container", detail: "This keeps future logs tied to the physical medication.")
        ],
        footerNote: "A reminder dismissed later still won’t count as taken until a tap or manual confirmation happens."
    )

    static let nfcWriting = NFCPairingViewState(
        stepText: "Step 3 of 3",
        title: nfcReady.title,
        message: nfcReady.message,
        medicationName: nfcReady.medicationName,
        bottleLabel: nfcReady.bottleLabel,
        phase: .writing,
        helperTitle: "Almost there",
        helperMessage: "Keep holding the bottle near the phone until the tag has been written and verified.",
        helpItems: [
            NFCHelpItemState(title: "Hold steady", detail: "Movement can interrupt the write cycle."),
            NFCHelpItemState(title: "Stay close", detail: "The tag should remain within a few centimeters of the phone."),
            NFCHelpItemState(title: "Don't lock the screen", detail: "Let the system finish before switching apps.")
        ],
        footerNote: nfcReady.footerNote
    )

    static let nfcSuccess = NFCPairingViewState(
        stepText: "Step 3 of 3",
        title: nfcReady.title,
        message: nfcReady.message,
        medicationName: nfcReady.medicationName,
        bottleLabel: nfcReady.bottleLabel,
        phase: .success,
        helperTitle: "What happens next",
        helperMessage: "A future tap on this bottle can create a trustworthy dose log source without adding friction for the patient.",
        helpItems: [
            NFCHelpItemState(title: "Tap to log", detail: "The patient can tap the bottle when the dose is due."),
            NFCHelpItemState(title: "Manual fallback stays available", detail: "CareTap still supports confirmation when NFC isn't practical."),
            NFCHelpItemState(title: "Caregivers see the source", detail: "Logs can later distinguish bottle taps from manual confirmation.")
        ],
        footerNote: nfcReady.footerNote
    )

    static let nfcFailure = NFCPairingViewState(
        stepText: "Step 3 of 3",
        title: nfcReady.title,
        message: nfcReady.message,
        medicationName: nfcReady.medicationName,
        bottleLabel: nfcReady.bottleLabel,
        phase: .failure,
        helperTitle: "Try these fixes",
        helperMessage: "CareTap can continue with manual confirmation now, and you can return to pairing later from NFC tools.",
        helpItems: [
            NFCHelpItemState(title: "Check the tag type", detail: "Some stickers are read-only and can't store a CareTap ID."),
            NFCHelpItemState(title: "Move to a quieter surface", detail: "Metal countertops and pill cases can interfere."),
            NFCHelpItemState(title: "Retry with a new sticker", detail: "If this tag has been written before, replacing it may be fastest.")
        ],
        footerNote: nfcReady.footerNote
    )

    static let settingsLoaded = SettingsViewState(
        profile: PersonProfile(displayName: "Ella", initials: "EL", style: .caregiver),
        title: "Settings",
        subtitle: "Preferences, sharing, and device tools.",
        hero: SettingsHeroState(
            title: "Support view",
            subtitle: "Watching over Arthur Nguyen",
            summary: "Alerts are tuned for missed check-ins, refill risk, and shared access from this phone."
        ),
        loadState: .loaded,
        sections: [
            SettingsSectionState(
                title: "Account",
                footer: "You can switch views later if this phone changes roles.",
                rows: [
                    SettingsRowState(symbolName: "person.crop.circle.fill", tone: .sage, title: "Signed in as", subtitle: "Ella Caregiver", accessory: .label("Apple"), actionKind: .accountInfo),
                    SettingsRowState(symbolName: "person.2.fill", tone: .mist, title: "Current role", subtitle: "Support view", accessory: .label("Support view"), actionKind: .currentRole),
                    SettingsRowState(symbolName: "trash.fill", tone: .alert, title: "Delete account", subtitle: "Permanently remove your CareTap account and synced data.", accessory: .chevron, actionKind: .deleteAccount)
                ]
            ),
            SettingsSectionState(
                title: "Reminders",
                rows: [
                    SettingsRowState(symbolName: "bell.badge.fill", tone: .alert, title: "Reminders", subtitle: "Enabled", accessory: .toggle(true), actionKind: .remindersToggle),
                    SettingsRowState(symbolName: "clock.badge.exclamationmark", tone: .warm, title: "Lead time", subtitle: "20 min early", accessory: .chevron, actionKind: .manageReminderLeadTime)
                ]
            ),
            SettingsSectionState(
                title: "Sharing and Access",
                rows: [
                    SettingsRowState(symbolName: "person.badge.shield.checkmark.fill", tone: .success, title: "Shared access", subtitle: "1 active connection", accessory: .chevron, actionKind: .sharedAccess),
                    SettingsRowState(symbolName: "square.and.arrow.up", tone: .mist, title: "Pending invitations", subtitle: "0 waiting", accessory: .chevron, actionKind: .pendingInvitations)
                ]
            ),
            SettingsSectionState(
                title: "NFC Tools",
                rows: [
                    SettingsRowState(symbolName: "bag.fill", tone: .warm, title: "Tap Kit", subtitle: "Order CareTap-ready NFC stickers.", accessory: .chevron, actionKind: .openTapKitShop),
                    SettingsRowState(symbolName: "dot.radiowaves.left.and.right", tone: .sage, title: "Pair or replace a tag", subtitle: "Write a new CareTap tag to a bottle, tub, tray, or organizer", accessory: .chevron, actionKind: .rePairCurrentTag),
                    SettingsRowState(symbolName: "wave.3.forward.circle", tone: .neutral, title: "Test current tag", subtitle: "Check whether a tap still resolves the right item", accessory: .chevron, actionKind: .testCurrentTag)
                ]
            ),
            SettingsSectionState(
                title: "Privacy and Data",
                rows: [
                    SettingsRowState(symbolName: "lock.fill", tone: .neutral, title: "On-device cache", subtitle: "This preview uses on-device state only.", accessory: .label("Local")),
                    SettingsRowState(symbolName: "tray.and.arrow.down.fill", tone: .mist, title: "Export support package", subtitle: "Prepare a local backup copy.", accessory: .chevron, actionKind: .exportSupportPackage)
                ]
            ),
            SettingsSectionState(
                title: "Support",
                rows: [
                    SettingsRowState(symbolName: "questionmark.circle.fill", tone: .warm, title: "How confirmation works", subtitle: "Review how taps, manual check-ins, and reminders differ.", accessory: .chevron, actionKind: .showSupportGuide),
                    SettingsRowState(symbolName: "rectangle.portrait.and.arrow.right", tone: .alert, title: "Sign out", subtitle: "Remove this session from the device.", accessory: .chevron, actionKind: .signOut)
                ]
            )
        ]
    )

    static let settingsLoading = SettingsViewState(
        profile: settingsLoaded.profile,
        title: settingsLoaded.title,
        subtitle: settingsLoaded.subtitle,
        hero: settingsLoaded.hero,
        loadState: .loading,
        sections: settingsLoaded.sections
    )

    static let settingsError = SettingsViewState(
        profile: settingsLoaded.profile,
        title: settingsLoaded.title,
        subtitle: settingsLoaded.subtitle,
        hero: settingsLoaded.hero,
        loadState: .error(message: "Settings couldn’t refresh. Showing the last saved copy from this device."),
        sections: settingsLoaded.sections
    )
}
