import SwiftUI

struct CareTapStatusBadge: View {
    let text: String
    let tone: CareTapTone

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
