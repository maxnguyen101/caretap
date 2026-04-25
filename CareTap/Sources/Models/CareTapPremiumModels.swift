import Foundation

enum CareTapPremiumPlan: String, CaseIterable, Identifiable, Codable, Hashable {
    case monthly
    case yearly

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var fallbackPriceText: String {
        switch self {
        case .monthly:
            return "$4.99"
        case .yearly:
            return "$29.99"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly:
            return "Flexible month-to-month access"
        case .yearly:
            return "Best value for long-term routines"
        }
    }
}

enum CareTapPremiumLoadState: Hashable {
    case loading
    case ready
    case unavailable(message: String)
}

struct CareTapPremiumFeatureState: Identifiable, Hashable {
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

struct CareTapPremiumProductState: Identifiable, Hashable {
    let id: CareTapPremiumPlan
    let productID: String
    let title: String
    let subtitle: String
    let priceText: String
    let billingText: String
    let badgeText: String?
    let savingsText: String?
    let isRecommended: Bool
    let isActivePlan: Bool
}

struct CareTapPremiumSnapshot: Hashable {
    let loadState: CareTapPremiumLoadState
    let isPremiumActive: Bool
    let activePlan: CareTapPremiumPlan?
    let activeProductID: String?
    let expirationDate: Date?
    let renewalDescription: String?
    let products: [CareTapPremiumProductState]

    static let loading = CareTapPremiumSnapshot(
        loadState: .loading,
        isPremiumActive: false,
        activePlan: nil,
        activeProductID: nil,
        expirationDate: nil,
        renewalDescription: nil,
        products: []
    )

    static func unavailable(_ message: String) -> CareTapPremiumSnapshot {
        CareTapPremiumSnapshot(
            loadState: .unavailable(message: message),
            isPremiumActive: false,
            activePlan: nil,
            activeProductID: nil,
            expirationDate: nil,
            renewalDescription: nil,
            products: []
        )
    }

    static func ready(
        isPremiumActive: Bool = false,
        activePlan: CareTapPremiumPlan? = nil,
        renewalDescription: String? = nil
    ) -> CareTapPremiumSnapshot {
        CareTapPremiumSnapshot(
            loadState: .ready,
            isPremiumActive: isPremiumActive,
            activePlan: activePlan,
            activeProductID: activePlan.map {
                switch $0 {
                case .monthly:
                    return "com.maxnguyen.caretap.premium.monthly"
                case .yearly:
                    return "com.maxnguyen.caretap.premium.yearly"
                }
            },
            expirationDate: nil,
            renewalDescription: renewalDescription,
            products: CareTapPremiumPlan.allCases.map { plan in
                let productID: String
                let billingText: String
                switch plan {
                case .monthly:
                    productID = "com.maxnguyen.caretap.premium.monthly"
                    billingText = "Billed every month"
                case .yearly:
                    productID = "com.maxnguyen.caretap.premium.yearly"
                    billingText = "Billed every year"
                }

                return CareTapPremiumProductState(
                    id: plan,
                    productID: productID,
                    title: plan.defaultTitle,
                    subtitle: plan.subtitle,
                    priceText: plan.fallbackPriceText,
                    billingText: billingText,
                    badgeText: activePlan == plan ? "Current" : (plan == .yearly ? "Best Value" : nil),
                    savingsText: plan == .yearly ? "Save 50%" : nil,
                    isRecommended: plan == .yearly,
                    isActivePlan: activePlan == plan
                )
            }
        )
    }
}

enum CareTapPremiumPurchaseOutcome: Hashable {
    case purchased(CareTapPremiumSnapshot)
    case pending(CareTapPremiumSnapshot)
    case cancelled(CareTapPremiumSnapshot)

    var snapshot: CareTapPremiumSnapshot {
        switch self {
        case .purchased(let snapshot),
             .pending(let snapshot),
             .cancelled(let snapshot):
            return snapshot
        }
    }
}

struct CareTapPremiumStatusState: Hashable {
    let isActive: Bool
    let badgeText: String
    let title: String
    let detail: String
    let renewalDetail: String?

    static func from(_ snapshot: CareTapPremiumSnapshot) -> CareTapPremiumStatusState {
        // Every CareTap feature now ships built-in. We keep the type to avoid
        // churn in downstream views, but isActive is always true so gate cards
        // never appear and the full experience is always available.
        CareTapPremiumStatusState(
            isActive: true,
            badgeText: "Included",
            title: "All features included",
            detail: "Insights, refill outlook, and caregiver summaries are built in for everyone.",
            renewalDetail: snapshot.renewalDescription
        )
    }
}

struct CareTapPremiumViewState: Hashable {
    let status: CareTapPremiumStatusState
    let loadState: CareTapPremiumLoadState
    let products: [CareTapPremiumProductState]
    let features: [CareTapPremiumFeatureState]
    let supportText: String
    let disclosureText: String
    let isPurchasing: Bool

    static func from(
        snapshot: CareTapPremiumSnapshot,
        isPurchasing: Bool
    ) -> CareTapPremiumViewState {
        CareTapPremiumViewState(
            status: .from(snapshot),
            loadState: snapshot.loadState,
            products: snapshot.products,
            features: [
                CareTapPremiumFeatureState(
                    symbolName: "chart.line.uptrend.xyaxis",
                    title: "Recent patterns",
                    detail: "See richer history trends, correction context, and confidence breakdowns."
                ),
                CareTapPremiumFeatureState(
                    symbolName: "clock.badge.exclamationmark",
                    title: "Refill outlook",
                    detail: "Keep a smarter eye on supply and which routines need attention first."
                ),
                CareTapPremiumFeatureState(
                    symbolName: "person.2.badge.gearshape.fill",
                    title: "Care circle summaries",
                    detail: "Unlock clearer caregiver summaries without changing the free daily workflow."
                )
            ],
            supportText: "Core logging, reminders, NFC pairing, and basic shared care stay free.",
            disclosureText: "Auto-renewing subscription. Payment is charged to your Apple Account at confirmation. It renews automatically unless canceled at least 24 hours before the end of the current period. Manage and cancel anytime in the App Store subscription settings.",
            isPurchasing: isPurchasing
        )
    }
}
