import SwiftUI

struct HomeScreenScaffold<Content: View>: View {
    let profile: PersonProfile
    let selectedDestination: CareTapDestination
    let unreadNoticeCount: Int
    var onDestinationSelected: (CareTapDestination) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}
    private let content: Content

    init(
        profile: PersonProfile,
        selectedDestination: CareTapDestination,
        unreadNoticeCount: Int = 0,
        onDestinationSelected: @escaping (CareTapDestination) -> Void = { _ in },
        onNotificationsTap: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.profile = profile
        self.selectedDestination = selectedDestination
        self.unreadNoticeCount = unreadNoticeCount
        self.onDestinationSelected = onDestinationSelected
        self.onNotificationsTap = onNotificationsTap
        self.content = content()
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                CareTapTopBar(
                    unreadCount: unreadNoticeCount,
                    onNotificationsTap: onNotificationsTap
                )

                CareTapViewportScrollView(topPadding: 8, bottomPadding: 28) {
                    content
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
    }

    private var backgroundLayer: some View {
        CareTapScreenBackground()
    }
}
