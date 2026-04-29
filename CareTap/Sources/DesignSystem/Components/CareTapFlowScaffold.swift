import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

                CareTapViewportScrollView(
                    topPadding: 8,
                    bottomPadding: footer == nil ? 48 : 144
                ) {
                    content
                }
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
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
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
                        .frame(width: 40, height: 40)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.04),
                            cornerRadius: 12,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 12, opacity: 0.28)
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
                        tint: CareTapTheme.glassTint.opacity(0.03),
                        cornerRadius: 8
                    )
                    .careTapGlassStroke(cornerRadius: 8, opacity: 0.22)
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

struct CareTapViewportScrollView<Content: View>: View {
    var horizontalPadding: CGFloat = CareTapSpacing.screenPadding
    var topPadding: CGFloat = 0
    var bottomPadding: CGFloat = 0
    private let content: Content

    init(
        horizontalPadding: CGFloat = CareTapSpacing.screenPadding,
        topPadding: CGFloat = 0,
        bottomPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                content
                    .frame(width: contentWidth(for: proxy.size.width), alignment: .topLeading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topPadding)
                    .padding(.bottom, bottomPadding)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func contentWidth(for proposedWidth: CGFloat) -> CGFloat {
        max(0, boundedViewportWidth(for: proposedWidth) - (horizontalPadding * 2))
    }

    private func boundedViewportWidth(for proposedWidth: CGFloat) -> CGFloat {
        #if canImport(UIKit) && !APP_EXTENSION
        let screen = UIScreen.main
        let logicalWidth = screen.nativeBounds.width / max(screen.scale, 1)
        return min(proposedWidth, screen.bounds.width, logicalWidth)
        #else
        return proposedWidth
        #endif
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
                        tint: CareTapTheme.glassTint.opacity(0.03),
                        cornerRadius: CareTapSpacing.cornerRadiusCompact,
                        interactive: true
                    )
                    .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.22)
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
                    RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                        .fill(CareTapTheme.sageStrong)
                        .overlay {
                            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
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
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.24)
    }
}
