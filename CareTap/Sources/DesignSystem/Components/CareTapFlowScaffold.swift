import SwiftUI

struct CareTapFlowScaffold<Content: View>: View {
    let leadingSystemImage: String?
    let leadingAccessibilityLabel: String
    let trailingBadgeText: String?
    private let leadingAction: () -> Void
    private let content: Content
    private let footer: AnyView?

    init(
        leadingSystemImage: String? = "chevron.left",
        leadingAccessibilityLabel: String = "Back",
        trailingBadgeText: String? = nil,
        leadingAction: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.leadingSystemImage = leadingSystemImage
        self.leadingAccessibilityLabel = leadingAccessibilityLabel
        self.trailingBadgeText = trailingBadgeText
        self.leadingAction = leadingAction
        self.content = content()
        self.footer = nil
    }

    init<Footer: View>(
        leadingSystemImage: String? = "chevron.left",
        leadingAccessibilityLabel: String = "Back",
        trailingBadgeText: String? = nil,
        leadingAction: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.leadingSystemImage = leadingSystemImage
        self.leadingAccessibilityLabel = leadingAccessibilityLabel
        self.trailingBadgeText = trailingBadgeText
        self.leadingAction = leadingAction
        self.content = content()
        self.footer = AnyView(footer())
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                if leadingSystemImage != nil || trailingBadgeText != nil {
                    header
                }

                ScrollView(.vertical) {
                    content
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, CareTapSpacing.screenPadding)
                        .padding(.top, 8)
                        .padding(.bottom, footer == nil ? 48 : 144)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let footer {
                footer
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            if let leadingSystemImage {
                Button {
                    CareTapInteraction.dismissKeyboard()
                    leadingAction()
                } label: {
                    Image(systemName: leadingSystemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.06),
                            cornerRadius: 22,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 22, opacity: 0.3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(leadingAccessibilityLabel)
            }

            Spacer()

            if let trailingBadgeText, !trailingBadgeText.isEmpty {
                Text(trailingBadgeText)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .careTapLiquidGlass(
                        tint: CareTapTheme.glassTint.opacity(0.04),
                        cornerRadius: 12
                    )
                    .careTapGlassStroke(cornerRadius: 12, opacity: 0.25)
            }
        }
        .padding(.horizontal, CareTapSpacing.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var backgroundLayer: some View {
        CareTapScreenBackground()
    }
}

struct CareTapFooterActionBar: View {
    let secondaryTitle: String
    let primaryTitle: String
    var primarySystemImage: String? = nil
    var isPrimaryEnabled: Bool = true
    var secondaryAction: () -> Void = {}
    var primaryAction: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            Button {
                CareTapHaptics.tap()
                CareTapInteraction.dismissKeyboard()
                secondaryAction()
            } label: {
                Text(secondaryTitle)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                    .careTapLiquidGlass(
                        tint: CareTapTheme.glassTint.opacity(0.04),
                        cornerRadius: 16,
                        interactive: true
                    )
                    .careTapGlassStroke(cornerRadius: 16, opacity: 0.22)
            }
            .buttonStyle(CareTapPressableButtonStyle())
            .accessibilityLabel(secondaryTitle)

            Button {
                CareTapHaptics.confirm()
                CareTapInteraction.dismissKeyboard()
                primaryAction()
            } label: {
                HStack(spacing: 8) {
                    Text(primaryTitle)
                        .font(CareTapTypography.bodyStrong)
                    if let primarySystemImage {
                        Image(systemName: primarySystemImage)
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
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
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(CareTapPressableButtonStyle())
            .disabled(!isPrimaryEnabled)
            .opacity(isPrimaryEnabled ? 1 : 0.5)
            .accessibilityLabel(primaryTitle)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.06), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
        .shadow(color: CareTapTheme.shadow.opacity(0.14), radius: 12, x: 0, y: 4)
    }
}
