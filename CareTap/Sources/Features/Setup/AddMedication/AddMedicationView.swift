import SwiftUI

struct AddMedicationView: View {
    let state: AddMedicationViewState
    var onClose: () -> Void = {}
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: () -> Void = {}
    var onCategorySelected: (MedicationCategory) -> Void = { _ in }
    var onQueryChange: (String) -> Void = { _ in }
    var onSuggestionSelected: (MedicationSuggestionState) -> Void = { _ in }
    var onTimeSlotSelected: (MedicationTimeSlotState) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var searchQuery = ""
    @State private var pendingSearchTask: Task<Void, Never>?

    var body: some View {
        CareTapFlowScaffold(
            leadingSystemImage: "xmark",
            leadingAccessibilityLabel: "Close setup",
            leadingAction: onClose
        ) {
            VStack(spacing: 22) {
                CareTapSetupProgressHeader(stepText: state.stepText)

                heroSection
                categorySection
                searchSection
                lookupContent
                timingSection
            }
        } footer: {
            CareTapFooterActionBar(
                secondaryTitle: state.secondaryActionTitle,
                primaryTitle: state.primaryActionTitle,
                primarySystemImage: "arrow.right",
                secondaryAction: onSecondaryAction,
                primaryAction: onPrimaryAction
            )
        }
        .onAppear {
            searchQuery = state.searchQuery
        }
        .onChange(of: state.searchQuery) { _, newValue in
            guard newValue != searchQuery else { return }
            searchQuery = newValue
        }
        .onDisappear {
            pendingSearchTask?.cancel()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        CareTapSetupHeroCard(
            title: state.title,
            message: state.message,
            symbolName: iconName(for: state.selectedCategory),
            tone: tone(for: state.selectedCategory),
            highlights: heroHighlights
        )
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CareTapSectionLabel("Type")

            ViewThatFits(in: .vertical) {
                HStack(spacing: 10) {
                    ForEach(MedicationCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(MedicationCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
            }
        }
    }

    // MARK: - Search

    private var searchSection: some View {
        CareTapSearchField(
            placeholder: state.searchPlaceholder,
            query: $searchQuery,
            onChange: queueSearchUpdate
        )
    }

    // MARK: - Lookup

    @ViewBuilder
    private var lookupContent: some View {
        switch state.lookupState {
        case .suggestions(let suggestions):
            VStack(alignment: .leading, spacing: 12) {
                Text(searchQuery.isEmpty ? "Popular picks" : "Matches")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)

                LazyVGrid(columns: medicationColumns, spacing: 10) {
                    ForEach(suggestions) { suggestion in
                        MedicationSuggestionTile(suggestion: suggestion) {
                            selectSuggestion(suggestion)
                        }
                    }
                }
            }
        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                    .tint(CareTapTheme.sage)
                    .scaleEffect(0.8)
                Text("Searching…")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        case .empty(let query):
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(CareTapTheme.textTertiary)
                Text("No match for \"\(query)\"")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Use what you typed and keep going.")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        case .error(let message):
            CareTapInlineBanner(
                icon: "exclamationmark.circle.fill",
                tone: .warm,
                title: "Suggestions unavailable",
                message: "\(message) Enter the name and continue."
            )
        }
    }

    // MARK: - Timing

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CareTapSectionLabel("Typical Times")

            if state.timeSlots.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .foregroundStyle(CareTapTheme.textTertiary)
                    Text("Pick one or more times to start.")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
            } else {
                LazyVGrid(columns: timingColumns, spacing: 10) {
                    ForEach(state.timeSlots) { slot in
                        DailyTimeSelectionTile(slot: slot) {
                            onTimeSlotSelected(slot)
                        }
                    }
                }
            }

            if !selectedTimeTitles.isEmpty {
                Text("Set exact times next.")
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textTertiary)
            }

            guidanceCard
        }
    }

    // MARK: - Helpers

    private var medicationColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: usesSingleColumnLayout ? 1 : 2)
    }

    private var timingColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: usesSingleColumnLayout ? 1 : 2)
    }

    private var selectedTimeTitles: [String] {
        state.timeSlots.filter(\.isSelected).map(\.title)
    }

    private var heroHighlights: [String] {
        [
            state.selectedCategory.title,
            searchQuery.isEmpty ? "Preset suggestions" : "Custom search",
            selectedTimeTitles.isEmpty ? "Choose times" : "\(selectedTimeTitles.count) time\(selectedTimeTitles.count == 1 ? "" : "s")"
        ]
    }

    private var guidanceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CareTapTheme.sageStrong)
                .frame(width: 32, height: 32)
                .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(state.infoTitle)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(state.infoMessage)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer()
        }
        .padding(14)
        .careTapGlassFill(opacity: 0.5)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.22)
    }

    private var usesSingleColumnLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private func queueSearchUpdate(_ value: String) {
        pendingSearchTask?.cancel()
        pendingSearchTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onQueryChange(value)
            }
        }
    }

    private func selectSuggestion(_ suggestion: MedicationSuggestionState) {
        pendingSearchTask?.cancel()
        searchQuery = suggestion.title
        onSuggestionSelected(suggestion)
    }

    private func categoryButton(_ category: MedicationCategory) -> some View {
        let isSelected = state.selectedCategory == category
        return Button {
            onCategorySelected(category)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName(for: category))
                    .font(.system(size: 13, weight: .semibold))
                Text(category.title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .careTapLiquidGlass(
                tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                cornerRadius: 14,
                interactive: true
            )
            .careTapGlassStroke(cornerRadius: 14, opacity: isSelected ? 0.28 : 0.18)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.title)
    }

    private func iconName(for category: MedicationCategory) -> String {
        switch category {
        case .prescription:
            return "cross.case.fill"
        case .otc:
            return "pills.fill"
        case .supplement:
            return "leaf.fill"
        }
    }

    private func tone(for category: MedicationCategory) -> CareTapTone {
        switch category {
        case .prescription:
            return .sage
        case .otc:
            return .warm
        case .supplement:
            return .success
        }
    }
}

#Preview("Add Medication · Default") {
    AddMedicationView(state: CareTapPhaseTwoPreviewScenarios.addMedicationDefault)
}

#Preview("Add Medication · Loading") {
    AddMedicationView(state: CareTapPhaseTwoPreviewScenarios.addMedicationLoading)
}

#Preview("Add Medication · Empty") {
    AddMedicationView(state: CareTapPhaseTwoPreviewScenarios.addMedicationEmpty)
}

#Preview("Add Medication · Error") {
    AddMedicationView(state: CareTapPhaseTwoPreviewScenarios.addMedicationError)
}
