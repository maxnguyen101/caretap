import SwiftUI

struct CaregiverHomeView: View {
    let state: CaregiverHomeState
    var notificationCount: Int = 0
    var onQuickAction: (QuickActionState) -> Void = { _ in }
    var onLinkedPersonSelected: (UUID) -> Void = { _ in }
    var onDestinationSelected: (CareTapDestination) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HomeScreenScaffold(
            profile: state.caregiverProfile,
            selectedDestination: state.selectedDestination,
            unreadNoticeCount: notificationCount,
            onDestinationSelected: onDestinationSelected,
            onNotificationsTap: onNotificationsTap
        ) {
            VStack(spacing: 28) {
                overviewHero
                if state.linkedPeople.count > 1 {
                    peoplePicker
                }
                statusStrip
                quickActions
                recentTimeline
            }
        }
    }

    // MARK: - Overview

    private var overviewHero: some View {
        CareTapCard(style: .elevated) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    CareTapAvatarView(profile: state.lovedOne, size: 64, isSquare: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.lovedOne.displayName)
                            .font(CareTapTypography.hero)
                            .foregroundStyle(CareTapTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        ViewThatFits(in: .vertical) {
                            HStack(spacing: 8) {
                                CareTapStatusBadge(text: alertBadgeText, tone: state.alertLevel.tone)

                                Text(state.alertDetail)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                CareTapStatusBadge(text: alertBadgeText, tone: state.alertLevel.tone)

                                Text(state.alertDetail)
                                    .font(CareTapTypography.footnote)
                                    .foregroundStyle(CareTapTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .layoutPriority(1)

                    Spacer()
                }

                HStack(spacing: 10) {
                    overviewStat(label: "Linked", value: state.householdSummary, icon: "person.2")
                    overviewStat(label: "Circle", value: state.careCircleSummary, icon: "heart.circle")
                }
            }
        }
    }

    private func overviewStat(label: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CareTapTheme.sage)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .careTapGlassFill(opacity: 0.6)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.04), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.25)
    }

    // MARK: - People

    private var peoplePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(state.linkedPeople) { person in
                    Button {
                        CareTapHaptics.selection()
                        onLinkedPersonSelected(person.id)
                    } label: {
                        HStack(spacing: 8) {
                            CareTapAvatarView(
                                profile: PersonProfile(
                                    id: person.id,
                                    displayName: person.displayName,
                                    initials: person.initials,
                                    style: .lovedOne,
                                    showsAlertDot: person.showsAttention
                                ),
                                size: 30
                            )

                            Text(person.displayName)
                                .font(CareTapTypography.footnote.weight(.semibold))
                                .foregroundStyle(person.isSelected ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            if person.isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(CareTapTheme.sageStrong)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .careTapGlassFill(CareTapTheme.sage, opacity: person.isSelected ? 0.08 : 0)
                        .careTapLiquidGlass(
                            tint: person.isSelected ? CareTapTheme.sage.opacity(0.06) : CareTapTheme.glassTint.opacity(0.03),
                            cornerRadius: 20
                        )
                        .overlay {
                            Capsule()
                                .stroke(
                                    person.isSelected ? CareTapTheme.sage.opacity(0.5) : CareTapTheme.stroke.opacity(0.35),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(person.displayName)\(person.isSelected ? ", selected" : "")")
                }
            }
        }
    }

    // MARK: - Status

    private var statusStrip: some View {
        VStack(spacing: 8) {
            ForEach(state.statusCards) { card in
                HStack(spacing: 12) {
                    Circle()
                        .fill(card.tone == .alert ? CareTapTheme.alert : CareTapTheme.sage)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.title)
                            .font(CareTapTypography.footnote.weight(.semibold))
                            .foregroundStyle(CareTapTheme.textTertiary)
                        Text(card.message)
                            .font(CareTapTypography.callout)
                            .foregroundStyle(card.tone == .alert ? CareTapTheme.alert : CareTapTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer()
                }
                .padding(14)
                .careTapGlassFill(opacity: 0.5)
                .careTapLiquidGlass(
                    tint: (card.tone == .alert ? CareTapTheme.alert : CareTapTheme.sage).opacity(0.03),
                    cornerRadius: 14
                )
                .careTapGlassStroke(cornerRadius: 14, opacity: 0.2)
            }
        }
    }

    // MARK: - Actions

    private var quickActions: some View {
        LazyVGrid(columns: actionColumns, spacing: 12) {
            ForEach(state.quickActions) { action in
                CareTapQuickActionButton(
                    title: action.title,
                    systemImage: action.systemImage,
                    tone: action.tone,
                    action: { onQuickAction(action) }
                )
            }
        }
    }

    // MARK: - Timeline

    private var recentTimeline: some View {
        CareTapGlassSection(title: "Recent") {
            VStack(alignment: .leading, spacing: 14) {
                Text(state.timelineDateLabel)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textTertiary)

                LazyVStack(spacing: 0) {
                    ForEach(Array(state.timelineEvents.enumerated()), id: \.element.id) { index, event in
                        HStack(alignment: .top, spacing: 14) {
                            timelineMarker(event: event, isLast: index == state.timelineEvents.count - 1)
                                .frame(width: 20)

                            timelineRow(event)
                                .padding(.bottom, 12)
                        }
                    }
                }
            }
        }
    }

    private func timelineMarker(event: CaregiverTimelineEvent, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(event.status == .completed ? CareTapTheme.success.opacity(0.2) : event.status.tone.color.opacity(0.15))
                .frame(width: 20, height: 20)
                .overlay {
                    Image(systemName: event.status == .completed ? "checkmark" : "circle.fill")
                        .font(.system(size: event.status == .completed ? 8 : 5, weight: .bold))
                        .foregroundStyle(event.status == .completed ? CareTapTheme.success : event.status.tone.color)
                }

            if !isLast {
                Rectangle()
                    .fill(CareTapTheme.separator.opacity(0.3))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private func timelineRow(_ event: CaregiverTimelineEvent) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(event.status == .completed ? CareTapTheme.textTertiary : CareTapTheme.textPrimary)
                    .strikethrough(event.status == .completed)
                    .fixedSize(horizontal: false, vertical: true)

                Text(event.scheduledText)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer()

            Text(event.status.label)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(event.status.tone.color)
        }
    }

    // MARK: - Helpers

    private var alertBadgeText: String {
        switch state.alertLevel {
        case .needsAttention: return "Needs attention"
        case .refillRisk: return "Refill risk"
        case .onTrack: return "On track"
        }
    }

    private var actionColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }
}

#Preview("Caregiver · Attention") {
    CaregiverHomeView(state: CareTapPreviewScenarios.caregiverAttentionNeeded)
}

#Preview("Caregiver · Refill Risk") {
    CaregiverHomeView(state: CareTapPreviewScenarios.caregiverRefillRisk)
}

#Preview("Caregiver · On Track") {
    CaregiverHomeView(state: CareTapPreviewScenarios.caregiverOnTrack)
}
