import SwiftUI

struct TapKitShopView: View {
    let state: TapKitShopViewState
    var onClose: () -> Void = {}
    var onSelectPack: (TapKitPack.Slug) -> Void = { _ in }
    var onCheckout: () -> Void = {}
    var onContactSupport: () -> Void = {}
    var onDismissConfirmation: () -> Void = {}

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            CareTapFlowScaffold(
                leadingSystemImage: "xmark",
                leadingAccessibilityLabel: "Close shop",
                trailingBadgeText: state.badgeText,
                leadingAction: onClose
            ) {
                VStack(alignment: .leading, spacing: 22) {
                    heroSection
                    trustStrip
                    packSelectorSection
                    featuresSection
                    founderNoteCard
                    detailsSection
                }
            } footer: {
                stickyCTA
            }

            if let confirmation = state.confirmation {
                TapKitOrderConfirmationOverlay(
                    state: confirmation,
                    onClose: onDismissConfirmation
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(2)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.18), value: state.confirmation)
    }

    // MARK: Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            heroVisual

            VStack(alignment: .leading, spacing: 8) {
                Text(state.title)
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(state.subtitle)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var heroVisual: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CareTapTheme.sage.opacity(0.22),
                    CareTapTheme.sageStrong.opacity(0.14),
                    CareTapTheme.canvasMist.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Circle()
                .fill(CareTapTheme.sage.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: -110, y: 80)

            Circle()
                .fill(CareTapTheme.warm.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 38)
                .offset(x: 130, y: -70)

            HStack(spacing: 18) {
                bottleIllustration
                tagIllustration
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 28)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .careTapGlassStroke(cornerRadius: 28, opacity: 0.22)
    }

    private var bottleIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.55))
                .frame(width: 100, height: 144)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: CareTapTheme.shadow.opacity(0.4), radius: 18, x: 0, y: 10)

            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(CareTapTheme.sageStrong.opacity(0.25))
                    .frame(width: 50, height: 18)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(CareTapTheme.sageStrong.opacity(0.15))
                    .frame(width: 60, height: 6)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(CareTapTheme.sageStrong.opacity(0.12))
                    .frame(width: 44, height: 6)
            }

            Image(systemName: "tag.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CareTapTheme.warm)
                .padding(10)
                .background(.white.opacity(0.85), in: Circle())
                .shadow(color: CareTapTheme.shadow.opacity(0.35), radius: 8, x: 0, y: 4)
                .offset(x: 36, y: 44)
        }
    }

    private var tagIllustration: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CareTapTheme.sageStrong)
                .padding(12)
                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))

            Text("Tap once.\nLogged.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CareTapTheme.textPrimary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Trust Strip

    private var trustStrip: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                trustBadge(icon: "shippingbox.and.arrow.backward.fill", text: TapKitShippingPolicy.freeShippingText)
                trustBadge(icon: "arrow.uturn.backward.circle.fill", text: TapKitShippingPolicy.returnsText)
            }
            HStack(spacing: 8) {
                trustBadge(icon: "lock.shield.fill", text: TapKitShippingPolicy.secureCheckoutText)
                trustBadge(icon: "bolt.fill", text: TapKitShippingPolicy.worksInstantlyText)
            }
        }
    }

    private func trustBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CareTapTheme.sageStrong)

            Text(text)
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 12)
        .careTapGlassStroke(cornerRadius: 12, opacity: 0.18)
    }

    // MARK: Pack Selector

    private var packSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                CareTapSectionLabel("Pick a pack")
                Spacer()
                Text("All packs ship from the U.S.")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
            }

            VStack(spacing: 10) {
                ForEach(state.packs) { pack in
                    TapKitPackCard(
                        pack: pack,
                        isSelected: pack.slug == state.selectedPackSlug,
                        onTap: { onSelectPack(pack.slug) }
                    )
                }
            }
        }
    }

    // MARK: Features

    private var featuresSection: some View {
        CareTapGlassSection(title: "Why TapKit") {
            VStack(spacing: 12) {
                ForEach(state.features) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: feature.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CareTapTheme.sageStrong)
                            .frame(width: 30, height: 30)
                            .background(CareTapTheme.sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

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

    // MARK: Founder Note

    private var founderNoteCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CareTapTheme.sageStrong, CareTapTheme.warm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("M")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("A note from the founder")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .tracking(0.4)

                Text(state.founderNote)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .careTapLiquidGlass(tint: CareTapTheme.warm.opacity(0.05), cornerRadius: 20)
        .careTapGlassStroke(cornerRadius: 20, opacity: 0.22)
    }

    // MARK: Details

    private var detailsSection: some View {
        CareTapGlassSection(title: "How it fits") {
            VStack(spacing: 10) {
                workflowRow(step: "1", title: "Pair once", detail: "Set up each sticker in CareTap during the tap setup step.")
                workflowRow(step: "2", title: "Place it where it helps", detail: "Bottles, organizers, trays, packets — wherever the routine already lives.")
                workflowRow(step: "3", title: "Tap to log", detail: "The same physical tap becomes the easiest way to stay on track.")
            }
        }
    }

    private func workflowRow(step: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(CareTapTypography.footnote.weight(.bold))
                .foregroundStyle(CareTapTheme.sageStrong)
                .frame(width: 26, height: 26)
                .background(CareTapTheme.sage.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer()
        }
    }

    // MARK: Sticky CTA

    private var stickyCTA: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(action: onContactSupport) {
                    Text(state.secondaryActionTitle)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .frame(minWidth: 88, minHeight: 56)
                        .padding(.horizontal, 14)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.04),
                            cornerRadius: 16,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 16, opacity: 0.22)
                }
                .buttonStyle(.plain)

                Button {
                    CareTapHaptics.confirm()
                    onCheckout()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Buy \(state.selectedPack.title)")
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(.white)
                            Text("\(state.selectedPack.priceText) • Apple Pay or card")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [CareTapTheme.sageStrong, CareTapTheme.sage],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                            .shadow(color: CareTapTheme.sageStrong.opacity(0.28), radius: 14, x: 0, y: 6)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!state.isCheckoutConfigured)
                .opacity(state.isCheckoutConfigured ? 1 : 0.55)
            }

            Text(state.checkoutNote)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.06), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
        .shadow(color: CareTapTheme.shadow.opacity(0.16), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Pack Card

private struct TapKitPackCard: View {
    let pack: TapKitPack
    let isSelected: Bool
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                radio
                detail
                pricing
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 1.6 : 1)
            }
            .shadow(
                color: isSelected ? CareTapTheme.sageStrong.opacity(0.16) : CareTapTheme.shadow.opacity(0.08),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .animation(.spring(duration: 0.32, bounce: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pack.title), \(pack.subtitle), \(pack.priceText)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var radio: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? CareTapTheme.sageStrong : CareTapTheme.stroke, lineWidth: isSelected ? 2 : 1)
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(CareTapTheme.sageStrong)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.top, 2)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(pack.title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)

                if let highlight = pack.highlightText {
                    Text(highlight)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(highlightTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(highlightBackgroundColor, in: Capsule())
                }
            }

            Text(pack.subtitle)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)

            Text(pack.summary)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(CareTapTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pricing: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(pack.priceText)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(CareTapTheme.textPrimary)

            Text(pack.perTagPriceText)
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
        }
    }

    private var backgroundFill: Color {
        isSelected
            ? CareTapTheme.sage.opacity(0.07)
            : CareTapTheme.surface.opacity(0.92)
    }

    private var borderColor: Color {
        isSelected
            ? CareTapTheme.sageStrong.opacity(0.55)
            : CareTapTheme.stroke.opacity(0.7)
    }

    private var highlightTextColor: Color {
        switch pack.highlight {
        case .none: return CareTapTheme.textTertiary
        case .mostPopular: return CareTapTheme.sageStrong
        }
    }

    private var highlightBackgroundColor: Color {
        switch pack.highlight {
        case .none: return CareTapTheme.stroke.opacity(0.4)
        case .mostPopular: return CareTapTheme.sage.opacity(0.18)
        }
    }
}

// MARK: - Confirmation Overlay

private struct TapKitOrderConfirmationOverlay: View {
    let state: TapKitOrderConfirmationState
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            CareTapTheme.canvas.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                successCheck

                VStack(spacing: 8) {
                    Text("Order confirmed")
                        .font(CareTapTypography.hero)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Text("Your \(state.pack.title.lowercased()) is on the way. Check your email for a Stripe receipt and tracking once it ships.")
                        .font(CareTapTypography.callout)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 18)
                }

                receiptCard

                Button {
                    CareTapHaptics.tap()
                    onClose()
                } label: {
                    Text("Back to CareTap")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [CareTapTheme.sageStrong, CareTapTheme.sage],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .frame(maxWidth: 420)
            .padding(.horizontal, 20)
        }
    }

    private var successCheck: some View {
        ZStack {
            Circle()
                .fill(CareTapTheme.success.opacity(0.12))
                .frame(width: 110, height: 110)

            Circle()
                .stroke(CareTapTheme.success.opacity(0.35), lineWidth: 1.5)
                .frame(width: 130, height: 130)

            Image(systemName: "checkmark")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(CareTapTheme.success)
                .symbolEffect(.bounce, options: .nonRepeating)
        }
    }

    private var receiptCard: some View {
        VStack(spacing: 12) {
            receiptRow(label: "Pack", value: state.pack.title)
            Divider().background(CareTapTheme.separator.opacity(0.6))
            receiptRow(label: "Tags", value: "\(state.pack.tagCount)")
            Divider().background(CareTapTheme.separator.opacity(0.6))
            receiptRow(label: "Total", value: state.pack.priceText)
            Divider().background(CareTapTheme.separator.opacity(0.6))
            receiptRow(label: "Confirmed", value: state.confirmedAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.06), cornerRadius: 20)
        .careTapGlassStroke(cornerRadius: 20, opacity: 0.28)
    }

    private func receiptRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
            Spacer()
            Text(value)
                .font(CareTapTypography.bodyStrong)
                .foregroundStyle(CareTapTheme.textPrimary)
        }
    }
}

#Preview("Shop · Default") {
    TapKitShopView(state: .default(isCheckoutConfigured: true))
}

#Preview("Shop · Confirmed") {
    TapKitShopView(
        state: .default(
            isCheckoutConfigured: true,
            confirmation: TapKitOrderConfirmationState(
                pack: TapKitPack.pack(for: .family),
                confirmedAt: .now
            )
        )
    )
}
