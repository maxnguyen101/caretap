import Foundation

/// Resolves Stripe Payment Link URLs for each `TapKitPack` from the app bundle.
///
/// Each pack maps to one Stripe Payment Link configured in the Stripe Dashboard.
/// The Payment Link should be configured with these "after payment" redirect URLs:
///   - Success → `caretap://tapkit/success?pack=<slug>`
///   - Cancel  → handled by Safari's "Done" button (no explicit cancel redirect)
///
/// At runtime we read each price-specific URL from `Info.plist`. If a pack-specific
/// link is missing, we fall back to the legacy `CareTapTapKitCheckoutURL` value so
/// development builds still work while Stripe is being configured.
struct TapKitCheckoutConfiguration {
    private let starterURL: URL?
    private let familyURL: URL?
    private let fallbackURL: URL?

    init(bundle: Bundle = .main) {
        self.starterURL = TapKitCheckoutConfiguration.url(
            forKey: "CareTapTapKitStarterPaymentLink",
            in: bundle
        )
        self.familyURL = TapKitCheckoutConfiguration.url(
            forKey: "CareTapTapKitFamilyPaymentLink",
            in: bundle
        )
        self.fallbackURL = TapKitCheckoutConfiguration.url(
            forKey: "CareTapTapKitCheckoutURL",
            in: bundle
        )
    }

    init(
        starterURL: URL?,
        familyURL: URL?,
        fallbackURL: URL?
    ) {
        self.starterURL = starterURL
        self.familyURL = familyURL
        self.fallbackURL = fallbackURL
    }

    /// Returns the Stripe Payment Link for a pack, falling back to the legacy
    /// generic checkout URL if no pack-specific link is configured.
    func paymentLink(for pack: TapKitPack) -> URL? {
        let configured: URL?
        switch pack.slug {
        case .starter: configured = starterURL
        case .family: configured = familyURL
        }
        return configured ?? fallbackURL
    }

    /// `true` if at least one Stripe Payment Link is wired up (per-pack or fallback).
    var isConfigured: Bool {
        starterURL != nil ||
        familyURL != nil ||
        fallbackURL != nil
    }

    /// `true` if every pack has its own Payment Link (production-grade configuration).
    var isFullyConfigured: Bool {
        starterURL != nil && familyURL != nil
    }

    private static func url(forKey key: String, in bundle: Bundle) -> URL? {
        guard let raw = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
}
