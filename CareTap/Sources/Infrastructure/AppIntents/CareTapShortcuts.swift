import AppIntents
import Foundation

private enum CareTapShortcutsBootstrap {
    @MainActor
    static func makeServices() -> CareTapServiceContainer {
        CareTapSupabaseBootstrap.makeServiceContainer(bundle: .main)
    }

    @MainActor
    static func makeAppStore() -> CareTapAppStore {
        CareTapAppStore(
            services: makeServices(),
            statePersistence: CareTapAppStateStore()
        )
    }

    @MainActor
    static func taggedItems() async throws -> [CareTapTaggedItemEntity] {
        let services = makeServices()
        let snapshot = await services.auth.sessionSnapshot()
        guard let user = snapshot.user else {
            return []
        }

        let state = CareTapAppStateStore().load()
        let profiles = try await services.recordStore.careProfiles(createdBy: user.id)
        let profile = if let activeProfileID = state.activeCareProfileID,
                         let explicitProfile = try await services.recordStore.fetchCareProfile(id: activeProfileID) {
            explicitProfile
        } else {
            profiles.first(where: { $0.patientUserID == user.id }) ?? profiles.first
        }

        guard let profile else {
            return []
        }

        return try await services.recordStore.medications(for: profile.id)
            .filter { $0.isActive && $0.nfcTagID != nil }
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
            .map(CareTapTaggedItemEntity.init)
    }
}

struct CareTapTaggedItemEntity: AppEntity, Identifiable {
    let id: UUID
    let title: String
    let detail: String

    init(medication: Medication) {
        id = medication.id
        title = medication.displayTitle
        detail = medication.bottleLabel
    }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Tagged Item"
    static let defaultQuery = CareTapTaggedItemQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(detail)"
        )
    }
}

struct CareTapTaggedItemQuery: EntityQuery {
    func entities(for identifiers: [CareTapTaggedItemEntity.ID]) async throws -> [CareTapTaggedItemEntity] {
        try await CareTapShortcutsBootstrap.taggedItems()
            .filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CareTapTaggedItemEntity] {
        try await CareTapShortcutsBootstrap.taggedItems()
    }

    func defaultResult() async -> CareTapTaggedItemEntity? {
        try? await CareTapShortcutsBootstrap.taggedItems().first
    }
}

struct LogTaggedItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Tagged Item"
    static let description = IntentDescription("Confirm a paired item from Shortcuts or an NFC personal automation.")
    static let openAppWhenRun = false

    @Parameter(title: "Item")
    var item: CareTapTaggedItemEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$item)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let url = CareTapDeepLink.tagURL(
            payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: item.id)
        ) else {
            return .result(dialog: "That item is not ready for tag automation yet.")
        }

        let store = CareTapShortcutsBootstrap.makeAppStore()
        await store.start()
        await store.handleIncomingURL(url)

        if let errorMessage = store.errorMessage {
            return .result(dialog: "\(errorMessage)")
        }

        let message = store.infoMessage ?? "\(item.title) is ready in CareTap."
        return .result(dialog: "\(message)")
    }
}

struct QuickLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Log"
    static let description = IntentDescription(
        "Log the most recent tagged item. Ideal for NFC automations where the item is already known."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let firstItem = try? await CareTapShortcutsBootstrap.taggedItems().first else {
            return .result(dialog: "No paired items found. Open TapCare and pair an NFC tag first.")
        }

        guard let url = CareTapDeepLink.tagURL(
            payloadIdentifier: CareTapDeepLink.payloadIdentifier(for: firstItem.id)
        ) else {
            return .result(dialog: "That item is not ready for tag automation yet.")
        }

        let store = CareTapShortcutsBootstrap.makeAppStore()
        await store.start()
        await store.handleIncomingURL(url)

        if let errorMessage = store.errorMessage {
            return .result(dialog: "\(errorMessage)")
        }

        return .result(dialog: "\(firstItem.title) logged.")
    }
}

struct CareTapAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogTaggedItemIntent(),
            phrases: [
                "Log \(\.$item) in \(.applicationName)",
                "Confirm \(\.$item) with \(.applicationName)"
            ],
            shortTitle: "Log Tagged Item",
            systemImageName: "dot.radiowaves.left.and.right"
        )

        AppShortcut(
            intent: QuickLogIntent(),
            phrases: [
                "Quick log in \(.applicationName)",
                "Log dose with \(.applicationName)"
            ],
            shortTitle: "Quick Log",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
