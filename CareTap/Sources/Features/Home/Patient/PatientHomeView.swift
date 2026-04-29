import SwiftUI

struct PatientHomeView: View {
    let state: PatientHomeState
    var notificationCount: Int = 0
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: (SecondaryActionState) -> Void = { _ in }
    var onDestinationSelected: (CareTapDestination) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}

    var body: some View {
        HomeScreenScaffold(
            profile: state.profile,
            selectedDestination: state.selectedDestination,
            unreadNoticeCount: notificationCount,
            onDestinationSelected: onDestinationSelected,
            onNotificationsTap: onNotificationsTap
        ) {
            VStack(spacing: 18) {
                PatientHomeHeroCard(
                    greetingText: greetingText,
                    currentDose: state.currentDose,
                    focusTint: focusTint,
                    onPrimaryAction: onPrimaryAction,
                    onSecondaryAction: onSecondaryAction
                )
                .careTapCardEntrance(delay: 0.05)

                PatientHomeSnapshotRow(
                    progress: state.progress,
                    upcomingMedication: state.upcomingMedication
                )
                .careTapCardEntrance(delay: 0.15)

                if !state.upcomingItems.isEmpty {
                    PatientUpcomingSection(items: state.upcomingItems)
                        .careTapCardEntrance(delay: 0.25)
                }

                if state.careTeamBanner.memberCount > 0 {
                    PatientCareTeamSection(banner: state.careTeamBanner)
                        .careTapCardEntrance(delay: 0.35)
                }
            }
        }
    }

    private var focusTint: Color {
        state.currentDose.focusState.tone.color
    }

    private var greetingText: String {
        let firstName = state.profile.displayName
            .split(separator: " ")
            .first
            .map(String.init) ?? state.profile.displayName

        let hour = Calendar.current.component(.hour, from: .now)
        let timeOfDay: String
        switch hour {
        case 0..<5: timeOfDay = "Late night"
        case 5..<12: timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        default: timeOfDay = "Good evening"
        }

        return "\(timeOfDay), \(firstName)"
    }
}

private struct PatientHomeHeroCard: View {
    let greetingText: String
    let currentDose: PatientDoseCardState
    let focusTint: Color
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: (SecondaryActionState) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 10) {
            // Greeting text sits above the card, not inside
            HStack {
                Text(greetingText)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textSecondary)
                Spacer()
            }

            CareTapCard(style: cardStyle) {
                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        CareTapMedicationPhotoView(
                            photoPath: currentDose.bottlePhotoLocalPath,
                            title: currentDose.medicationName,
                            size: CGSize(width: 48, height: 64)
                        )

                        VStack(alignment: .leading, spacing: 5) {
                            ViewThatFits(in: .vertical) {
                                HStack(alignment: .center, spacing: 6) {
                                    CareTapStatusBadge(text: currentDose.focusState.chipText, tone: currentDose.focusState.tone)
                                    Text(currentDose.scheduledText)
                                        .font(CareTapTypography.footnote)
                                        .foregroundStyle(CareTapTheme.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    CareTapStatusBadge(text: currentDose.focusState.chipText, tone: currentDose.focusState.tone)
                                    Text(currentDose.scheduledText)
                                        .font(CareTapTypography.footnote)
                                        .foregroundStyle(CareTapTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Text(currentDose.focusState.heroTitle)
                                .font(.system(size: 21, weight: .semibold, design: .default))
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(currentDose.medicationName)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // No ViewThatFits here — alternate branches can leave ghosted glass; one column + compositingGroup keeps layers clean.
                    VStack(spacing: 10) {
                        CareTapPrimaryActionButton(
                            title: currentDose.primaryActionTitle,
                            systemImage: currentDose.primaryActionSymbol,
                            action: onPrimaryAction
                        )

                        if !currentDose.secondaryActions.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(currentDose.secondaryActions) { action in
                                    CareTapSecondaryPillButton(title: action.title, tone: action.tone) {
                                        onSecondaryAction(action)
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .compositingGroup()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(currentDose.medicationName), \(currentDose.focusState.chipText)")
    }

    private var cardStyle: CareTapCardStyle {
        currentDose.focusState == .completed ? .completed : .elevated
    }
}

private struct PatientHomeSnapshotRow: View {
    let progress: DailyProgress
    let upcomingMedication: UpcomingMedicationState

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 12) {
                progressCard
                nextCard
            }

            VStack(spacing: 12) {
                progressCard
                nextCard
            }
        }
    }

    private var progressCard: some View {
        CareTapCard(style: .muted) {
            HStack(spacing: 10) {
                CareTapProgressRing(fraction: progress.fractionComplete, size: 44, lineWidth: 5)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Today")
                        .font(CareTapTypography.footnote.weight(.semibold))
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .lineLimit(1)
                    Text(progressValue)
                        .font(CareTapTypography.section)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(progressSummary)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var nextCard: some View {
        CareTapCard(style: .muted) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(CareTapTheme.sage)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Up next")
                        .font(CareTapTypography.footnote.weight(.semibold))
                        .foregroundStyle(CareTapTheme.textTertiary)
                    Text(upcomingMedication.timeText)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(upcomingMedication.title)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progressSummary: String {
        if progress.totalCount == 0 {
            return "Nothing due"
        }

        return "Logged today"
    }

    private var progressValue: String {
        if progress.totalCount == 0 {
            return "Clear"
        }

        return "\(progress.completedCount)/\(progress.totalCount)"
    }
}

private struct PatientUpcomingSection: View {
    let items: [UpcomingMedicationState]

    var body: some View {
        CareTapGlassSection(title: "Later Today") {
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CareTapTheme.textTertiary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(CareTapTypography.bodyStrong)
                                .foregroundStyle(CareTapTheme.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.contextLabel)
                                .font(CareTapTypography.footnote)
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(item.timeText)
                            .font(CareTapTypography.footnote.weight(.semibold))
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 0, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .careTapLiquidGlass(
                        tint: CareTapTheme.glassTint.opacity(0.02),
                        cornerRadius: CareTapSpacing.cornerRadiusCompact
                    )
                    .careTapGlassStroke(cornerRadius: CareTapSpacing.cornerRadiusCompact, opacity: 0.18)
                    .careTapStaggeredEntry(index: index, baseDelay: 0.3)
                }
            }
        }
    }
}

private struct PatientCareTeamSection: View {
    let banner: CareTeamBannerState

    var body: some View {
        CareTapGlassSection(title: "Care Circle") {
            HStack(spacing: 14) {
                CareTeamAvatarStack(
                    initials: banner.memberInitials,
                    totalCount: banner.memberCount
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(banner.title)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)

                    if !banner.message.isEmpty {
                        Text(banner.message)
                            .font(CareTapTypography.footnote)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview("Patient · Due Now") {
    PatientHomeView(state: CareTapPreviewScenarios.patientDueNow)
}

#Preview("Patient · Snoozed") {
    PatientHomeView(state: CareTapPreviewScenarios.patientSnoozed)
}

#Preview("Patient · Completed") {
    PatientHomeView(state: CareTapPreviewScenarios.patientCompleted)
}
