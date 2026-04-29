import XCTest
@testable import CareTap

final class PhaseTwoStateTests: XCTestCase {
    func testNFCPairingReadyUsesExpectedPrimaryAction() {
        XCTAssertEqual(NFCPairingPhase.ready.primaryActionTitle, "Start Pairing")
        XCTAssertEqual(NFCPairingPhase.ready.badgeText, "Ready")
    }

    func testNFCPairingFailureUsesAlertTone() {
        XCTAssertEqual(NFCPairingPhase.failure.tone, .alert)
        XCTAssertEqual(NFCPairingPhase.failure.secondaryActionTitle, "Back")
    }

    func testNFCPairingSuccessUsesContinueAction() {
        XCTAssertEqual(NFCPairingPhase.success.primaryActionTitle, "Continue")
        XCTAssertEqual(NFCPairingPhase.success.secondaryActionTitle, "Pair Another")
    }

    func testBundledCatalogMatchesSupplementAliasAndDefaults() {
        let catalog = CareTapBundledMedicationCatalog(bundle: Bundle(for: Self.self))

        let suggestion = catalog.suggestions(matching: "creatine monohydrates").first

        XCTAssertEqual(suggestion?.title, "Creatine")
        XCTAssertEqual(suggestion?.category, .supplement)
        XCTAssertEqual(suggestion?.defaultContainerKind, .packet)
    }

    func testBundledCatalogDoesNotShowPresetSuggestionsWhenQueryIsEmpty() {
        let catalog = CareTapBundledMedicationCatalog(bundle: Bundle(for: Self.self))

        let suggestions = catalog.suggestions(matching: "")

        XCTAssertTrue(suggestions.isEmpty)
    }

    func testTapKitShopDefaultStateReflectsCheckoutAvailability() {
        let unavailableState = TapKitShopViewState.default(isCheckoutConfigured: false)
        let availableState = TapKitShopViewState.default(isCheckoutConfigured: true)

        XCTAssertFalse(unavailableState.isCheckoutConfigured)
        XCTAssertEqual(unavailableState.features.count, 4)
        XCTAssertTrue(unavailableState.checkoutNote.contains("connected"))

        XCTAssertTrue(availableState.isCheckoutConfigured)
        XCTAssertTrue(availableState.checkoutNote.contains("Stripe checkout"))
    }

    func testTapKitShopDefaultStateExposesPackCatalogWithRecommendedDefault() {
        let state = TapKitShopViewState.default(isCheckoutConfigured: true)

        XCTAssertEqual(state.packs.count, TapKitPack.catalog.count)
        XCTAssertEqual(state.selectedPackSlug, TapKitPack.recommendedSlug)
        XCTAssertEqual(state.selectedPack.slug, .family)
        XCTAssertEqual(state.selectedPack.priceCents, 2500)
    }

    func testTapKitPackCatalogPricingMatchesRetail() {
        let starter = TapKitPack.pack(for: .starter)
        let family = TapKitPack.pack(for: .family)

        XCTAssertEqual(starter.priceCents, 1499)
        XCTAssertEqual(starter.tagCount, 5)
        XCTAssertEqual(family.priceCents, 2500)
        XCTAssertEqual(family.tagCount, 10)
        XCTAssertEqual(starter.priceText, "$14.99")
        XCTAssertEqual(family.priceText, "$25")
        XCTAssertEqual(TapKitPack.catalog.count, 2)
    }

    func testTapKitOrderResultDeepLinkParsesSuccessAndCancel() {
        let success = CareTapDeepLink(url: URL(string: "caretap://tapkit/success?pack=family")!)
        XCTAssertEqual(success, .tapKitOrderResult(success: true, packSlug: "family"))

        let cancel = CareTapDeepLink(url: URL(string: "caretap://tapkit/cancel")!)
        XCTAssertEqual(cancel, .tapKitOrderResult(success: false, packSlug: nil))
    }

    func testPremiumStatusIsAlwaysActiveBecauseFeaturesAreBuiltIn() {
        let purchased = CareTapPremiumStatusState.from(
            .ready(
                isPremiumActive: true,
                activePlan: .yearly,
                renewalDescription: "Renews May 20"
            )
        )

        XCTAssertTrue(purchased.isActive)
        XCTAssertEqual(purchased.badgeText, "Included")
        XCTAssertEqual(purchased.renewalDetail, "Renews May 20")

        let fresh = CareTapPremiumStatusState.from(.ready())
        XCTAssertTrue(fresh.isActive, "Premium features ship built-in; status should always be active.")
        XCTAssertEqual(fresh.badgeText, "Included")
    }

    func testPremiumViewStateIncludesFallbackPlans() {
        let state = CareTapPremiumViewState.from(
            snapshot: .ready(),
            isPurchasing: false
        )

        XCTAssertEqual(state.products.count, 2)
        XCTAssertEqual(state.products.first?.title, "Monthly")
        XCTAssertEqual(state.products.last?.title, "Yearly")
    }
}
