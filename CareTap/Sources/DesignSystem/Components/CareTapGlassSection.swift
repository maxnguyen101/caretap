import SwiftUI

/// A titled section with glass-morphism card styling.
/// Consolidates the repeated `glassSection(title:content:)` pattern found
/// across feature views into a single design system component.
struct CareTapGlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CareTapSectionLabel(title)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapGlassFill(opacity: 0.5)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 18)
            .careTapGlassStroke(cornerRadius: 18, opacity: 0.25)
        }
    }
}

/// Uppercase micro-label used as a section divider in settings, support, and
/// detail views. Replaces duplicated inline Text styling across the codebase.
struct CareTapSectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .default))
            .tracking(0.6)
            .foregroundStyle(CareTapTheme.textTertiary)
    }
}
