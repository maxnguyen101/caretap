import SwiftUI

struct CareTapSettingsSectionView: View {
    let section: SettingsSectionState
    var isLoading: Bool = false
    var onRowTap: (SettingsRowState) -> Void = { _ in }
    var onToggle: (SettingsRowState, Bool) -> Void = { _, _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CareTapSectionLabel(section.title)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    CareTapSettingsRowView(
                        row: row,
                        onTap: { onRowTap(row) },
                        onToggle: { onToggle(row, $0) }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .opacity(isLoading ? 0.55 : 1)
                    .redacted(reason: isLoading ? .placeholder : [])
                    .allowsHitTesting(!isLoading)

                    if index < section.rows.count - 1 {
                        Divider()
                            .overlay(CareTapTheme.separator.opacity(0.35))
                            .padding(.leading, 62)
                    }
                }
            }
            .careTapGlassFill(opacity: 0.6)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 18)
            .careTapGlassStroke(cornerRadius: 18, opacity: 0.25)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let footer = section.footer {
                Text(footer)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct CareTapSettingsRowView: View {
    let row: SettingsRowState
    var onTap: () -> Void = {}
    var onToggle: (Bool) -> Void = { _ in }

    var body: some View {
        Group {
            if case .toggle(let isOn) = row.accessory {
                toggleRowContent(isOn: isOn)
            } else if row.isInteractive {
                Button {
                    CareTapInteraction.dismissKeyboard()
                    onTap()
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                rowContent
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func toggleRowContent(isOn: Bool) -> some View {
        HStack(spacing: 14) {
            Button {
                CareTapInteraction.dismissKeyboard()
                onToggle(!isOn)
            } label: {
                HStack(spacing: 14) {
                    iconView

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(CareTapTypography.body)
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
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: Binding(get: { isOn }, set: { onToggle($0) }))
                .labelsHidden()
                .tint(CareTapTheme.sageStrong)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(CareTapTypography.body)
                    .foregroundStyle(row.tone == .alert ? CareTapTheme.alert : CareTapTheme.textPrimary)
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

            accessoryView
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var iconView: some View {
        Image(systemName: row.symbolName)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(row.tone == .alert ? CareTapTheme.alert : row.tone.color)
            .frame(width: 30, height: 30)
            .background(
                (row.tone == .neutral ? CareTapTheme.surfaceMuted : row.tone.color.opacity(0.1)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch row.accessory {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
        case .toggle:
            EmptyView()
        case .label(let text):
            Text(text)
                .font(CareTapTypography.footnote.weight(.medium))
                .foregroundStyle(CareTapTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
                .frame(maxWidth: 120, alignment: .trailing)
        case .none:
            EmptyView()
        }
    }
}

private extension SettingsRowState {
    var isInteractive: Bool {
        if case .none = accessory {
            return actionKind != nil
        }
        return true
    }
}
