import SwiftUI

@MainActor
final class AppEnvironment: ObservableObject {
    let services: CareTapServiceContainer
    let appStore: CareTapAppStore

    var homeSnapshots: HomeSnapshotProviding {
        services.homeSnapshots
    }

    init(services: CareTapServiceContainer) {
        self.services = services
        appStore = CareTapAppStore(services: services)
    }

    static func bootstrap(bundle: Bundle = .main) -> AppEnvironment {
        AppEnvironment(services: CareTapSupabaseBootstrap.makeServiceContainer(bundle: bundle))
    }

    static let preview = AppEnvironment(services: .preview)
}
