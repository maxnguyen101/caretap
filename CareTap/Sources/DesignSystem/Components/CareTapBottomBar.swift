import SwiftUI

/// Floating bottom navigation: compact, liquid-glass, sized to the window (not oversized).
struct CareTapBottomBar: View {
    let selected: CareTapDestination
    var onSelect: (CareTapDestination) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CareTapDestination.allCases) { destination in
                tabItem(destination)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background { barBackground }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.32), lineWidth: 0.75)
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab navigation")
    }

    @ViewBuilder
    private var barBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(CareTapTheme.surface.opacity(0.78))
            .careTapLiquidGlass(
                tint: CareTapTheme.glassTint.opacity(0.05),
                cornerRadius: 22
            )
    }

    @ViewBuilder
    private func tabItem(_ destination: CareTapDestination) -> some View {
        let isSelected = destination == selected

        Button {
            CareTapHaptics.selection()
            withAnimation(.easeInOut(duration: 0.18)) {
                onSelect(destination)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? destination.selectedSystemImage : destination.systemImage)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))

                Text(destination.tabBarTitle)
                    .font(.system(size: 9, weight: .semibold, design: .default))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
            .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textPrimary.opacity(0.68))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(CareTapTheme.sage.opacity(0.12))
                        .padding(.horizontal, 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(destination.title)
        .accessibilityHint(destination.accessibilityHint)
    }
}
