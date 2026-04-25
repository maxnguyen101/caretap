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

                ScrollView(.vertical) {
                    content
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, CareTapSpacing.screenPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var backgroundLayer: some View {
        CareTapScreenBackground()
    }
}
