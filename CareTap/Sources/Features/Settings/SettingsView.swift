import SwiftUI

struct SettingsView: View {
    let state: SettingsViewState
    var showsBackButton: Bool = true
    var onBack: () -> Void = {}
    var onRowTap: (SettingsRowState) -> Void = { _ in }
    var onToggle: (SettingsRowState, Bool) -> Void = { _, _ in }

    @State private var presentedLegalPage: CareTapLegalPage?

    var body: some View {
        CareTapFlowScaffold(
            leadingSystemImage: showsBackButton ? "chevron.left" : nil,
            leadingAction: onBack
        ) {
            VStack(alignment: .leading, spacing: 24) {
                profileHeader
                spotlightSection

                if isLoading {
                    loadingState
                }

                if let errorMessage {
                    errorBanner(errorMessage)
                }

                if state.sections.isEmpty && !isLoading {
                    emptyState
                } else {
                    ForEach(displaySections) { section in
                        CareTapSettingsSectionView(
                            section: section,
                            isLoading: isLoading,
                            onRowTap: onRowTap,
                            onToggle: onToggle
                        )
                    }
                }

                legalSection
            }
            .sheet(item: $presentedLegalPage) { page in
                CareTapLegalDetailView(page: page) {
                    presentedLegalPage = nil
                }
            }
        }
    }

    // MARK: - Profile

    private var profileHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            CareTapAvatarView(profile: state.profile, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(state.profile.displayName)
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(state.hero.title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !state.hero.summary.isEmpty {
                    Text(state.hero.summary)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !statusChips.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statusChips, id: \.title) { chip in
                            statusChip(title: chip.title, value: chip.value)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .padding(16)
        .careTapGlassFill(opacity: 0.6)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
        .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.28)
        .clipShape(RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCard, style: .continuous))
    }

    @ViewBuilder
    private var spotlightSection: some View {
        if let tapKit = tapKitSpotlightRow {
            VStack(alignment: .leading, spacing: 12) {
                CareTapSectionLabel("Highlights")
                    .padding(.horizontal, 4)

                spotlightCard(for: tapKit)
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(CareTapTheme.sage)

            Text("Refreshing settings...")
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(CareTapTheme.warm)

            Text(message)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CareTapTheme.warm.opacity(0.06))
        .careTapLiquidGlass(tint: CareTapTheme.warm.opacity(0.03), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.2)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(CareTapTheme.mist.opacity(0.5))

            Text("No settings available yet")
                .font(CareTapTypography.section)
                .foregroundStyle(CareTapTheme.textPrimary)

            Text("Finish setup to unlock device tools and preferences.")
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            CareTapSectionLabel("Legal & Support")
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(CareTapLegalPage.allCases.enumerated()), id: \.element.id) { index, page in
                    Button { presentedLegalPage = page } label: {
                        HStack(spacing: 12) {
                            Image(systemName: page.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CareTapTheme.textTertiary)
                                .frame(width: 24)

                            Text(page.rawValue)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(CareTapTheme.textTertiary.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if index < CareTapLegalPage.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .careTapGlassFill(opacity: 0.5)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.24)

            Text("v1.0 · TapCare · \(Calendar.current.component(.year, from: .now))")
                .font(.system(size: 10))
                .foregroundStyle(CareTapTheme.textTertiary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    // MARK: - Computed

    private var isLoading: Bool {
        if case .loading = state.loadState { return true }
        return false
    }

    private var errorMessage: String? {
        if case .error(let message) = state.loadState { return message }
        return nil
    }

    private var displaySections: [SettingsSectionState] {
        state.sections.compactMap { section in
            let rows = section.rows.filter { row in
                row.actionKind != .openTapKitShop
            }
            guard !rows.isEmpty else { return nil }
            return SettingsSectionState(id: section.id, title: section.title, footer: section.footer, rows: rows)
        }
    }

    private var tapKitSpotlightRow: SettingsRowState? {
        state.sections
            .flatMap(\.rows)
            .first(where: { $0.actionKind == .openTapKitShop })
    }

    private var statusChips: [(title: String, value: String)] {
        var chips: [(String, String)] = []

        if let reminderRow = state.sections.flatMap(\.rows).first(where: { $0.actionKind == .remindersToggle }) {
            chips.append(("Alerts", reminderRow.subtitle ?? "Off"))
        }

        if let sharingRow = state.sections.flatMap(\.rows).first(where: { $0.actionKind == .sharedAccess }) {
            chips.append(("Sharing", sharingRow.subtitle ?? "Private"))
        }

        return chips
    }

    private func statusChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(value)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CareTapTheme.surfaceMuted.opacity(0.7))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.25), lineWidth: 0.5)
        }
    }

    private func spotlightCard(for row: SettingsRowState) -> some View {
        Button {
            onRowTap(row)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: row.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(row.tone == .alert ? CareTapTheme.alert : row.tone.color)
                    .frame(width: 42, height: 42)
                    .background(
                        (row.tone == .neutral ? CareTapTheme.surfaceMuted : row.tone.color.opacity(0.12)),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .padding(.top, 4)
            }
            .padding(16)
            .careTapGlassFill(opacity: 0.58)
            .careTapLiquidGlass(
                tint: CareTapTheme.warm.opacity(0.04),
                cornerRadius: CareTapSpacing.cornerRadiusCard,
                interactive: true
            )
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.24)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Settings · Loaded") {
    SettingsView(state: CareTapPhaseTwoPreviewScenarios.settingsLoaded)
}

#Preview("Settings · Loading") {
    SettingsView(state: CareTapPhaseTwoPreviewScenarios.settingsLoading)
}

#Preview("Settings · Error") {
    SettingsView(state: CareTapPhaseTwoPreviewScenarios.settingsError)
}
