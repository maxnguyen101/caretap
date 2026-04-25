import Foundation

protocol CareTapAppStatePersisting {
    func load() -> CareTapPersistedAppState
    func save(_ state: CareTapPersistedAppState)
    func clear()
}

final class CareTapAppStateStore: CareTapAppStatePersisting {
    private let defaults: UserDefaults
    private let key = "com.maxnguyen.caretap.app-state"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> CareTapPersistedAppState {
        guard let data = defaults.data(forKey: key),
              let state = try? CareTapSupabaseJSON.decoder.decode(CareTapPersistedAppState.self, from: data) else {
            return .default()
        }

        return state
    }

    func save(_ state: CareTapPersistedAppState) {
        guard let data = try? CareTapSupabaseJSON.encoder.encode(state) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
