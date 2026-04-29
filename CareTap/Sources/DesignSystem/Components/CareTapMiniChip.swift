import SwiftUI

/// A small label used to display metadata chips
/// (e.g. "NFC", "Low Supply", "Refill") next to medication rows.
struct CareTapMiniChip: View {
    let text: String
    var tint: Color = CareTapTheme.sage

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 0.5)
            }
            .accessibilityLabel(text)
    }
}
