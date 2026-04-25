import Foundation

struct CareTapPersistedSyncState: Codable, Hashable {
    let cursor: CareTapSyncCursor?
    let pendingMutations: CareTapSyncMutationBatch
    let conflicts: [CareTapSyncConflictPayload]
}

struct CareTapPersistedAuthSession: Codable, Hashable {
    let authUserID: UUID
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date?
    let provider: String
    let appleAuthorizationCode: String?

    init(
        authUserID: UUID,
        accessToken: String,
        refreshToken: String,
        expiresAt: Date?,
        provider: String,
        appleAuthorizationCode: String? = nil
    ) {
        self.authUserID = authUserID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.provider = provider
        self.appleAuthorizationCode = appleAuthorizationCode
    }
}

protocol CareTapSyncStatePersisting: Sendable {
    func loadSyncState() throws -> CareTapPersistedSyncState?
    func saveSyncState(_ state: CareTapPersistedSyncState) throws
}

protocol CareTapAuthSessionPersisting: Sendable {
    func loadAuthSession() throws -> CareTapPersistedAuthSession?
    func saveAuthSession(_ session: CareTapPersistedAuthSession) throws
    func clearAuthSession() throws
    func clearAllLocalData() throws
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

final class CareTapBackendDiskStore: CareTapSyncStatePersisting, CareTapAuthSessionPersisting, @unchecked Sendable {
    private let fileManager: FileManager
    private let lock = NSLock()

    let directoryURL: URL

    private var cacheURL: URL {
        directoryURL.appending(path: "local-cache.json")
    }

    private var syncStateURL: URL {
        directoryURL.appending(path: "sync-state.json")
    }

    private var authSessionURL: URL {
        directoryURL.appending(path: "auth-session.json")
    }

    init(directoryURL: URL, fileManager: FileManager = .default) throws {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    static func defaultLiveStore(bundle: Bundle = .main, fileManager: FileManager = .default) throws -> CareTapBackendDiskStore {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleIdentifier = bundle.bundleIdentifier ?? "com.maxnguyen.caretap"
        let directoryURL = applicationSupportURL
            .appending(path: bundleIdentifier, directoryHint: .isDirectory)
            .appending(path: "Backend", directoryHint: .isDirectory)

        return try CareTapBackendDiskStore(directoryURL: directoryURL, fileManager: fileManager)
    }

    func loadCache() throws -> CareTapSyncBatchPayload? {
        try load(CareTapSyncBatchPayload.self, from: cacheURL)
    }

    func saveCache(_ payload: CareTapSyncBatchPayload) throws {
        try save(payload, to: cacheURL)
    }

    func loadSyncState() throws -> CareTapPersistedSyncState? {
        try load(CareTapPersistedSyncState.self, from: syncStateURL)
    }

    func saveSyncState(_ state: CareTapPersistedSyncState) throws {
        try save(state, to: syncStateURL)
    }

    func loadAuthSession() throws -> CareTapPersistedAuthSession? {
        try load(CareTapPersistedAuthSession.self, from: authSessionURL)
    }

    func saveAuthSession(_ session: CareTapPersistedAuthSession) throws {
        try save(session, to: authSessionURL)
    }

    func clearAuthSession() throws {
        try lock.withLock {
            guard fileManager.fileExists(atPath: authSessionURL.path) else {
                return
            }

            try fileManager.removeItem(at: authSessionURL)
        }
    }

    func clearAllLocalData() throws {
        try lock.withLock {
            let fileURLs = [cacheURL, syncStateURL, authSessionURL]
            for fileURL in fileURLs where fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    private func load<Value: Decodable>(_ type: Value.Type, from url: URL) throws -> Value? {
        try lock.withLock {
            guard fileManager.fileExists(atPath: url.path) else {
                return nil
            }

            let data = try Data(contentsOf: url)
            return try CareTapSupabaseJSON.decoder.decode(Value.self, from: data)
        }
    }

    private func save<Value: Encodable>(_ value: Value, to url: URL) throws {
        let data = try CareTapSupabaseJSON.encoder.encode(value)
        try lock.withLock {
            try data.write(to: url, options: .atomic)
        }
    }
}
