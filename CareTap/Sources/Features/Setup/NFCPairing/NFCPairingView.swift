import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NFCPairingView: View {
    let state: NFCPairingViewState
    var onBack: () -> Void = {}
    var onOpenTapKitShop: () -> Void = {}
    var onSecondaryAction: () -> Void = {}
    var onPrimaryAction: () -> Void = {}

    @State private var showAutomationWizard = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        CareTapFlowScaffold(
            leadingAction: onBack
        ) {
            VStack(spacing: 0) {
                if state.stepText.hasPrefix("Step") {
                    CareTapSetupProgressHeader(stepText: state.stepText)
                        .padding(.bottom, 20)
                }

                phaseContent
            }
        } footer: {
            footerActions
        }
    }

    // MARK: - Phase Router

    @ViewBuilder
    private var phaseContent: some View {
        switch state.phase {
        case .ready:
            readyPhase
        case .writing:
            writingPhase
        case .success:
            successPhase
        case .failure:
            failurePhase
        }
    }

    // MARK: - Ready

    private var readyPhase: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                pairingVisual

                VStack(spacing: 8) {
                    Text("Tap the tag to pair")
                        .font(CareTapTypography.hero)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Hold the top of your iPhone near the NFC sticker on the container.")
                        .font(CareTapTypography.callout)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            medicationRow

            tapKitCard

            VStack(spacing: 8) {
                tipRow(icon: "iphone.radiowaves.left.and.right", text: "Keep the screen unlocked")
                tipRow(icon: "hand.raised.fill", text: "Hold steady until it finishes")
            }
        }
    }

    // MARK: - Writing

    private var writingPhase: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(CareTapTheme.warm.opacity(0.06))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: pulseScale
                        )

                    ProgressView()
                        .tint(CareTapTheme.warm)
                        .scaleEffect(1.4)
                }
                .onAppear { pulseScale = 1.15 }

                VStack(spacing: 8) {
                    Text("Hold steady\u{2026}")
                        .font(CareTapTypography.hero)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Text("Writing to the tag. Keep the container close.")
                        .font(CareTapTypography.callout)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            medicationRow
        }
    }

    // MARK: - Success

    private var successPhase: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CareTapTheme.success.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(CareTapTheme.success)
                }

                VStack(spacing: 8) {
                    Text("Tag paired")
                        .font(CareTapTypography.hero)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Text("This tag is ready for future check-ins.")
                        .font(CareTapTypography.callout)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            medicationRow

            tapKitCard

            if state.automationURL != nil {
                automationUpsellButton
            }
        }
        .sheet(isPresented: $showAutomationWizard) {
            AutomationSetupWizardView(
                automationURL: state.automationURL,
                onDismiss: { showAutomationWizard = false }
            )
            .interactiveDismissDisabled(false)
        }
    }

    // MARK: - Failure

    private var failurePhase: some View {
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(CareTapTheme.alert.opacity(0.08))
                        .frame(width: 100, height: 100)

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(CareTapTheme.alert)
                }

                VStack(spacing: 8) {
                    Text("Pairing didn't finish")
                        .font(CareTapTypography.hero)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Text("The tag wasn’t writable or moved too soon.")
                        .font(CareTapTypography.callout)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            tapKitCard

            VStack(spacing: 8) {
                tipRow(icon: "tag.fill", text: "Some stickers are read-only")
                tipRow(icon: "rectangle.slash", text: "Metal surfaces can block the signal")
                tipRow(icon: "arrow.clockwise", text: "Try a different sticker if needed")
            }
        }
    }

    // MARK: - Shared Components

    private var pairingVisual: some View {
        ZStack {
            Circle()
                .stroke(CareTapTheme.sage.opacity(0.08), lineWidth: 1)
                .frame(width: 160, height: 160)

            Circle()
                .fill(CareTapTheme.sage.opacity(0.06))
                .frame(width: 120, height: 120)

            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(CareTapTheme.sageStrong)
                .symbolEffect(.pulse.byLayer, options: .repeating)
        }
    }

    private var medicationRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "pill.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CareTapTheme.sageStrong)
                .frame(width: 36, height: 36)
                .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(state.medicationName)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(state.bottleLabel)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer()

            if state.phase == .success {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CareTapTheme.success)
            }
        }
        .padding(14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.2)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 28)

            Text(text)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
    }

    private var tapKitCard: some View {
        Button {
            CareTapHaptics.tap()
            onOpenTapKitShop()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(tapKitTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("TapKit")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.18), in: Capsule())
                        }

                        Text(tapKitSubtitle)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer()
                }

                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("From $14.99")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.16), in: Capsule())

                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Free U.S. shipping on orders $25+")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.88))

                    Spacer()
                }

                HStack(spacing: 8) {
                    Text("Order your TapKit")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.sageStrong)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CareTapTheme.sageStrong)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 4)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                CareTapTheme.sageStrong,
                                CareTapTheme.sage,
                                CareTapTheme.sage.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .shadow(color: CareTapTheme.sageStrong.opacity(0.28), radius: 16, x: 0, y: 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Order your TapKit. \(tapKitSubtitle)")
    }

    private var tapKitTitle: String {
        switch state.phase {
        case .success: return "Stock up on TapKit"
        case .failure: return "Try a fresh TapKit"
        case .ready, .writing: return "Don’t have NFC tags yet?"
        }
    }

    private var tapKitSubtitle: String {
        switch state.phase {
        case .success:
            return "Spare CareTap-ready stickers for other containers and people."
        case .failure:
            return "A fresh TapKit is often the fastest fix when a sticker won’t write."
        case .ready, .writing:
            return "Pre-tested NFC stickers shipped from the U.S. — pair right inside CareTap."
        }
    }

    // MARK: - Automation

    private var automationUpsellButton: some View {
        Button {
            showAutomationWizard = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .frame(width: 32, height: 32)
                    .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up instant logging")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Use Apple automation for fewer steps")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(CareTapTheme.sageStrong.opacity(0.7))
            }
            .padding(14)
            .careTapLiquidGlass(
                tint: CareTapTheme.sage.opacity(0.04),
                cornerRadius: 18
            )
            .careTapGlassStroke(cornerRadius: 18, opacity: 0.2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footerActions: some View {
        CareTapFooterActionBar(
            secondaryTitle: state.secondaryActionTitle ?? secondaryTitle,
            primaryTitle: state.primaryActionTitle ?? primaryTitle,
            primarySystemImage: primaryIcon,
            isPrimaryEnabled: state.phase != .writing,
            secondaryAction: onSecondaryAction,
            primaryAction: onPrimaryAction
        )
    }

    private var primaryTitle: String {
        switch state.phase {
        case .ready: "Start Pairing"
        case .writing: "Pairing\u{2026}"
        case .success: "Continue"
        case .failure: "Try Again"
        }
    }

    private var secondaryTitle: String {
        state.phase == .success ? "Pair Another" : "Skip"
    }

    private var primaryIcon: String? {
        switch state.phase {
        case .ready: "dot.radiowaves.left.and.right"
        case .writing: nil
        case .success: "arrow.right"
        case .failure: "arrow.clockwise"
        }
    }
}

#Preview("NFC · Ready") {
    NFCPairingView(state: CareTapPhaseTwoPreviewScenarios.nfcReady)
}

#Preview("NFC · Writing") {
    NFCPairingView(state: CareTapPhaseTwoPreviewScenarios.nfcWriting)
}

#Preview("NFC · Success") {
    NFCPairingView(state: CareTapPhaseTwoPreviewScenarios.nfcSuccess)
}

#Preview("NFC · Failure") {
    NFCPairingView(state: CareTapPhaseTwoPreviewScenarios.nfcFailure)
}
