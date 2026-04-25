import Foundation

final class CareTapWidgetSnapshotStore: CareTapWidgetSnapshotStoring, @unchecked Sendable {
    private struct PersistedSnapshots: Codable, Hashable {
        var bestNextStep: BestNextStepSnapshot?
        var todaySnapshot: TodaySnapshotWidgetState?
    }

    private let fileManager: FileManager
    private let lock = NSLock()
    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        storageURL = Self.makeStorageURL(bundle: bundle, fileManager: fileManager)
        try? fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    func loadBestNextStep() throws -> BestNextStepSnapshot? {
        try load()?.bestNextStep
    }

    func loadTodaySnapshot() throws -> TodaySnapshotWidgetState? {
        try load()?.todaySnapshot
    }

    func save(bestNextStep: BestNextStepSnapshot, todaySnapshot: TodaySnapshotWidgetState) throws {
        try lock.withLock {
            let persisted = PersistedSnapshots(bestNextStep: bestNextStep, todaySnapshot: todaySnapshot)
            let data = try encoder.encode(persisted)
            try data.write(to: storageURL, options: .atomic)
        }
    }

    private func load() throws -> PersistedSnapshots? {
        try lock.withLock { () throws -> PersistedSnapshots? in
            guard fileManager.fileExists(atPath: storageURL.path) else {
                return nil
            }

            let data = try Data(contentsOf: storageURL)
            return try decoder.decode(PersistedSnapshots.self, from: data)
        }
    }

    private static func makeStorageURL(bundle: Bundle, fileManager: FileManager) -> URL {
        let appGroupIdentifier = bundle.object(forInfoDictionaryKey: "CareTapAppGroupIdentifier") as? String
        if let appGroupIdentifier,
           !appGroupIdentifier.isEmpty,
           let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL.appending(path: "widget-snapshots.json")
        }

        let applicationSupportURL = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appending(path: bundle.bundleIdentifier ?? "com.maxnguyen.caretap", directoryHint: .isDirectory)
            .appending(path: "widget-snapshots.json")
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
