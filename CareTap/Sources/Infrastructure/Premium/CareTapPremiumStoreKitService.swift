import Foundation
import StoreKit

private enum CareTapPremiumStoreError: LocalizedError {
    case missingProductConfiguration
    case productsUnavailable
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .missingProductConfiguration:
            return "TapCare Premium products are not configured for this build yet."
        case .productsUnavailable:
            return "TapCare Premium plans are not available right now. Try again in a moment."
        case .verificationFailed:
            return "The App Store could not verify that purchase."
        }
    }
}

actor CareTapPremiumStoreKitService: PremiumSubscriptionServicing {
    private struct Configuration {
        let monthlyProductID: String
        let yearlyProductID: String

        var productIDs: [String] {
            [monthlyProductID, yearlyProductID]
        }

        func plan(for productID: String) -> CareTapPremiumPlan? {
            switch productID {
            case monthlyProductID:
                return .monthly
            case yearlyProductID:
                return .yearly
            default:
                return nil
            }
        }

        static func load(bundle: Bundle = .main) -> Configuration? {
            let defaultMonthly = "com.maxnguyen.caretap.premium.monthly"
            let defaultYearly = "com.maxnguyen.caretap.premium.yearly"

            let monthly = (bundle.object(forInfoDictionaryKey: "CareTapPremiumMonthlyProductID") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let yearly = (bundle.object(forInfoDictionaryKey: "CareTapPremiumYearlyProductID") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let monthlyProductID = monthly?.isEmpty == false ? monthly! : defaultMonthly
            let yearlyProductID = yearly?.isEmpty == false ? yearly! : defaultYearly

            guard !monthlyProductID.isEmpty, !yearlyProductID.isEmpty else {
                return nil
            }

            return Configuration(
                monthlyProductID: monthlyProductID,
                yearlyProductID: yearlyProductID
            )
        }
    }

    private let configuration: Configuration?
    private var updatesTask: Task<Void, Never>?
    private var cachedProducts: [String: Product] = [:]

    init(bundle: Bundle = .main) {
        configuration = Configuration.load(bundle: bundle)
    }

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
        _ = await snapshot()
    }

    func snapshot() async -> CareTapPremiumSnapshot {
        guard let configuration else {
            return .unavailable(CareTapPremiumStoreError.missingProductConfiguration.localizedDescription)
        }

        let products = await loadProducts(using: configuration)
        if products.isEmpty {
            return .unavailable(CareTapPremiumStoreError.productsUnavailable.localizedDescription)
        }

        var activePlan: CareTapPremiumPlan?
        var activeProductID: String?
        var expirationDate: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded else {
                continue
            }

            if let expiry = transaction.expirationDate, expiry < .now {
                continue
            }

            guard let plan = configuration.plan(for: transaction.productID) else {
                continue
            }

            if expirationDate == nil || (transaction.expirationDate ?? .distantFuture) > (expirationDate ?? .distantPast) {
                activePlan = plan
                activeProductID = transaction.productID
                expirationDate = transaction.expirationDate
            }
        }

        return CareTapPremiumSnapshot(
            loadState: .ready,
            isPremiumActive: activePlan != nil,
            activePlan: activePlan,
            activeProductID: activeProductID,
            expirationDate: expirationDate,
            renewalDescription: expirationDate.map {
                "Renews \(Self.subscriptionDateFormatter.string(from: $0))"
            },
            products: productStates(
                from: products,
                activePlan: activePlan,
                configuration: configuration
            )
        )
    }

    func purchase(plan: CareTapPremiumPlan) async throws -> CareTapPremiumPurchaseOutcome {
        guard let configuration else {
            throw CareTapPremiumStoreError.missingProductConfiguration
        }

        let products = await loadProducts(using: configuration)
        guard let product = product(for: plan, configuration: configuration, products: products) else {
            throw CareTapPremiumStoreError.productsUnavailable
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try verifiedTransaction(from: verification)
            await transaction.finish()
            return .purchased(await snapshot())
        case .pending:
            return .pending(await snapshot())
        case .userCancelled:
            return .cancelled(await snapshot())
        @unknown default:
            return .cancelled(await snapshot())
        }
    }

    func restorePurchases() async throws -> CareTapPremiumSnapshot {
        try await StoreKit.AppStore.sync()
        return await snapshot()
    }

    private func loadProducts(using configuration: Configuration) async -> [Product] {
        if cachedProducts.count == configuration.productIDs.count {
            return configuration.productIDs.compactMap { cachedProducts[$0] }
        }

        do {
            let products = try await Product.products(for: configuration.productIDs)
            cachedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            return configuration.productIDs.compactMap { cachedProducts[$0] }
        } catch {
            return []
        }
    }

    private func product(
        for plan: CareTapPremiumPlan,
        configuration: Configuration,
        products: [Product]
    ) -> Product? {
        let productID = switch plan {
        case .monthly: configuration.monthlyProductID
        case .yearly: configuration.yearlyProductID
        }

        return products.first(where: { $0.id == productID })
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
    }

    private func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw CareTapPremiumStoreError.verificationFailed
        }
    }

    private func productStates(
        from products: [Product],
        activePlan: CareTapPremiumPlan?,
        configuration: Configuration
    ) -> [CareTapPremiumProductState] {
        let monthlyPrice = products.first(where: { $0.id == configuration.monthlyProductID })?.price

        return CareTapPremiumPlan.allCases.compactMap { plan in
            guard let product = product(for: plan, configuration: configuration, products: products) else {
                return nil
            }

            let billingText = product.subscription.map { subscription in
                Self.billingText(for: subscription.subscriptionPeriod)
            } ?? plan.subtitle

            let savingsText: String? = {
                guard plan == .yearly,
                      let yearlyPrice = products.first(where: { $0.id == configuration.yearlyProductID })?.price,
                      let monthlyPrice else {
                    return nil
                }

                let yearlyAsMonthly = NSDecimalNumber(decimal: monthlyPrice).multiplying(by: 12)
                let yearlyNumber = NSDecimalNumber(decimal: yearlyPrice)
                guard yearlyAsMonthly.compare(yearlyNumber) == .orderedDescending else {
                    return nil
                }

                let discount = yearlyAsMonthly.subtracting(yearlyNumber)
                let percent = Int(
                    ((discount.doubleValue / yearlyAsMonthly.doubleValue) * 100).rounded()
                )
                return percent > 0 ? "Save \(percent)%" : nil
            }()

            return CareTapPremiumProductState(
                id: plan,
                productID: product.id,
                title: product.displayName.isEmpty ? plan.defaultTitle : product.displayName,
                subtitle: plan.subtitle,
                priceText: product.displayPrice,
                billingText: billingText,
                badgeText: activePlan == plan ? "Current" : (plan == .yearly ? "Best Value" : nil),
                savingsText: savingsText,
                isRecommended: plan == .yearly,
                isActivePlan: activePlan == plan
            )
        }
    }

    private static func billingText(for period: Product.SubscriptionPeriod) -> String {
        let unitText: String = switch period.unit {
        case .day: period.value == 1 ? "day" : "days"
        case .week: period.value == 1 ? "week" : "weeks"
        case .month: period.value == 1 ? "month" : "months"
        case .year: period.value == 1 ? "year" : "years"
        @unknown default: "period"
        }

        return "Billed every \(period.value) \(unitText)"
    }

    private static let subscriptionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
