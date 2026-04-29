import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct CareTapRoleSelectionView: View {
    let selectedRole: CareTapRole?
    var authenticatedDisplayName: String?
    var isBusy: Bool = false
    var onRoleSelected: (CareTapRole) -> Void
    var onContinueLocally: (CareTapRole) -> Void = { _ in }
    var onSignedIn: (AppleIdentityTokenPayload) -> Void
    var onEmailSignUp: (String, String, String?) -> Void = { _, _, _ in }
    var onEmailSignIn: (String, String) -> Void = { _, _ in }
    var onSignInFailure: (String) -> Void = { _ in }

    @State private var currentNonce = ""
    @State private var showEmailForm = false
    @State private var isSignUpMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        CareTapFlowScaffold(
            leadingSystemImage: nil
        ) {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                roleSelector
                localFirstSection
                signInSection
                CareTapLegalLinksFooter()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .frame(width: 36, height: 36)
                    .background(CareTapTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.5), lineWidth: 1)
                    }

                Text("TapCare")
                    .font(CareTapTypography.brand)
                    .foregroundStyle(CareTapTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Start with your routine")
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Use TapCare privately on this iPhone, then add sync or caregiver sharing when you need it.")
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Roles

    private var roleSelector: some View {
        VStack(spacing: 10) {
            roleOption(
                role: .patient,
                title: "For me",
                subtitle: "Track your own routine",
                icon: "person.fill"
            )

            roleOption(
                role: .caregiver,
                title: "Helping someone",
                subtitle: "Follow someone and stay in sync",
                icon: "person.2.fill"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func roleOption(role: CareTapRole, title: String, subtitle: String, icon: String) -> some View {
        let isSelected = selectedRole == role

        return Button {
            CareTapHaptics.selection()
            onRoleSelected(role)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                                .fill(isSelected ? CareTapTheme.sage.opacity(0.12) : .clear)
                        } else {
                            RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                                .fill(isSelected ? CareTapTheme.sage.opacity(0.12) : CareTapTheme.surfaceMuted)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .stroke(isSelected ? CareTapTheme.sageStrong : CareTapTheme.stroke, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(CareTapTheme.sageStrong)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapGlassFill(opacity: isSelected ? 0.8 : 0.5)
            .careTapLiquidGlass(
                tint: isSelected ? CareTapTheme.sage.opacity(0.04) : CareTapTheme.glassTint.opacity(0.025),
                cornerRadius: CareTapSpacing.cornerRadiusCard
            )
            .overlay {
                RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous)
                    .stroke(isSelected ? CareTapTheme.sage.opacity(0.42) : CareTapTheme.stroke.opacity(0.3), lineWidth: isSelected ? 1.25 : 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Local First

    private var localFirstSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedRole {
                CareTapPrimaryActionButton(
                    title: selectedRole == .patient ? "Continue on This iPhone" : "Continue as Caregiver",
                    systemImage: "iphone",
                    isEnabled: !isBusy
                ) {
                    onContinueLocally(selectedRole)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CareTapTheme.sageStrong)
                        .frame(width: 24, height: 24)
                        .background(CareTapTheme.sage.opacity(0.1), in: Circle())

                    Text("No login required. Your routine, photos, reminders, and NFC tags stay local unless you choose to sync.")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)
            } else {
                CareTapInlineBanner(
                    icon: "hand.tap.fill",
                    tone: .sage,
                    title: "Pick a mode to continue",
                    message: "Most people start with “For me” and add sharing later."
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 14) {
            continueHeader

            if let authenticatedDisplayName {
                authenticatedBanner(displayName: authenticatedDisplayName)
            } else if showEmailForm {
                emailFormSection
            } else {
                appleSignInSection
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var continueHeader: some View {
        if let selectedRole {
            HStack(spacing: 12) {
                Image(systemName: selectedRole == .patient ? "person.fill" : "person.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .frame(width: 34, height: 34)
                    .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Optional sync and sharing")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Sign in when you want account recovery, caregiver sharing, or multi-device setup.")
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapGlassFill(opacity: 0.55)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.22)
        } else {
            Text("Choose a view above to continue.")
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func authenticatedBanner(displayName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CareTapTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Signed in")
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text(displayName)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(CareTapTheme.success, opacity: 0.06)
        .careTapLiquidGlass(tint: CareTapTheme.success.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.24)
    }

    // MARK: - Apple Sign In

    private var appleSignInSection: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.continue) { request in
                currentNonce = randomNonceString()
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(currentNonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                          let tokenData = credential.identityToken,
                          let idToken = String(data: tokenData, encoding: .utf8) else {
                        onSignInFailure("CareTap couldn\u{2019}t read the Apple identity token from this sign-in.")
                        return
                    }

                    let authCode: String? = credential.authorizationCode
                        .flatMap { String(data: $0, encoding: .utf8) }

                    let payload = AppleIdentityTokenPayload(
                        idToken: idToken,
                        rawNonce: currentNonce,
                        authorizationCode: authCode,
                        appleSubject: credential.user,
                        email: credential.email,
                        givenName: credential.fullName?.givenName,
                        familyName: credential.fullName?.familyName
                    )
                    onSignedIn(payload)
                case .failure:
                    onSignInFailure("CareTap couldn\u{2019}t complete Sign in with Apple from this device.")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous))
            .disabled(selectedRole == nil || isBusy)
            .opacity(selectedRole == nil ? 0.4 : 1)

            dividerRow

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showEmailForm = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15, weight: .medium))
                    Text("Continue with email")
                        .font(CareTapTypography.bodyStrong)
                }
                .foregroundStyle(CareTapTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .careTapLiquidGlass(
                    tint: CareTapTheme.glassTint.opacity(0.06),
                    cornerRadius: CareTapSpacing.cornerRadiusCompact,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.3)
            }
            .buttonStyle(.plain)
            .disabled(selectedRole == nil || isBusy)
            .opacity(selectedRole == nil ? 0.4 : 1)

            if isBusy {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(CareTapTheme.sage)
                        .scaleEffect(0.8)
                    Text("Signing in\u{2026}")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                }
            } else if selectedRole == nil {
                Text("Choose a view above to continue")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Email Form

    private var emailFormSection: some View {
        VStack(spacing: 14) {
            if isSignUpMode {
                glassTextField(
                    placeholder: "Name (optional)",
                    text: $displayName,
                    icon: "person",
                    contentType: .name,
                    capitalization: .words
                )
            }

            glassTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                contentType: .emailAddress,
                keyboardType: .emailAddress
            )

            glassSecureField(
                placeholder: "Password",
                text: $password,
                icon: "lock"
            )

            Button {
                CareTapHaptics.confirm()
                if isSignUpMode {
                    let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onEmailSignUp(
                        email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password,
                        name.isEmpty ? nil : name
                    )
                } else {
                    onEmailSignIn(
                        email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isSignUpMode ? "Create account" : "Sign in")
                        .font(CareTapTypography.bodyStrong)
                    if isBusy {
                        ProgressView()
                            .tint(CareTapTheme.textPrimary)
                            .scaleEffect(0.7)
                    }
                }
                .foregroundStyle(CareTapTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .careTapLiquidGlass(
                    tint: CareTapTheme.sage.opacity(0.1),
                    cornerRadius: CareTapSpacing.cornerRadiusCompact,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.3)
            }
            .buttonStyle(.plain)
            .disabled(!isEmailFormValid || isBusy)
            .opacity(isEmailFormValid ? 1 : 0.5)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isSignUpMode.toggle()
                }
            } label: {
                Text(isSignUpMode ? "Already have an account? Sign in" : "Need an account? Sign up")
                    .font(CareTapTypography.footnote.weight(.medium))
                    .foregroundStyle(CareTapTheme.sageStrong)
            }
            .buttonStyle(.plain)

            dividerRow

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showEmailForm = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .medium))
                    Text("Use Apple instead")
                        .font(CareTapTypography.footnote.weight(.semibold))
                }
                .foregroundStyle(CareTapTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var isEmailFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedEmail.isEmpty && trimmedEmail.contains("@") && password.count >= 6
    }

    private func glassTextField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType? = nil,
        keyboardType: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .never
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(CareTapTypography.body)
                .foregroundStyle(CareTapTheme.textPrimary)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: CareTapSpacing.cornerRadiusCompact)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.25)
    }

    private func glassSecureField(
        placeholder: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 20)

            SecureField(placeholder, text: text)
                .font(CareTapTypography.body)
                .foregroundStyle(CareTapTheme.textPrimary)
                .textContentType(.password)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: CareTapSpacing.cornerRadiusCompact)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.25)
    }

    private var dividerRow: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(CareTapTheme.separator.opacity(0.5))
                .frame(height: 0.5)
            Text("or")
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
            Rectangle()
                .fill(CareTapTheme.separator.opacity(0.5))
                .frame(height: 0.5)
        }
    }

    // MARK: - Crypto

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    CareTapRoleSelectionView(
        selectedRole: .patient,
        onRoleSelected: { _ in },
        onSignedIn: { _ in }
    )
}
