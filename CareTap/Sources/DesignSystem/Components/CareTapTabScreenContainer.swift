import SwiftUI

struct CareTapTabScreenContainer<Content: View>: View {
    let unreadNoticeCount: Int
    var onNotificationsTap: () -> Void = {}
    private let content: Content

    init(
        unreadNoticeCount: Int = 0,
        onNotificationsTap: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.unreadNoticeCount = unreadNoticeCount
        self.onNotificationsTap = onNotificationsTap
        self.content = content()
    }

    var body: some View {
        ZStack {
            CareTapScreenBackground()

            VStack(spacing: 0) {
                CareTapTopBar(
                    unreadCount: unreadNoticeCount,
                    onNotificationsTap: onNotificationsTap
                )

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}
