import Foundation

enum CareTapRuntimeConfigurationError: Error {
    case missingProjectURL
    case invalidProjectURL
    case missingPublishableKey
}

enum CareTapSupabaseBootstrap {
    private static let projectURLKey = "CareTapSupabaseProjectURL"
    private static let publishableKeyKey = "CareTapSupabasePublishableKey"
    private static let universalLinkHostKey = "CareTapUniversalLinkHost"

    static func configuration(bundle: Bundle = .main) throws -> SupabaseConfiguration {
        guard let projectURLString = bundle.object(forInfoDictionaryKey: projectURLKey) as? String,
              !projectURLString.isEmpty else {
            throw CareTapRuntimeConfigurationError.missingProjectURL
        }

        guard let projectURL = URL(string: projectURLString) else {
            throw CareTapRuntimeConfigurationError.invalidProjectURL
        }

        guard let publishableKey = bundle.object(forInfoDictionaryKey: publishableKeyKey) as? String,
              !publishableKey.isEmpty else {
            throw CareTapRuntimeConfigurationError.missingPublishableKey
        }

        let universalLinkHost = bundle.object(forInfoDictionaryKey: universalLinkHostKey) as? String
        return SupabaseConfiguration(
            projectURL: projectURL,
            apiKey: publishableKey,
            universalLinkHost: universalLinkHost
        )
    }

    @MainActor
    static func makeServiceContainer(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> CareTapServiceContainer {
        guard let configuration = try? configuration(bundle: bundle),
              let diskStore = try? CareTapBackendDiskStore.defaultLiveStore(bundle: bundle, fileManager: fileManager) else {
            return .failsafeUnavailable()
        }

        return (try? .live(configuration: configuration, diskStore: diskStore)) ?? .failsafeUnavailable()
    }
}
