import SwiftUI

struct CareTapTopBar: View {
    var unreadCount: Int = 0
    var onNotificationsTap: () -> Void = {}

    var body: some View {
        HStack {
            Spacer()

            Button {
                CareTapInteraction.dismissKeyboard()
                onNotificationsTap()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: unreadCount == 0 ? "bell" : "bell.badge.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.08),
                            cornerRadius: 22,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 22, opacity: 0.4)

                    if unreadCount > 0 {
                        Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(CareTapTheme.alert, in: Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
                .accessibilityLabel(unreadCount == 0 ? "Open notifications" : "Open notifications, \(unreadCount) unread")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CareTapSpacing.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
