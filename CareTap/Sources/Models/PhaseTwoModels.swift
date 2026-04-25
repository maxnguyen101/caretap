import Foundation

struct MedicationSuggestionState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let category: MedicationCategory
    let symbolName: String
    let tone: CareTapTone
    let aliases: [String]
    let defaultDosage: String?
    let defaultContainerKind: ContainerKind
    let defaultReminderLeadTimeMinutes: Int?
    let defaultTimeTitles: [String]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: MedicationCategory = .prescription,
        symbolName: String,
        tone: CareTapTone,
        aliases: [String] = [],
        defaultDosage: String? = nil,
        defaultContainerKind: ContainerKind = .bottle,
        defaultReminderLeadTimeMinutes: Int? = nil,
        defaultTimeTitles: [String] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.symbolName = symbolName
        self.tone = tone
        self.aliases = aliases
        self.defaultDosage = defaultDosage
        self.defaultContainerKind = defaultContainerKind
        self.defaultReminderLeadTimeMinutes = defaultReminderLeadTimeMinutes
        self.defaultTimeTitles = defaultTimeTitles
    }
}

enum MedicationLookupState: Hashable {
    case suggestions([MedicationSuggestionState])
    case loading
    case empty(query: String)
    case error(message: String)
}

struct MedicationTimeSlotState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let timeText: String
    let symbolName: String
    let isSelected: Bool

    init(
        id: UUID = UUID(),
        title: String,
        timeText: String,
        symbolName: String,
        isSelected: Bool
    ) {
        self.id = id
        self.title = title
        self.timeText = timeText
        self.symbolName = symbolName
        self.isSelected = isSelected
    }
}

struct AddMedicationViewState: Hashable {
    let stepText: String
    let title: String
    let message: String
    let selectedCategory: MedicationCategory
    let searchPlaceholder: String
    let searchQuery: String
    let lookupState: MedicationLookupState
    let timeSlots: [MedicationTimeSlotState]
    let infoTitle: String
    let infoMessage: String
    let primaryActionTitle: String
    let secondaryActionTitle: String
}

enum NFCPairingPhase: String, Hashable, CaseIterable {
    case ready
    case writing
    case success
    case failure

    var badgeText: String {
        switch self {
        case .ready:
            return "Ready"
        case .writing:
            return "Working"
        case .success:
            return "Ready"
        case .failure:
            return "Try Again"
        }
    }

    var title: String {
        switch self {
        case .ready:
            return "Ready to pair"
        case .writing:
            return "Hold the container near the top of the iPhone"
        case .success:
            return "Tag paired and ready"
        case .failure:
            return "Pairing did not finish"
        }
    }

    var message: String {
        switch self {
        case .ready:
            return "When the tag is close, CareTap writes a secure local ID so future taps log the right check-in."
        case .writing:
            return "Keep the phone steady for a moment while the tag is written and checked."
        case .success:
            return "This tag can now confirm future check-ins with one quick tap."
        case .failure:
            return "The tag was not writable or moved too soon. Try again, or keep going with manual check-ins for now."
        }
    }

    var symbolName: String {
        switch self {
        case .ready:
            return "dot.radiowaves.left.and.right"
        case .writing:
            return "wave.3.right.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    var tone: CareTapTone {
        switch self {
        case .ready:
            return .sage
        case .writing:
            return .warm
        case .success:
            return .success
        case .failure:
            return .alert
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .ready:
            return "Start Pairing"
        case .writing:
            return "Working"
        case .success:
            return "Continue"
        case .failure:
            return "Try Again"
        }
    }

    var secondaryActionTitle: String {
        switch self {
        case .success:
            return "Pair Another"
        default:
            return "Back"
        }
    }
}

struct NFCHelpItemState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String

    init(id: UUID = UUID(), title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

struct NFCPairingViewState: Hashable {
    let stepText: String
    let title: String
    let message: String
    let medicationName: String
    let bottleLabel: String
    let phase: NFCPairingPhase
    let helperTitle: String
    let helperMessage: String
    let helpItems: [NFCHelpItemState]
    let footerNote: String
    var automationURL: URL? = nil
    var primaryActionTitle: String? = nil
    var secondaryActionTitle: String? = nil
}

struct TapKitFeatureState: Identifiable, Hashable {
    let id: UUID
    let symbolName: String
    let title: String
    let detail: String

    init(
        id: UUID = UUID(),
        symbolName: String,
        title: String,
        detail: String
    ) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
    }
}

struct TapKitOrderConfirmationState: Hashable {
    let pack: TapKitPack
    let confirmedAt: Date
}

struct TapKitShopViewState: Hashable {
    let badgeText: String
    let title: String
    let subtitle: String
    let detail: String
    let checkoutNote: String
    let features: [TapKitFeatureState]
    let packs: [TapKitPack]
    let selectedPackSlug: TapKitPack.Slug
    let supportURL: URL?
    let isCheckoutConfigured: Bool
    let founderNote: String
    let confirmation: TapKitOrderConfirmationState?
    let primaryActionTitle: String
    let secondaryActionTitle: String

    var selectedPack: TapKitPack {
        packs.first(where: { $0.slug == selectedPackSlug }) ?? packs[0]
    }

    static func `default`(
        isCheckoutConfigured: Bool,
        selectedPackSlug: TapKitPack.Slug = TapKitPack.recommendedSlug,
        confirmation: TapKitOrderConfirmationState? = nil
    ) -> TapKitShopViewState {
        let packs = TapKitPack.catalog
        let selectedPack = packs.first(where: { $0.slug == selectedPackSlug }) ?? packs[1]
        return TapKitShopViewState(
            badgeText: "TapKit",
            title: "Order your TapKit",
            subtitle: "Pre-printed NFC stickers built to pair with CareTap in one tap.",
            detail: "Pick the pack that fits your routine. Free US shipping on orders $25+. We typically ship within one business day.",
            checkoutNote: isCheckoutConfigured
                ? "Secure Stripe checkout opens inside CareTap. Apple Pay and major cards supported."
                : "Stripe checkout will be connected for this build soon. You can still browse pack options.",
            features: [
                TapKitFeatureState(
                    symbolName: "tag.fill",
                    title: "Pre-tested NFC stickers",
                    detail: "Each tag is verified to write cleanly with iPhone before it ships."
                ),
                TapKitFeatureState(
                    symbolName: "shippingbox.fill",
                    title: "Made for real containers",
                    detail: "Sized for bottles, organizers, trays, and packet boxes."
                ),
                TapKitFeatureState(
                    symbolName: "bolt.badge.checkmark.fill",
                    title: "Fast CareTap pairing",
                    detail: "Pair once in the app, then use tap-to-log every day."
                ),
                TapKitFeatureState(
                    symbolName: "person.2.wave.2.fill",
                    title: "Designed for shared care",
                    detail: "Helpful when more than one person keeps a routine on track."
                )
            ],
            packs: packs,
            selectedPackSlug: selectedPack.slug,
            supportURL: URL(string: "mailto:support@tapcare.app?subject=CareTap%20TapKit"),
            isCheckoutConfigured: isCheckoutConfigured,
            founderNote: "I’m Max — a USC pre-med student building TapCare. Every kit is hand-tested before it leaves my desk so it works the moment it arrives.",
            confirmation: confirmation,
            primaryActionTitle: "Buy TapKit",
            secondaryActionTitle: "Questions"
        )
    }
}

enum SettingsRowAccessory: Hashable {
    case chevron
    case toggle(Bool)
    case label(String)
    case none
}

enum SettingsActionKind: String, Hashable, CaseIterable {
    case accountInfo
    case openPremium
    case currentRole
    case deleteAccount
    case remindersToggle
    case sharedAccess
    case pendingInvitations
    case manageRole
    case linkCaregiver
    case enterInviteCode
    case manageQuietHours
    case manageReminderLeadTime
    case exportSupportPackage
    case rePairCurrentTag
    case exportData
    case rePairCurrentMedication
    case testCurrentTag
    case openTapKitShop
    case showSupportGuide
    case shareDiagnostics
    case signOut
}

struct SettingsRowState: Identifiable, Hashable {
    let id: UUID
    let symbolName: String
    let tone: CareTapTone
    let title: String
    let subtitle: String?
    let accessory: SettingsRowAccessory
    let actionKind: SettingsActionKind?

    init(
        id: UUID = UUID(),
        symbolName: String,
        tone: CareTapTone,
        title: String,
        subtitle: String? = nil,
        accessory: SettingsRowAccessory,
        actionKind: SettingsActionKind? = nil
    ) {
        self.id = id
        self.symbolName = symbolName
        self.tone = tone
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.actionKind = actionKind
    }
}

struct SettingsSectionState: Identifiable, Hashable {
    let id: UUID
    let title: String
    let footer: String?
    let rows: [SettingsRowState]

    init(id: UUID = UUID(), title: String, footer: String? = nil, rows: [SettingsRowState]) {
        self.id = id
        self.title = title
        self.footer = footer
        self.rows = rows
    }
}

enum SettingsScreenLoadState: Hashable {
    case loaded
    case loading
    case error(message: String)
}

struct SettingsHeroState: Hashable {
    let title: String
    let subtitle: String
    let summary: String
}

struct SettingsViewState: Hashable {
    let profile: PersonProfile
    let title: String
    let subtitle: String
    let hero: SettingsHeroState
    let loadState: SettingsScreenLoadState
    let sections: [SettingsSectionState]
}
