import SwiftUI

struct CareTapSegmentedItem<ID: Hashable>: Identifiable, Hashable {
    let id: ID
    let title: String
    let subtitle: String?

    init(id: ID, title: String, subtitle: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

struct CareTapSegmentedControl<ID: Hashable>: View {
    let items: [CareTapSegmentedItem<ID>]
    let selectedID: ID
    var onSelect: (ID) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                segment(item)
            }
        }
        .padding(4)
        .careTapLiquidGlass(
            tint: CareTapTheme.glassTint.opacity(0.035),
            cornerRadius: 12
        )
        .careTapGlassStroke(cornerRadius: 12, opacity: 0.24)
    }

    private func segment(_ item: CareTapSegmentedItem<ID>) -> some View {
        let isSelected = item.id == selectedID

        return Button {
            guard !isSelected else { return }
            CareTapHaptics.selection()
            onSelect(item.id)
        } label: {
            VStack(spacing: item.subtitle == nil ? 0 : 2) {
                Text(item.title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(isSelected ? CareTapTheme.textPrimary : CareTapTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundStyle(isSelected ? CareTapTheme.textSecondary : CareTapTheme.textTertiary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: item.subtitle == nil ? 44 : 52)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? CareTapTheme.surface.opacity(0.9) : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(
                                isSelected
                                    ? CareTapTheme.stroke.opacity(0.52)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CareTapPressableButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
