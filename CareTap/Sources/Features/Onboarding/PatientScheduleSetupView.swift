import PhotosUI
import SwiftUI

@MainActor
struct PatientScheduleSetupView: View {
    let state: ScheduleSetupViewState
    var onBack: () -> Void = {}
    var onContinue: () -> Void = {}
    var onDetailsChanged: (String, String, String, Int) -> Void = { _, _, _, _ in }
    var onStartDateChanged: (Date) -> Void = { _ in }
    var onTimeChanged: (UUID, Date) -> Void = { _, _ in }
    var onAddCustomTime: () -> Void = {}
    var onRemoveTime: (UUID) -> Void = { _ in }
    var onPhotoDataSelected: (Data) -> Void = { _ in }
    var onFrequencyChanged: (ScheduleFrequency) -> Void = { _ in }
    var onIntervalHoursChanged: (Int) -> Void = { _ in }
    var onWeekdayToggled: (Int) -> Void = { _ in }
    var onFoodPreferenceChanged: (Bool?) -> Void = { _ in }
    var onSupplyChanged: (Int, Int) -> Void = { _, _ in }
    var onContainerKindChanged: (ContainerKind) -> Void = { _ in }

    @State private var dosage: String = ""
    @State private var bottleLabel: String = ""
    @State private var instructions: String = ""
    @State private var reminderLeadTime: Int = 0
    @State private var startDate: Date = .now
    @State private var photoItem: PhotosPickerItem?
    @State private var hasLoadedState = false
    @State private var selectedFrequency: ScheduleFrequency = .onceDaily
    @State private var intervalHours: Int = 8
    @State private var selectedWeekdays: [Int] = []
    @State private var takeWithFood: Bool? = nil
    @State private var supplyCount: Int = 30
    @State private var lowSupplyThreshold: Int = 5
    @State private var showsAdvancedOptions = false

    var body: some View {
        CareTapFlowScaffold(
            leadingAction: onBack
        ) {
            VStack(spacing: 28) {
                CareTapSetupProgressHeader(stepText: state.stepText)

                heroSection
                overviewSection
                detailsSection
                timesSection
                reminderSection
                advancedOptionsSection
            }
        } footer: {
            CareTapFooterActionBar(
                secondaryTitle: state.secondaryActionTitle,
                primaryTitle: state.primaryActionTitle,
                primarySystemImage: "arrow.right",
                secondaryAction: onBack,
                primaryAction: onContinue
            )
        }
        .onAppear(perform: loadStateIfNeeded)
        .onChange(of: state.dosage) { _, newValue in
            guard dosage != newValue else { return }
            dosage = newValue
        }
        .onChange(of: state.bottleLabel) { _, newValue in
            guard bottleLabel != newValue else { return }
            bottleLabel = newValue
        }
        .onChange(of: state.instructions) { _, newValue in
            guard instructions != newValue else { return }
            instructions = newValue
        }
        .onChange(of: state.startDate) { _, newValue in
            guard startDate != newValue else { return }
            startDate = newValue
        }
        .onChange(of: state.reminderSummary) { _, newValue in
            let nextValue = reminderLeadTime(from: newValue)
            guard reminderLeadTime != nextValue else { return }
            reminderLeadTime = nextValue
        }
        .onChange(of: state.intervalHours) { _, newValue in
            guard intervalHours != newValue else { return }
            intervalHours = newValue
        }
        .onChange(of: state.selectedWeekdays) { _, newValue in
            guard selectedWeekdays != newValue else { return }
            selectedWeekdays = newValue
        }
        .onChange(of: dosage) { _, _ in commitDetails() }
        .onChange(of: bottleLabel) { _, _ in commitDetails() }
        .onChange(of: instructions) { _, _ in commitDetails() }
        .onChange(of: reminderLeadTime) { _, _ in commitDetails() }
        .onChange(of: startDate) { _, newValue in
            onStartDateChanged(newValue)
        }
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    onPhotoDataSelected(data)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text(state.title)
                .font(CareTapTypography.hero)
                .foregroundStyle(CareTapTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(state.message)
                .font(CareTapTypography.callout)
                .foregroundStyle(CareTapTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var overviewSection: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 10) {
                summaryChip(icon: categorySymbolName, text: state.category.title)
                summaryChip(icon: state.containerKind.symbolName, text: state.containerKind.title)
                summaryChip(
                    icon: "clock.fill",
                    text: "\(state.selectedTimes.count) time\(state.selectedTimes.count == 1 ? "" : "s")"
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    summaryChip(icon: categorySymbolName, text: state.category.title)
                    summaryChip(icon: state.containerKind.symbolName, text: state.containerKind.title)
                }
                summaryChip(
                    icon: "clock.fill",
                    text: "\(state.selectedTimes.count) time\(state.selectedTimes.count == 1 ? "" : "s")"
                )
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Routine details")

            glassField(title: "Item", text: .constant(state.medicationName), isEditable: false)
            containerSelector
            glassField(title: state.dosageTitle, text: $dosage)
            glassField(title: state.containerTitle, text: $bottleLabel)
            glassField(title: state.notesTitle, text: $instructions, axis: .vertical)

            DatePicker("Starts on", selection: $startDate, displayedComponents: .date)
                .font(CareTapTypography.callout)
                .tint(CareTapTheme.sage)
                .padding(14)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
                .careTapGlassStroke(cornerRadius: 16, opacity: 0.2)
        }
    }

    private var containerSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Container")
                .font(CareTapTypography.footnote.weight(.medium))
                .foregroundStyle(CareTapTheme.textSecondary)

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    ForEach(ContainerKind.allCases, id: \.self) { kind in
                        containerChip(kind)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ContainerKind.allCases, id: \.self) { kind in
                        containerChip(kind)
                    }
                }
            }
        }
    }

    // MARK: - Times

    private var timesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("Exact times")
                Spacer()
                Button {
                    CareTapInteraction.dismissKeyboard()
                    onAddCustomTime()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add exact time")
                            .font(CareTapTypography.footnote.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(CareTapTheme.sageStrong)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.06), cornerRadius: 12, interactive: true)
                    .careTapGlassStroke(cornerRadius: 12, opacity: 0.25)
                }
                .buttonStyle(.plain)
            }

            Text(state.timingHelperText)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(state.selectedTimes) { time in
                HStack(spacing: 14) {
                    Image(systemName: time.symbolName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CareTapTheme.sageStrong)
                        .frame(width: 36, height: 36)
                        .background(CareTapTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(time.title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Spacer()

                    DatePicker(
                        time.title,
                        selection: Binding(
                            get: {
                                Calendar.current.date(
                                    from: DateComponents(hour: time.hour, minute: time.minute)
                                ) ?? .now
                            },
                            set: { newValue in
                                onTimeChanged(time.id, newValue)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(CareTapTheme.sage)

                    if state.selectedTimes.count > 1 {
                        Button {
                            CareTapInteraction.dismissKeyboard()
                            onRemoveTime(time.id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(CareTapTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(time.title)")
                    }
                }
                .padding(12)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
                .careTapGlassStroke(cornerRadius: 16, opacity: 0.2)
            }
        }
    }

    private var advancedOptionsSection: some View {
        DisclosureGroup(isExpanded: $showsAdvancedOptions) {
            VStack(spacing: 24) {
                frequencySection
                advancedScheduleSection
                foodPreferenceSection
                supplySection
                photoSection
            }
            .padding(.top, 14)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("More options")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Food, refill watch, container photo, and alternate schedule styles.")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .tint(CareTapTheme.sageStrong)
        .padding(16)
        .careTapGlassFill(opacity: 0.55)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 18)
        .careTapGlassStroke(cornerRadius: 18, opacity: 0.24)
    }

    private var advancedScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch selectedFrequency {
            case .everyXHours:
                sectionLabel("Interval")

                HStack {
                    Text("Repeat every \(intervalHours) hours")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                    Spacer()
                    Stepper("", value: $intervalHours, in: 1...24)
                        .labelsHidden()
                        .tint(CareTapTheme.sage)
                }
                .padding(14)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
                .careTapGlassStroke(cornerRadius: 16, opacity: 0.2)
                .onChange(of: intervalHours) { _, newValue in
                    onIntervalHoursChanged(newValue)
                }

            case .specificWeekdays:
                sectionLabel("Days")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(weekdayOptions, id: \.value) { weekday in
                        weekdayChip(title: weekday.title, value: weekday.value)
                    }
                }

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Reminders")

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    ForEach(reminderChoices, id: \.minutes) { choice in
                        reminderChip(choice)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(reminderChoices, id: \.minutes) { choice in
                        reminderChip(choice)
                    }
                }
            }

            Text(state.reminderSummary)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(state.photoSectionTitle)

            photoPickerRow
        }
    }

    private var photoPickerRow: some View {
        let hasBottlePhoto = state.hasBottlePhoto
        return PhotosPicker(selection: $photoItem, matching: .images) {
            HStack(spacing: 14) {
                Image(systemName: hasBottlePhoto ? "checkmark.circle.fill" : "camera")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(hasBottlePhoto ? CareTapTheme.success : CareTapTheme.sageStrong)
                    .frame(width: 40, height: 40)
                    .background(
                        (hasBottlePhoto ? CareTapTheme.success : CareTapTheme.sage).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(hasBottlePhoto ? "Photo saved" : "Add a photo")
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                    Text(hasBottlePhoto ? "Tap to replace" : "Optional \u{2014} helps identify the container")
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(CareTapTheme.surface.opacity(0.22))
                    }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CareTapTheme.stroke.opacity(0.24), lineWidth: 1)
            }
        }
    }

    // MARK: - Frequency

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Schedule")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ScheduleFrequency.allCases, id: \.self) { freq in
                    let isSelected = selectedFrequency == freq
                    Button {
                        selectedFrequency = freq
                        onFrequencyChanged(freq)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: freq.symbolName)
                                .font(.system(size: 14, weight: .medium))
                            Text(freq.displayTitle)
                                .font(CareTapTypography.footnote.weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .careTapLiquidGlass(
                            tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                            cornerRadius: 14
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.2),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Food Preference

    private var foodPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Food")

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    foodChip(label: "No preference", value: nil)
                    foodChip(label: "With food", value: true)
                    foodChip(label: "Empty stomach", value: false)
                }

                VStack(spacing: 8) {
                    foodChip(label: "No preference", value: nil)
                    foodChip(label: "With food", value: true)
                    foodChip(label: "Empty stomach", value: false)
                }
            }
        }
    }

    private func foodChip(label: String, value: Bool?) -> some View {
        let isSelected = takeWithFood == value
        return Button {
            takeWithFood = value
            onFoodPreferenceChanged(value)
        } label: {
            Text(label)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .careTapLiquidGlass(
                    tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                    cornerRadius: 14
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Supply

    private var supplySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Supply")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quantity on hand")
                        .font(CareTapTypography.footnote.weight(.medium))
                        .foregroundStyle(CareTapTheme.textSecondary)
                    Stepper("\(supplyCount) doses", value: $supplyCount, in: 1...999)
                        .font(CareTapTypography.callout)
                }
                .padding(14)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 14)
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.2)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Low supply alert at")
                        .font(CareTapTypography.footnote.weight(.medium))
                        .foregroundStyle(CareTapTheme.textSecondary)
                    Stepper("\(lowSupplyThreshold) doses left", value: $lowSupplyThreshold, in: 1...99)
                        .font(CareTapTypography.callout)
                }
                .padding(14)
                .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 14)
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.2)
            }
        }
        .onChange(of: supplyCount) { _, _ in onSupplyChanged(supplyCount, lowSupplyThreshold) }
        .onChange(of: lowSupplyThreshold) { _, _ in onSupplyChanged(supplyCount, lowSupplyThreshold) }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        CareTapSectionLabel(text)
    }

    private func summaryChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(CareTapTypography.micro.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(CareTapTheme.sageStrong)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.06), cornerRadius: 12)
        .careTapGlassStroke(cornerRadius: 12, opacity: 0.22)
    }

    @ViewBuilder
    private func glassField(title: String, text: Binding<String>, isEditable: Bool = true, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(CareTapTypography.footnote.weight(.medium))
                .foregroundStyle(CareTapTheme.textSecondary)

            if isEditable {
                TextField(title, text: text, axis: axis)
                    .font(CareTapTypography.body)
                    .textInputAutocapitalization(axis == .vertical ? .sentences : .words)
                    .autocorrectionDisabled(axis == .horizontal)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(CareTapTheme.stroke.opacity(0.25), lineWidth: 1)
                    }
            } else {
                Text(text.wrappedValue)
                    .font(CareTapTypography.body)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
            }
        }
    }

    private func reminderChip(_ choice: (minutes: Int, title: String)) -> some View {
        let isSelected = reminderLeadTime == choice.minutes

        return Button {
            reminderLeadTime = choice.minutes
        } label: {
            Text(choice.title)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .careTapLiquidGlass(
                    tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                    cornerRadius: 14
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }

    private func containerChip(_ kind: ContainerKind) -> some View {
        let isSelected = state.containerKind == kind

        return Button {
            onContainerKindChanged(kind)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: kind.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                Text(kind.title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .careTapLiquidGlass(
                tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                cornerRadius: 14
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.2),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var reminderChoices: [(minutes: Int, title: String)] {
        [
            (0, "On time"),
            (10, "10 min"),
            (20, "20 min"),
            (30, "30 min")
        ]
    }

    private func commitDetails() {
        onDetailsChanged(dosage, bottleLabel, instructions, reminderLeadTime)
    }

    private func loadStateIfNeeded() {
        guard !hasLoadedState else { return }
        dosage = state.dosage
        bottleLabel = state.bottleLabel
        instructions = state.instructions
        startDate = state.startDate
        reminderLeadTime = reminderLeadTime(from: state.reminderSummary)
        selectedFrequency = state.scheduleFrequency
        intervalHours = state.intervalHours
        selectedWeekdays = state.selectedWeekdays
        takeWithFood = state.takeWithFood
        supplyCount = state.supplyCount
        lowSupplyThreshold = state.lowSupplyThreshold
        hasLoadedState = true
    }

    private func reminderLeadTime(from summary: String) -> Int {
        if summary.contains("30 minutes") {
            return 30
        }
        if summary.contains("20 minutes") {
            return 20
        }
        if summary.contains("10 minutes") {
            return 10
        }
        return 0
    }

    private var weekdayOptions: [(value: Int, title: String)] {
        [
            (1, "Sun"),
            (2, "Mon"),
            (3, "Tue"),
            (4, "Wed"),
            (5, "Thu"),
            (6, "Fri"),
            (7, "Sat")
        ]
    }

    private func weekdayChip(title: String, value: Int) -> some View {
        let isSelected = selectedWeekdays.contains(value)

        return Button {
            if let index = selectedWeekdays.firstIndex(of: value) {
                if selectedWeekdays.count > 1 {
                    selectedWeekdays.remove(at: index)
                }
            } else {
                selectedWeekdays.append(value)
                selectedWeekdays.sort()
            }
            onWeekdayToggled(value)
        } label: {
            Text(title)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .careTapLiquidGlass(
                    tint: isSelected ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                    cornerRadius: 14
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    private var categorySymbolName: String {
        switch state.category {
        case .prescription:
            return "cross.case.fill"
        case .otc:
            return "pills.fill"
        case .supplement:
            return "leaf.fill"
        }
    }
}
