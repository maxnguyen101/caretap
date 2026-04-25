import Foundation

final class SupabaseAuthCoordinator: AuthCoordinating, @unchecked Sendable {
    private enum SupabaseAuthCoordinatorError: LocalizedError {
        case invalidAuthURL
        case invalidFunctionURL
        case missingSession
        case missingEdgeFunction(name: String)
        case requestFailed(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidAuthURL:
                return "CareTap couldn’t build the Supabase authentication request."
            case .invalidFunctionURL:
                return "CareTap couldn’t build the Supabase function request."
            case .missingSession:
                return "CareTap needs a signed-in session before it can manage the account."
            case let .missingEdgeFunction(name):
                if name == "delete-account" {
                    return "Account deletion isn’t available on this CareTap project yet."
                }
                return "CareTap couldn’t find the Supabase function \"\(name)\" for this project yet."
            case let .requestFailed(statusCode, message):
                return "Supabase auth failed (\(statusCode)): \(message)"
            }
        }
    }

    private struct SupabaseAuthErrorResponse: Decodable {
        let error: String?
        let msg: String?
        let errorDescription: String?
        let code: String?

        enum CodingKeys: String, CodingKey {
            case error
            case msg
            case errorDescription = "error_description"
            case code
        }

        var bestMessage: String {
            [msg, errorDescription, error, code]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "Unknown authentication error"
        }
    }

    private struct SupabaseTokenExchangeRequest: Encodable {
        let provider: String
        let idToken: String
        let nonce: String

        enum CodingKeys: String, CodingKey {
            case provider
            case idToken = "id_token"
            case nonce
        }
    }

    private struct SupabaseEmailSignUpRequest: Encodable {
        let email: String
        let password: String
        let data: UserMetadata?

        struct UserMetadata: Encodable {
            let displayName: String?

            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"
            }
        }
    }

    private struct SupabaseEmailSignInRequest: Encodable {
        let email: String
        let password: String
    }

    private struct SupabaseRefreshRequest: Encodable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    private struct SupabaseSessionResponse: Decodable {
        struct AuthUser: Decodable {
            let id: UUID
            let email: String?
        }

        let accessToken: String
        let refreshToken: String
        let expiresIn: Int?
        let expiresAt: TimeInterval?
        let user: AuthUser

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
            case user
        }
    }

    private struct DeleteAccountResponse: Decodable {
        let success: Bool
    }

    private let configuration: SupabaseConfiguration
    private let sessionStore: any CareTapAuthSessionPersisting
    private let recordStore: any CareTapRecordStoring
    private let session: URLSession

    init(
        configuration: SupabaseConfiguration,
        sessionStore: any CareTapAuthSessionPersisting,
        recordStore: any CareTapRecordStoring,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.recordStore = recordStore
        self.session = session
    }

    func sessionSnapshot() async -> AuthenticationSessionSnapshot {
        do {
            guard let persistedSession = try sessionStore.loadAuthSession() else {
                return AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
            }

            let refreshedSession = try await validSession(from: persistedSession)
            let user = try await recordStore.fetchUser(authUserID: refreshedSession.authUserID)
            return AuthenticationSessionSnapshot(state: .linkedForSync, user: user, lastUpdatedAt: .now)
        } catch {
            try? sessionStore.clearAuthSession()
            return AuthenticationSessionSnapshot(state: .signedOut, user: nil, lastUpdatedAt: .now)
        }
    }

    func signInWithApple(
        with payload: AppleIdentityTokenPayload,
        preferredRole: CareTapRole
    ) async throws -> AuthenticationSessionSnapshot {
        let response = try await exchangeIdentityToken(payload)
        let displayName = Self.displayName(
            givenName: payload.givenName,
            familyName: payload.familyName,
            email: payload.email
        )
        return try await finalizeSession(
            response: response,
            provider: "apple",
            preferredRole: preferredRole,
            displayName: displayName,
            appleSubject: payload.appleSubject,
            isAppleLinked: true,
            appleAuthorizationCode: payload.authorizationCode
        )
    }

    func signUpWithEmail(
        _ credential: EmailPasswordCredential,
        preferredRole: CareTapRole
    ) async throws -> AuthenticationSessionSnapshot {
        let response = try await emailSignUp(credential)
        let displayName = credential.displayName
            ?? Self.displayName(givenName: nil, familyName: nil, email: credential.email)
        return try await finalizeSession(
            response: response,
            provider: "email",
            preferredRole: preferredRole,
            displayName: displayName,
            appleSubject: nil,
            isAppleLinked: false
        )
    }

    func signInWithEmail(
        _ credential: EmailPasswordCredential,
        preferredRole: CareTapRole
    ) async throws -> AuthenticationSessionSnapshot {
        let response = try await emailSignIn(credential)
        let displayName = credential.displayName
            ?? Self.displayName(givenName: nil, familyName: nil, email: credential.email)
        return try await finalizeSession(
            response: response,
            provider: "email",
            preferredRole: preferredRole,
            displayName: displayName,
            appleSubject: nil,
            isAppleLinked: false
        )
    }

    private func finalizeSession(
        response: SupabaseSessionResponse,
        provider: String,
        preferredRole: CareTapRole,
        displayName: String,
        appleSubject: String?,
        isAppleLinked: Bool,
        appleAuthorizationCode: String? = nil
    ) async throws -> AuthenticationSessionSnapshot {
        let persistedSession = CareTapPersistedAuthSession(
            authUserID: response.user.id,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt(from: response),
            provider: provider,
            appleAuthorizationCode: appleAuthorizationCode
        )
        try sessionStore.saveAuthSession(persistedSession)

        let user = User(
            id: UUID(),
            authUserID: response.user.id,
            appleSubject: appleSubject,
            preferredRole: preferredRole,
            displayName: displayName,
            initials: Self.initials(from: displayName),
            timezoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier,
            isSignInWithAppleLinked: isAppleLinked,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .pendingUpload
        )

        let existingUser = try await recordStore.fetchUser(authUserID: response.user.id)
        let storedUser = if let existingUser {
            try await recordStore.upsertUser(
                User(
                    id: existingUser.id,
                    authUserID: response.user.id,
                    appleSubject: appleSubject ?? existingUser.appleSubject,
                    preferredRole: preferredRole,
                    displayName: displayName == "CareTap User" ? existingUser.displayName : displayName,
                    initials: displayName == "CareTap User" ? existingUser.initials : Self.initials(from: displayName),
                    timezoneIdentifier: TimeZone.current.identifier,
                    localeIdentifier: Locale.current.identifier,
                    isSignInWithAppleLinked: isAppleLinked || existingUser.isSignInWithAppleLinked,
                    createdAt: existingUser.createdAt,
                    updatedAt: .now,
                    lastActiveAt: .now,
                    syncState: .pendingUpload
                )
            )
        } else {
            try await recordStore.upsertUser(user)
        }

        return AuthenticationSessionSnapshot(state: .linkedForSync, user: storedUser, lastUpdatedAt: .now)
    }

    func signOut() async {
        if let persistedSession = try? sessionStore.loadAuthSession() {
            try? await revokeSession(persistedSession)
        }

        try? sessionStore.clearAllLocalData()
    }

    func deleteAccount() async throws {
        guard let persistedSession = try sessionStore.loadAuthSession() else {
            throw SupabaseAuthCoordinatorError.missingSession
        }

        let freshSession = try await forceRefreshedSession(from: persistedSession)

        // Include Apple authorization code so the server can revoke Apple tokens
        // per Apple's Sign in with Apple account deletion requirement (TN3194).
        var requestBody: [String: String]? = nil
        if let code = persistedSession.appleAuthorizationCode {
            requestBody = ["apple_authorization_code": code]
        }

        do {
            _ = try await invokeEdgeFunction(
                named: "delete-account",
                accessToken: freshSession.accessToken,
                body: requestBody
            ) as DeleteAccountResponse
        } catch let error as SupabaseAuthCoordinatorError {
            if case .requestFailed(let statusCode, _) = error, statusCode == 401 {
                let retrySession = try await forceRefreshedSession(from: freshSession)
                _ = try await invokeEdgeFunction(
                    named: "delete-account",
                    accessToken: retrySession.accessToken,
                    body: requestBody
                ) as DeleteAccountResponse
            } else {
                throw error
            }
        }

        try sessionStore.clearAllLocalData()
    }

    private func validSession(from persistedSession: CareTapPersistedAuthSession) async throws -> CareTapPersistedAuthSession {
        if let expiresAt = persistedSession.expiresAt,
           expiresAt > Date().addingTimeInterval(60) {
            return persistedSession
        }

        return try await forceRefreshedSession(from: persistedSession)
    }

    private func forceRefreshedSession(from persistedSession: CareTapPersistedAuthSession) async throws -> CareTapPersistedAuthSession {
        let response = try await refreshSession(refreshToken: persistedSession.refreshToken)
        let refreshed = CareTapPersistedAuthSession(
            authUserID: response.user.id,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiresAt(from: response),
            provider: persistedSession.provider,
            appleAuthorizationCode: persistedSession.appleAuthorizationCode
        )
        try sessionStore.saveAuthSession(refreshed)
        return refreshed
    }

    private func exchangeIdentityToken(_ payload: AppleIdentityTokenPayload) async throws -> SupabaseSessionResponse {
        let request = SupabaseTokenExchangeRequest(
            provider: "apple",
            idToken: payload.idToken,
            nonce: payload.rawNonce
        )
        return try await performAuthRequest(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: request
        )
    }

    private func emailSignUp(_ credential: EmailPasswordCredential) async throws -> SupabaseSessionResponse {
        // Use the email-signup edge function which creates the user with
        // auto-confirm via the admin API, bypassing email confirmation.
        let body: [String: String?] = [
            "email": credential.email,
            "password": credential.password,
            "display_name": credential.displayName
        ]
        let url = try edgeFunctionURL(named: "email-signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try CareTapSupabaseJSON.encoder.encode(body)
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CareTapServiceError.authenticationFailed
        }

        if httpResponse.statusCode == 409 {
            // Email already registered — try signing in instead
            return try await emailSignIn(credential)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapAuthError(statusCode: httpResponse.statusCode, data: data)
        }

        return try CareTapSupabaseJSON.decoder.decode(SupabaseSessionResponse.self, from: data)
    }

    private func emailSignIn(_ credential: EmailPasswordCredential) async throws -> SupabaseSessionResponse {
        try await performAuthRequest(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: SupabaseEmailSignInRequest(email: credential.email, password: credential.password)
        )
    }

    private func refreshSession(refreshToken: String) async throws -> SupabaseSessionResponse {
        try await performAuthRequest(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: SupabaseRefreshRequest(refreshToken: refreshToken)
        )
    }

    private func revokeSession(_ persistedSession: CareTapPersistedAuthSession) async throws {
        let url = try authURL(path: "logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(persistedSession.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CareTapServiceError.authenticationFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapAuthError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func performAuthRequest<Body: Encodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body
    ) async throws -> SupabaseSessionResponse {
        let url = try authURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try CareTapSupabaseJSON.encoder.encode(body)
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CareTapServiceError.authenticationFailed
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapAuthError(statusCode: httpResponse.statusCode, data: data)
        }

        return try CareTapSupabaseJSON.decoder.decode(SupabaseSessionResponse.self, from: data)
    }

    private func invokeEdgeFunction<Response: Decodable>(
        named functionName: String,
        accessToken: String,
        body: [String: String]? = nil
    ) async throws -> Response {
        let url = try edgeFunctionURL(named: functionName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try CareTapSupabaseJSON.encoder.encode(body)
        } else {
            request.httpBody = Data("{}".utf8)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CareTapServiceError.authenticationFailed
        }

        if httpResponse.statusCode == 404 {
            throw SupabaseAuthCoordinatorError.missingEdgeFunction(name: functionName)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw mapAuthError(statusCode: httpResponse.statusCode, data: data)
        }

        return try CareTapSupabaseJSON.decoder.decode(Response.self, from: data)
    }

    private func authURL(
        path: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthCoordinatorError.invalidAuthURL
        }

        components.path = "/auth/v1/\(path)"
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseAuthCoordinatorError.invalidAuthURL
        }

        return url
    }

    private func edgeFunctionURL(named functionName: String) throws -> URL {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthCoordinatorError.invalidFunctionURL
        }

        components.path = "/functions/v1/\(functionName)"

        guard let url = components.url else {
            throw SupabaseAuthCoordinatorError.invalidFunctionURL
        }

        return url
    }

    private func mapAuthError(statusCode: Int, data: Data) -> Error {
        let message: String

        if let decoded = try? CareTapSupabaseJSON.decoder.decode(SupabaseAuthErrorResponse.self, from: data) {
            message = decoded.bestMessage
        } else if let rawBody = String(data: data, encoding: .utf8), !rawBody.isEmpty {
            message = rawBody
        } else {
            message = "Unknown authentication error"
        }

        return SupabaseAuthCoordinatorError.requestFailed(statusCode: statusCode, message: message)
    }

    private func expiresAt(from response: SupabaseSessionResponse) -> Date? {
        if let expiresAt = response.expiresAt {
            return Date(timeIntervalSince1970: expiresAt)
        }

        if let expiresIn = response.expiresIn {
            return Date().addingTimeInterval(TimeInterval(expiresIn))
        }

        return nil
    }

    private static func displayName(
        givenName: String?,
        familyName: String?,
        email: String?
    ) -> String {
        let combined = [givenName, familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !combined.isEmpty {
            return combined
        }

        if let email, let localPart = email.split(separator: "@").first, !localPart.isEmpty {
            return localPart
                .split(separator: ".")
                .map { $0.capitalized }
                .joined(separator: " ")
        }

        return "CareTap User"
    }

    private static func initials(from displayName: String) -> String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }
        return letters.isEmpty ? "CT" : String(letters).uppercased()
    }
}
