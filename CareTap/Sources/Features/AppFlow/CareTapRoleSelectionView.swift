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
            VStack(spacing: 28) {
                heroSection
                roleSelector
                localFirstSection
                signInSection
                CareTapLegalLinksFooter()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CareTapTheme.sage.opacity(0.22), CareTapTheme.sage.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(CareTapTheme.sageStrong)
            }
            .overlay {
                Circle()
                    .stroke(CareTapTheme.sage.opacity(0.35), lineWidth: 1)
            }
            .padding(.top, 4)

            VStack(spacing: 8) {
                Text("Start tracking, your way")
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Use TapCare privately on this iPhone, then add sync or caregiver sharing when you need it.")
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Roles

    private var roleSelector: some View {
        VStack(spacing: 12) {
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
    }

    private func roleOption(role: CareTapRole, title: String, subtitle: String, icon: String) -> some View {
        let isSelected = selectedRole == role

        return Button {
            CareTapHaptics.selection()
            onRoleSelected(role)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background {
                        if #available(iOS 26, *) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? CareTapTheme.sage.opacity(0.12) : .clear)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? CareTapTheme.sage.opacity(0.12) : CareTapTheme.surfaceMuted)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()

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
            .padding(16)
            .careTapGlassFill(opacity: isSelected ? 0.8 : 0.5)
            .careTapLiquidGlass(
                tint: isSelected ? CareTapTheme.sage.opacity(0.06) : CareTapTheme.glassTint.opacity(0.03),
                cornerRadius: 20
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.3), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isSelected)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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
            .careTapGlassFill(opacity: 0.55)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 18)
            .careTapGlassStroke(cornerRadius: 18, opacity: 0.22)
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
        .padding(16)
        .careTapGlassFill(CareTapTheme.success, opacity: 0.06)
        .careTapLiquidGlass(tint: CareTapTheme.success.opacity(0.04), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.25)
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
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(selectedRole == nil || isBusy)
            .opacity(selectedRole == nil ? 0.4 : 1)

            dividerRow

            Button {
                withAnimation(.spring(duration: 0.3)) {
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
                .padding(.vertical, 14)
                .careTapLiquidGlass(
                    tint: CareTapTheme.glassTint.opacity(0.06),
                    cornerRadius: 14,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.3)
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
                .padding(.vertical, 14)
                .careTapLiquidGlass(
                    tint: CareTapTheme.sage.opacity(0.1),
                    cornerRadius: 14,
                    interactive: true
                )
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.3)
            }
            .buttonStyle(.plain)
            .disabled(!isEmailFormValid || isBusy)
            .opacity(isEmailFormValid ? 1 : 0.5)

            Button {
                withAnimation(.spring(duration: 0.25)) {
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
                withAnimation(.spring(duration: 0.3)) {
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
        .padding(.vertical, 14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.25)
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
        .padding(.vertical, 14)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.25)
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
