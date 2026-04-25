import Foundation

/// A TapKit pack the user can buy. Each pack maps to a Stripe Price ID
/// that is configured at build time via `Info.plist`. Pricing reflects the
/// current TapCare retail catalog and is shown to the user in the shop.
struct TapKitPack: Identifiable, Hashable {
    enum Slug: String, CaseIterable, Identifiable, Hashable {
        case starter
        case family

        var id: String { rawValue }

        /// Info.plist key that holds the Stripe Price ID for this pack.
        var priceIDPlistKey: String {
            switch self {
            case .starter: return "CareTapTapKitStarterPriceID"
            case .family: return "CareTapTapKitFamilyPriceID"
            }
        }
    }

    enum Highlight: Hashable {
        case none
        case mostPopular
    }

    let id: UUID
    let slug: Slug
    let title: String
    let subtitle: String
    let tagCount: Int
    let priceCents: Int
    let highlight: Highlight
    let summary: String
    let perks: [String]

    init(
        id: UUID = UUID(),
        slug: Slug,
        title: String,
        subtitle: String,
        tagCount: Int,
        priceCents: Int,
        highlight: Highlight,
        summary: String,
        perks: [String]
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.subtitle = subtitle
        self.tagCount = tagCount
        self.priceCents = priceCents
        self.highlight = highlight
        self.summary = summary
        self.perks = perks
    }

    /// Formatted price like "$24.99".
    var priceText: String {
        TapKitPack.formattedPrice(cents: priceCents)
    }

    /// Per-tag price like "$2.50 / tag".
    var perTagPriceText: String {
        guard tagCount > 0 else { return priceText }
        let perTag = Double(priceCents) / Double(tagCount) / 100.0
        return String(format: "$%.2f / tag", perTag)
    }

    var highlightText: String? {
        switch highlight {
        case .none: return nil
        case .mostPopular: return "Most Popular"
        }
    }

    static func formattedPrice(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        if cents % 100 == 0 {
            return String(format: "$%.0f", dollars)
        } else {
            return String(format: "$%.2f", dollars)
        }
    }
}

extension TapKitPack {
    /// The retail TapKit catalog. Order is meaningful (shown top-to-bottom in the shop).
    static let catalog: [TapKitPack] = [
        TapKitPack(
            slug: .starter,
            title: "Starter Pack",
            subtitle: "5 NFC tags",
            tagCount: 5,
            priceCents: 1499,
            highlight: .none,
            summary: "Perfect for one routine — bottle, organizer, or tray.",
            perks: ["5 CareTap-ready stickers", "Pre-printed setup card", "Replacement-friendly"]
        ),
        TapKitPack(
            slug: .family,
            title: "Family Pack",
            subtitle: "10 NFC tags",
            tagCount: 10,
            priceCents: 2500,
            highlight: .mostPopular,
            summary: "Ideal for a typical week of vitamins, meds, and refills.",
            perks: ["10 CareTap-ready stickers", "Best per-tag price", "Free US shipping"]
        ),
    ]

    static let recommendedSlug: Slug = .family

    static func pack(for slug: Slug) -> TapKitPack {
        catalog.first(where: { $0.slug == slug }) ?? catalog[1]
    }
}

/// Shipping policy copy displayed alongside the catalog.
enum TapKitShippingPolicy {
    static let freeShippingThresholdCents: Int = 2500
    static let freeShippingText: String = "Free US shipping on orders $25+"
    static let returnsText: String = "30-day returns"
    static let secureCheckoutText: String = "Secure Stripe checkout"
    static let worksInstantlyText: String = "Works instantly with iPhone"
}
