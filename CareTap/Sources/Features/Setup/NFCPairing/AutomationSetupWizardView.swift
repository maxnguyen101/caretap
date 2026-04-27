import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AutomationSetupWizardView: View {
    let automationURL: URL?
    let onDismiss: () -> Void

    @State private var currentStep = 0
    @State private var didCopyLink = false
    @Environment(\.openURL) private var openURL

    private let steps: [AutomationWizardStep] = [
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_1",
            fallbackImageName: "automation_step_1",
            icon: "magnifyingglass",
            title: "Open Shortcuts & Automation",
            instruction: "Open **Shortcuts**, tap **Automation**, then tap **+**. Use the **Search** bar at the bottom of the picker.",
            highlight: "Tap Search at the bottom"
        ),
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_2",
            fallbackImageName: "automation_step_2",
            icon: "sensor.tag.radiowaves.forward.fill",
            title: "Find NFC Trigger",
            instruction: "Search for **NFC**, then choose the trigger that says **When I tap an NFC tag**.",
            highlight: "Search \"NFC\" and tap it"
        ),
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_3",
            fallbackImageName: "automation_step_3",
            icon: "bolt.fill",
            title: "Scan & Set to Run Immediately",
            instruction: "Tap **Scan** and hold your iPhone near the paired tag. Then choose **Run Immediately** so it logs without an extra prompt.",
            highlight: "Tap Scan, then select Run Immediately"
        ),
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_4",
            fallbackImageName: "automation_step_4",
            icon: "plus.rectangle.on.rectangle",
            title: "Fallback: Create a New Shortcut",
            instruction: "If **CareTap** appears in the action picker, choose **Log Tagged Item** first. If it doesn’t, use **Create New Shortcut** for the fallback shown here.",
            highlight: "Choose CareTap first, or tap Create New Shortcut"
        ),
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_5",
            fallbackImageName: "automation_step_5",
            icon: "safari.fill",
            title: "Fallback: Search for \"Open URLs\"",
            instruction: "This fallback only matters if the CareTap shortcut action does not appear. Search for **open url** and choose **Open URLs**.",
            highlight: "Only use this if TapCare is not available"
        ),
        AutomationWizardStep(
            imageName: "AutomationGuide/automation_step_6",
            fallbackImageName: "automation_step_6",
            icon: "link",
            title: "Paste Your Tag Link",
            instruction: "Tap the blue **URL** field and paste the CareTap link you copied. Then tap the **checkmark** to save.",
            highlight: "Paste the link and tap the checkmark"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $currentStep) {
                ForEach(steps.indices, id: \.self) { index in
                    stepPage(steps[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(duration: 0.35), value: currentStep)

            footer
        }
        .background(CareTapTheme.canvas.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .frame(width: 34, height: 34)
                    .careTapLiquidGlass(
                        tint: CareTapTheme.glassTint.opacity(0.06),
                        cornerRadius: 17,
                        interactive: true
                    )
                    .careTapGlassStroke(cornerRadius: 17, opacity: 0.3)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Step \(currentStep + 1) of \(steps.count)")
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Step Page

    private func stepPage(_ step: AutomationWizardStep, index: Int) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if index == 0 {
                    copyLinkCard
                }

                screenshotCard(step)

                instructionCard(step)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    private func screenshotCard(_ step: AutomationWizardStep) -> some View {
        AutomationStepScreenshotView(step: step)
    }

    private func instructionCard(_ step: AutomationWizardStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: step.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .frame(width: 36, height: 36)
                    .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(step.title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(LocalizedStringKey(step.instruction))
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CareTapTheme.sageStrong)

                Text(step.highlight)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.sageStrong)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CareTapTheme.sage.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.2)
    }

    // MARK: - Copy Link Card

    private var copyLinkCard: some View {
        Button {
            #if canImport(UIKit)
            UIPasteboard.general.string = automationURL?.absoluteString ?? ""
            #endif
            CareTapHaptics.confirm()
            didCopyLink = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: didCopyLink ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(didCopyLink ? CareTapTheme.success : CareTapTheme.sageStrong)
                    .frame(width: 40, height: 40)
                    .background(
                        (didCopyLink ? CareTapTheme.success : CareTapTheme.sage).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(didCopyLink ? "Link Copied" : "Copy Tag Link First")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        didCopyLink
                            ? "Fastest path: search CareTap and choose Log Tagged Item. The screenshots below are the Open URL fallback."
                            : (automationURL?.absoluteString ?? "No link available")
                    )
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .lineLimit(didCopyLink ? 3 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(didCopyLink ? CareTapTheme.success.opacity(0.06) : CareTapTheme.sage.opacity(0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        didCopyLink ? CareTapTheme.success.opacity(0.3) : CareTapTheme.sage.opacity(0.3),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: didCopyLink)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            progressDots

            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(CareTapTypography.bodyStrong)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.05),
                            cornerRadius: 16,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 16, opacity: 0.28)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    if currentStep < steps.count - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        if let shortcutsURL = URL(string: "shortcuts://create-automation") {
                            openURL(shortcutsURL)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentStep < steps.count - 1 ? "Next" : "Open Shortcuts")
                            .font(CareTapTypography.bodyStrong)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: currentStep < steps.count - 1 ? "chevron.right" : "arrow.up.forward.square")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .careTapLiquidGlass(
                        tint: CareTapTheme.sage.opacity(0.1),
                        cornerRadius: 16,
                        interactive: true
                    )
                    .careTapGlassStroke(cornerRadius: 16, opacity: 0.28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.06), cornerRadius: 22)
            .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? CareTapTheme.sageStrong : CareTapTheme.textTertiary.opacity(0.25))
                    .frame(width: index == currentStep ? 20 : 8, height: 6)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Model

private struct AutomationWizardStep {
    let imageName: String
    let fallbackImageName: String
    let icon: String
    let title: String
    let instruction: String
    let highlight: String
}

private struct AutomationStepScreenshotView: View {
    let step: AutomationWizardStep

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(CareTapTheme.textTertiary)

                    Text("Screenshot unavailable")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    Text("The walkthrough text below still explains this step.")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .padding(20)
                .background(CareTapTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .frame(maxHeight: 380)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CareTapTheme.stroke, lineWidth: 1)
        )
    }

    private func loadImage() -> UIImage? {
        UIImage(named: step.imageName) ?? UIImage(named: step.fallbackImageName)
    }
}
