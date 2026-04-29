import SwiftUI

struct CareTapPremiumView: View {
    let state: CareTapPremiumViewState
    var onClose: () -> Void = {}
    var onPurchase: (CareTapPremiumPlan) -> Void = { _ in }
    var onRestore: () -> Void = {}

    @Environment(\.openURL) private var openURL
    @State private var selectedPlan: CareTapPremiumPlan = .yearly

    var body: some View {
        CareTapFlowScaffold(
            leadingSystemImage: "xmark",
            leadingAccessibilityLabel: "Close premium",
            trailingBadgeText: state.status.badgeText,
            leadingAction: onClose
        ) {
            VStack(alignment: .leading, spacing: 24) {
                heroCard

                if case .unavailable(let message) = state.loadState {
                    statusCard(
                        tone: .warm,
                        symbolName: "wifi.exclamationmark",
                        title: "Premium is unavailable right now",
                        detail: message
                    )
                } else {
                    plansSection
                }

                featuresSection
                supportSection
                CareTapLegalLinksFooter()
            }
        } footer: {
            CareTapFooterActionBar(
                secondaryTitle: "Restore",
                primaryTitle: primaryActionTitle,
                primarySystemImage: state.status.isActive ? "arrow.up.right" : "sparkles",
                isPrimaryEnabled: isPrimaryEnabled,
                secondaryAction: onRestore,
                primaryAction: handlePrimaryAction
            )
        }
        .onAppear {
            selectedPlan = preferredPlan
        }
        .onChange(of: state.products) { _, _ in
            selectedPlan = preferredPlan
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("PremiumHeroArt")
                .resizable()
                .scaledToFill()
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(state.status.title)
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(state.status.detail)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    heroPill(icon: "checkmark.circle.fill", text: "Core care stays free")
                    heroPill(icon: "arrow.clockwise", text: "Cancel anytime")
                    heroPill(icon: "apple.logo", text: "App Store billing")
                }

                VStack(alignment: .leading, spacing: 8) {
                    heroPill(icon: "checkmark.circle.fill", text: "Core care stays free")
                    heroPill(icon: "arrow.clockwise", text: "Cancel anytime")
                    heroPill(icon: "apple.logo", text: "App Store billing")
                }
            }

            if let renewalDetail = state.status.renewalDetail {
                statusCard(
                    tone: .sage,
                    symbolName: "arrow.clockwise.circle.fill",
                    title: "Subscription status",
                    detail: renewalDetail
                )
            } else {
                statusCard(
                    tone: .neutral,
                    symbolName: "checkmark.circle.fill",
                    title: "Always included",
                    detail: state.supportText
                )
            }
        }
        .padding(18)
        .careTapGlassFill(opacity: 0.58)
        .careTapLiquidGlass(tint: heroTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.24)
    }

    private var plansSection: some View {
        CareTapGlassSection(title: state.status.isActive ? "Other plans" : "Choose a plan") {
            VStack(spacing: 12) {
                ForEach(state.products) { product in
                    premiumPlanCard(product)
                }
            }
        }
    }

    private func premiumPlanCard(_ product: CareTapPremiumProductState) -> some View {
        Button {
            selectedPlan = product.id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(product.title)
                            .font(CareTapTypography.bodyStrong)
                            .foregroundStyle(CareTapTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let badgeText = product.badgeText {
                            premiumBadge(text: badgeText, tone: product.isActivePlan ? .sage : .warm)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(product.subtitle)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(product.billingText)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let savingsText = product.savingsText {
                        Text(savingsText)
                            .font(CareTapTypography.footnote.weight(.semibold))
                            .foregroundStyle(CareTapTheme.sageStrong)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(product.priceText)
                        .font(CareTapTypography.section)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Image(systemName: isSelected(product) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected(product) ? CareTapTheme.sageStrong : CareTapTheme.textTertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapLiquidGlass(
                tint: isSelected(product)
                    ? CareTapTheme.sage.opacity(0.05)
                    : CareTapTheme.glassTint.opacity(0.025),
                cornerRadius: CareTapSpacing.cornerRadiusCompact,
                interactive: true
            )
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: isSelected(product) ? 0.3 : 0.2)
        }
        .buttonStyle(.plain)
        .disabled(state.status.isActive && product.isActivePlan)
    }

    private var featuresSection: some View {
        CareTapGlassSection(title: "Unlock with premium") {
            VStack(spacing: 12) {
                ForEach(state.features) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: feature.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CareTapTheme.sageStrong)
                            .frame(width: 28, height: 28)
                            .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(feature.detail)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .layoutPriority(1)

                        Spacer()
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        CareTapGlassSection(title: "Billing") {
            VStack(alignment: .leading, spacing: 10) {
                detailRow(
                    icon: "checkmark.circle.fill",
                    text: state.supportText
                )
                detailRow(
                    icon: "arrow.clockwise",
                    text: state.disclosureText
                )

                Button("Manage in App Store") {
                    openManageSubscriptions()
                }
                .buttonStyle(.plain)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.sageStrong)
            }
        }
    }

    private func heroPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))

            Text(text)
                .font(CareTapTypography.footnote.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(CareTapTheme.sageStrong)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.04), cornerRadius: 10)
        .careTapGlassStroke(cornerRadius: 10, opacity: 0.18)
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 20)

            Text(text)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statusCard(
        tone: CareTapTone,
        symbolName: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tone.color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: tone.color.opacity(0.035), cornerRadius: CareTapSpacing.cornerRadiusCompact)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.18)
    }

    private func premiumBadge(text: String, tone: CareTapTone) -> some View {
        Text(text)
            .font(CareTapTypography.micro.weight(.semibold))
            .foregroundStyle(tone == .sage ? CareTapTheme.sageStrong : tone.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (tone == .sage ? CareTapTheme.sage : tone.color).opacity(0.1),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }

    private func isSelected(_ product: CareTapPremiumProductState) -> Bool {
        if state.status.isActive && product.isActivePlan {
            return true
        }
        return selectedPlan == product.id
    }

    private var preferredPlan: CareTapPremiumPlan {
        state.products.first(where: \.isActivePlan)?.id
            ?? state.products.first(where: \.isRecommended)?.id
            ?? state.products.first?.id
            ?? .yearly
    }

    private var selectedProduct: CareTapPremiumProductState? {
        state.products.first(where: { $0.id == selectedPlan })
            ?? state.products.first(where: \.isRecommended)
            ?? state.products.first
    }

    private var primaryActionTitle: String {
        if state.isPurchasing {
            return "Working"
        }

        if state.status.isActive {
            return "Manage"
        }

        return selectedProduct.map { "Start \($0.title)" } ?? "Start Premium"
    }

    private var isPrimaryEnabled: Bool {
        if state.isPurchasing {
            return false
        }

        if state.status.isActive {
            return true
        }

        guard case .ready = state.loadState else {
            return false
        }

        return selectedProduct != nil
    }

    private var heroTint: Color {
        state.status.isActive ? CareTapTheme.sageStrong : CareTapTheme.warm
    }

    private func handlePrimaryAction() {
        if state.status.isActive {
            openManageSubscriptions()
            return
        }

        guard let selectedProduct else { return }
        onPurchase(selectedProduct.id)
    }

    private func openManageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        openURL(url)
    }
}

#Preview {
    CareTapPremiumView(
        state: .from(snapshot: .ready(), isPurchasing: false)
    )
}
