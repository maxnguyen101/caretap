import SwiftUI

struct CareTapStatusBadge: View {
    let text: String
    let tone: CareTapTone

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor, in: Capsule())
            .accessibilityLabel(text)
    }

    private var backgroundColor: Color {
        tone == .neutral ? CareTapTheme.surfaceMuted : tone.color.opacity(0.12)
    }

    private var foregroundColor: Color {
        switch tone {
        case .sage: CareTapTheme.sageStrong
        case .neutral: CareTapTheme.textSecondary
        case .mist: CareTapTheme.textPrimary
        default: tone.color
        }
    }
}
