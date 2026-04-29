import SwiftUI

struct CaregiverWelcomeView: View {
    let state: CaregiverWelcomeViewState
    let inviteCode: String
    var onInviteCodeChanged: (String) -> Void = { _ in }
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: () -> Void = {}
    @State private var draftInviteCode = ""

    var body: some View {
        let secondaryTitle = draftInviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? state.secondaryActionTitle
            : "Decline Code"

        CareTapFlowScaffold(
            leadingSystemImage: nil
        ) {
            VStack(spacing: 32) {
                heroSection
                codeSection
                instructionsSection
            }
        } footer: {
            CareTapFooterActionBar(
                secondaryTitle: secondaryTitle,
                primaryTitle: state.primaryActionTitle,
                primarySystemImage: "arrow.right",
                secondaryAction: onSecondaryAction,
                primaryAction: onPrimaryAction
            )
        }
        .onAppear {
            draftInviteCode = inviteCode
        }
        .onChange(of: inviteCode) { _, newValue in
            if newValue != draftInviteCode {
                draftInviteCode = newValue
            }
        }
        .onChange(of: draftInviteCode) { _, newValue in
            onInviteCodeChanged(newValue.uppercased())
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(CareTapTheme.sage)
                .padding(.top, 16)

            Text(state.title)
                .font(CareTapTypography.hero)
                .foregroundStyle(CareTapTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(state.message)
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Code

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invite code")
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.textSecondary)

            TextField(
                "Enter code",
                text: $draftInviteCode
            )
            .textInputAutocapitalization(.characters)
            .font(.system(size: 28, weight: .semibold, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
            .overlay {
                RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                    .stroke(
                        draftInviteCode.isEmpty ? CareTapTheme.stroke.opacity(0.25) : CareTapTheme.sage.opacity(0.5),
                        lineWidth: draftInviteCode.isEmpty ? 1 : 1.5
                    )
            }
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)

            Text(state.inviteInstructions)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.15)
    }
}
