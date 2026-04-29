import SwiftUI

/// A titled section with restrained glass card styling.
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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapGlassFill(opacity: 0.58)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.26)
        }
    }
}

/// Small section divider used in settings, support, and detail views.
struct CareTapSectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(CareTapTypography.footnote.weight(.semibold))
            .foregroundStyle(CareTapTheme.textSecondary)
    }
}
