import SwiftUI

struct CareTapBottomBar: View {
    let selected: CareTapDestination
    var onSelect: (CareTapDestination) -> Void = { _ in }

    @Namespace private var selectionNamespace

    var body: some View {
        barChrome
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation")
    }

    private var barChrome: some View {
        ZStack {
            barBackground

            HStack(spacing: 8) {
                ForEach(CareTapDestination.allCases) { destination in
                    tabItem(destination)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 74)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var barBackground: some View {
        let barShape = RoundedRectangle(cornerRadius: 30, style: .continuous)

        if #available(iOS 26, *) {
            barShape
                .fill(CareTapTheme.surface.opacity(0.88))
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            CareTapTheme.canvasWarm.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(barShape)
                }
                .overlay {
                    Image("GlassTexture")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.14)
                        .blendMode(.softLight)
                        .clipShape(barShape)
                }
                .overlay {
                    barShape
                        .stroke(CareTapTheme.stroke.opacity(0.18), lineWidth: 0.75)
                }
        } else {
            barShape
                .fill(CareTapTheme.surface.opacity(0.94))
                .background(.thinMaterial, in: barShape)
                .overlay {
                    barShape
                        .stroke(CareTapTheme.stroke.opacity(0.45), lineWidth: 0.5)
                }
        }
    }

    @ViewBuilder
    private func tabItem(_ destination: CareTapDestination) -> some View {
        let isSelected = destination == selected

        Button {
            CareTapHaptics.selection()
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                onSelect(destination)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .center) {
                    if isSelected {
                        selectedTabBackground
                            .matchedGeometryEffect(id: "tabHighlight", in: selectionNamespace)
                    }

                    VStack(spacing: 3) {
                        Image(systemName: isSelected ? destination.selectedSystemImage : destination.systemImage)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                            .symbolEffect(.bounce.byLayer, value: isSelected)

                        Text(destination.title)
                            .font(.system(size: 11, weight: isSelected ? .bold : .semibold, design: .default))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
            }
            .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textPrimary.opacity(0.72))
            .contentShape(Rectangle())
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            .accessibilityLabel(destination.title)
            .accessibilityHint(destination.accessibilityHint)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedTabBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        if #available(iOS 26, *) {
            shape
                .fill(CareTapTheme.surface.opacity(0.58))
                .glassEffect(
                    .regular
                        .tint(CareTapTheme.sage.opacity(0.14))
                        .interactive(),
                    in: .rect(cornerRadius: 20)
                )
                .overlay {
                    Image("GlassTexture")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.12)
                        .blendMode(.softLight)
                        .clipShape(shape)
                }
                .overlay {
                    shape
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.6)
                }
        } else {
            shape
                .fill(CareTapTheme.sage.opacity(0.12))
                .overlay {
                    shape
                        .stroke(CareTapTheme.sage.opacity(0.14), lineWidth: 0.5)
                }
        }
    }
}
