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
                        .frame(width: 40, height: 40)
                        .careTapLiquidGlass(
                            tint: CareTapTheme.glassTint.opacity(0.05),
                            cornerRadius: 12,
                            interactive: true
                        )
                        .careTapGlassStroke(cornerRadius: 12, opacity: 0.34)

                    if unreadCount > 0 {
                        Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(CareTapTheme.alert, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
