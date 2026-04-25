import SwiftUI

@main
struct CareTapApp: App {
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            CareTapRootView()
                .environmentObject(environment)
                .onOpenURL { url in
                    Task {
                        await environment.appStore.handleIncomingURL(url)
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    guard let url = userActivity.webpageURL else {
                        return
                    }

                    Task {
                        await environment.appStore.handleIncomingURL(url)
                    }
                }
        }
    }
}
