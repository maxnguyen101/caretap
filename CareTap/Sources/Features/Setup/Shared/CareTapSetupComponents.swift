import SwiftUI

struct CareTapSetupChecklistItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let isComplete: Bool
}

struct CareTapSetupWalkthroughItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let symbolName: String
}

// MARK: - Hero Card

struct CareTapSetupHeroCard: View {
    let title: String
    let message: String
    let symbolName: String
    var tone: CareTapTone = .sage
    var highlights: [String] = []

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbolName)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(accentColor)

            VStack(spacing: 8) {
                Text(title)
                    .font(CareTapTypography.hero)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !highlights.isEmpty {
                ViewThatFits(in: .vertical) {
                    HStack(spacing: 8) {
                        ForEach(highlights.prefix(3), id: \.self) { highlight in
                            CareTapSetupHighlightPill(text: highlight, tone: tone)
                        }
                    }

                    VStack(spacing: 8) {
                        ForEach(highlights.prefix(3), id: \.self) { highlight in
                            CareTapSetupHighlightPill(text: highlight, tone: tone)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var accentColor: Color {
        tone.accentColor
    }
}

// MARK: - Progress Header

struct CareTapSetupProgressHeader: View {
    let stepText: String
    var title: String = "Setup"

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(capsuleColor(for: index))
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                }
            }

            HStack {
                Text(stepText)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                Spacer()
            }
        }
    }

    private var currentStep: Int {
        let numbers = stepText
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        return max(1, numbers.first ?? 1)
    }

    private var totalSteps: Int {
        let numbers = stepText
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        return max(currentStep, numbers.dropFirst().first ?? 4)
    }

    private func capsuleColor(for index: Int) -> Color {
        if index + 1 < currentStep {
            return CareTapTheme.sage.opacity(0.6)
        }
        if index + 1 == currentStep {
            return CareTapTheme.sageStrong
        }
        return CareTapTheme.surfaceElevated.opacity(0.6)
    }
}

// MARK: - Checklist Card

struct CareTapSetupChecklistCard: View {
    let title: String
    let message: String?
    let items: [CareTapSetupChecklistItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Spacer()

                Text("\(completedCount)/\(items.count)")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 10)
            }

            if let message, !message.isEmpty {
                Text(message)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(item.isComplete ? CareTapTheme.sageStrong : CareTapTheme.textTertiary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !item.detail.isEmpty {
                                Text(item.detail)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .layoutPriority(1)

                        Spacer()
                    }
                    .padding(14)
                    .careTapLiquidGlass(
                        tint: item.isComplete ? CareTapTheme.sage.opacity(0.04) : CareTapTheme.glassTint.opacity(0.02),
                        cornerRadius: 16
                    )
                    .careTapGlassStroke(cornerRadius: 16, opacity: 0.2)
                }
            }
        }
    }

    private var completedCount: Int {
        items.filter(\.isComplete).count
    }
}

// MARK: - Walkthrough Card

struct CareTapSetupWalkthroughCard: View {
    let title: String
    let message: String?
    let items: [CareTapSetupWalkthroughItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(CareTapTypography.bodyStrong)
                .foregroundStyle(CareTapTheme.textPrimary)

            if let message, !message.isEmpty {
                Text(message)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
            }

            VStack(spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(CareTapTheme.sage.opacity(0.1))
                                .frame(width: 32, height: 32)

                            if item.symbolName.isEmpty {
                                Text("\(index + 1)")
                                    .font(CareTapTypography.footnote.weight(.bold))
                                    .foregroundStyle(CareTapTheme.sageStrong)
                            } else {
                                Image(systemName: item.symbolName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(CareTapTheme.sageStrong)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(item.detail)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .layoutPriority(1)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
            }
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: CareTapSpacing.cornerRadiusCard)
            .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCard, opacity: 0.2)
        }
    }
}

// MARK: - Search Field

struct CareTapSearchField: View {
    let placeholder: String
    @Binding var query: String
    var onChange: ((String) -> Void)? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isFocused ? CareTapTheme.sageStrong : CareTapTheme.textTertiary)

            if let onChange {
                TextField(placeholder, text: $query)
                    .font(CareTapTypography.body)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onChange(of: query) { _, newValue in
                        onChange(newValue)
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        onChange("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CareTapTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear medication name")
                }
            } else {
                Text(query.isEmpty ? placeholder : query)
                    .font(CareTapTypography.body)
                    .foregroundStyle(query.isEmpty ? CareTapTheme.textTertiary : CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(
            tint: isFocused ? CareTapTheme.sage.opacity(0.04) : CareTapTheme.glassTint.opacity(0.03),
            cornerRadius: 16
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFocused ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.3), lineWidth: isFocused ? 1.5 : 1)
        }
    }
}

// MARK: - Medication Suggestion Tile

struct MedicationSuggestionTile: View {
    let suggestion: MedicationSuggestionState
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: suggestion.symbolName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconForeground)
                    .frame(width: 36, height: 36)
                    .background(iconBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: 6) {
                            Text(suggestion.subtitle)
                                .font(CareTapTypography.micro)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            categoryPill
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(suggestion.subtitle)
                                .font(CareTapTypography.micro)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            categoryPill
                        }
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 0)
            }
            .padding(12)
            .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
            .careTapGlassStroke(cornerRadius: 16, opacity: 0.2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var iconBackground: Color {
        suggestion.tone.accentColor.opacity(0.12)
    }

    private var iconForeground: Color {
        suggestion.tone.accentColor
    }
}

// MARK: - Time Selection Tile

struct DailyTimeSelectionTile: View {
    let slot: MedicationTimeSlotState
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: slot.symbolName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(slot.isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        slot.isSelected ? CareTapTheme.sage.opacity(0.12) : CareTapTheme.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(spacing: 2) {
                    Text(slot.title)
                        .font(CareTapTypography.footnote.weight(.semibold))
                        .foregroundStyle(slot.isSelected ? CareTapTheme.sageStrong : CareTapTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(slot.timeText)
                        .font(CareTapTypography.micro)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .careTapLiquidGlass(
                tint: slot.isSelected ? CareTapTheme.sage.opacity(0.05) : CareTapTheme.glassTint.opacity(0.02),
                cornerRadius: CareTapSpacing.cornerRadiusCompact
            )
            .overlay {
                RoundedRectangle(cornerRadius: CareTapSpacing.cornerRadiusCompact, style: .continuous)
                    .stroke(
                        slot.isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.25),
                        lineWidth: slot.isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: slot.isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(slot.isSelected ? [.isSelected] : [])
    }
}

// MARK: - Highlight Pill

private struct CareTapSetupHighlightPill: View {
    let text: String
    let tone: CareTapTone

    var body: some View {
        Text(text)
            .font(CareTapTypography.micro)
            .foregroundStyle(CareTapTheme.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .careTapLiquidGlass(tint: tone.accentColor.opacity(0.04), cornerRadius: 10)
            .careTapGlassStroke(cornerRadius: 10, opacity: 0.18)
    }
}

private extension MedicationSuggestionTile {
    var categoryPill: some View {
        Text(suggestion.category.title)
            .font(CareTapTypography.micro)
            .foregroundStyle(suggestion.tone.accentColor)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                suggestion.tone.accentColor.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}

// MARK: - Tone Extension

private extension CareTapTone {
    var accentColor: Color {
        switch self {
        case .sage:
            return CareTapTheme.sage
        case .neutral:
            return CareTapTheme.textSecondary
        case .mist:
            return CareTapTheme.mist
        case .warm:
            return CareTapTheme.warm
        case .alert:
            return CareTapTheme.alert
        case .success:
            return CareTapTheme.success
        }
    }
}
