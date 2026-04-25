import SwiftUI

struct CaregiverSupportView: View {
    let relationships: [CaregiverRelationshipRowState]
    let invitations: [CaregiverInvitationRowState]
    let medicationRows: [PatientMedicationRowState]
    let premiumStatus: CareTapPremiumStatusState
    let inviteCode: String
    var showsHeader: Bool = true
    var settingsState: SettingsViewState? = nil
    var onInviteCodeChanged: (String) -> Void = { _ in }
    var onAcceptInvite: () -> Void = {}
    var onDeclineInvite: () -> Void = {}
    var onSelectCareProfile: (UUID) -> Void = { _ in }
    var onOpenPersonDetail: (CaregiverRelationshipRowState) -> Void = { _ in }
    var onRevokeInvitation: (UUID) -> Void = { _ in }
    var onRevokeRelationship: (UUID) -> Void = { _ in }
    var onMissedDoseAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onRefillAlertsChanged: (UUID, Bool) -> Void = { _, _ in }
    var onSettingsRowTap: (SettingsRowState) -> Void = { _ in }
    var onSettingsToggle: (SettingsRowState, Bool) -> Void = { _, _ in }
    var onOpenPremium: () -> Void = {}
    @State private var draftInviteCode = ""
    @State private var relationshipToRevoke: UUID?
    @State private var invitationToRevoke: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if showsHeader, let settingsState {
                settingsHeader(settingsState)
            }

            connectSection
            peopleSection
            pendingSection
            premiumSummarySection

            if showsHeader, let settingsState {
                preferencesSection(settingsState)
            }
        }
        .onAppear { draftInviteCode = inviteCode }
        .onChange(of: inviteCode) { _, newValue in
            if newValue != draftInviteCode { draftInviteCode = newValue }
        }
        .onChange(of: draftInviteCode) { _, newValue in
            let normalized = newValue.uppercased()
            if normalized != newValue { draftInviteCode = normalized; return }
            onInviteCodeChanged(normalized)
        }
        .confirmationDialog(
            "Remove access",
            isPresented: Binding(get: { relationshipToRevoke != nil }, set: { if !$0 { relationshipToRevoke = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let id = relationshipToRevoke { onRevokeRelationship(id); relationshipToRevoke = nil }
            }
            Button("Cancel", role: .cancel) { relationshipToRevoke = nil }
        } message: {
            Text("This person will lose shared access to check-in updates. You can reconnect later with a new invite code.")
        }
        .confirmationDialog(
            "Revoke invite",
            isPresented: Binding(get: { invitationToRevoke != nil }, set: { if !$0 { invitationToRevoke = nil } }),
            titleVisibility: .visible
        ) {
            Button("Revoke", role: .destructive) {
                if let id = invitationToRevoke { onRevokeInvitation(id); invitationToRevoke = nil }
            }
            Button("Cancel", role: .cancel) { invitationToRevoke = nil }
        } message: {
            Text("This invite code will stop working. You can send a new one afterward.")
        }
    }

    // MARK: - Header

    private func settingsHeader(_ state: SettingsViewState) -> some View {
        HStack(spacing: 14) {
            CareTapAvatarView(profile: state.profile, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.hero.subtitle)
                    .font(CareTapTypography.section)
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text("Sharing & Settings")
                    .font(CareTapTypography.footnote.weight(.medium))
                    .foregroundStyle(CareTapTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Connect

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Connect")

            Text("Enter a shared code to follow someone, receive alerts, and keep their routine visible from Home.")
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                TextField("Invite code", text: $draftInviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(CareTapTypography.section)
                    .padding(14)
                    .careTapGlassFill(opacity: 0.6)
                    .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.04), cornerRadius: 14)
                    .careTapGlassStroke(cornerRadius: 14, opacity: 0.3)

                HStack(spacing: 10) {
                    CareTapPrimaryActionButton(
                        title: "Connect",
                        systemImage: "person.badge.plus",
                        isEnabled: !trimmedInviteCode.isEmpty,
                        action: onAcceptInvite
                    )

                    if !trimmedInviteCode.isEmpty {
                        CareTapSecondaryPillButton(title: "Decline", tone: .warm, action: onDeclineInvite)
                    }
                }
            }
        }
    }

    // MARK: - People

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("People")

            if relationships.isEmpty {
                emptyRow(
                    icon: "person.2",
                    title: "No one linked yet",
                    detail: "Use a shared code above to connect the first person you want to follow."
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(relationships) { r in
                        personTile(r)
                    }
                }
            }
        }
    }

    private func personTile(_ relationship: CaregiverRelationshipRowState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(relationship.lovedOneName)
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(relationship.statusText)
                        .font(CareTapTypography.footnote.weight(.medium))
                        .foregroundStyle(relationship.showsAttention ? CareTapTheme.alert : CareTapTheme.sageStrong)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer()

                if relationship.isSelected {
                    CareTapStatusBadge(text: "Current", tone: .sage)
                }
            }

            if !relationship.permissionTags.isEmpty {
                FlexibleTagRow(tags: relationship.permissionTags)
            }

            Text(relationship.accessLevelTitle)
                .font(CareTapTypography.footnote.weight(.medium))
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(relationship.alertSummary)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)

                    Text(relationship.alertPreferencesText)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: 12) {
                        if !relationship.isSelected {
                            actionLink(title: "Show on Home", tone: CareTapTheme.sageStrong) {
                                onSelectCareProfile(relationship.careProfileID)
                            }
                        }

                        actionLink(title: "Details", tone: CareTapTheme.textSecondary) {
                            onOpenPersonDetail(relationship)
                        }

                        actionLink(title: "Remove", tone: CareTapTheme.alert) {
                            relationshipToRevoke = relationship.id
                        }
                        .accessibilityHint("Removes shared access for this person")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        if !relationship.isSelected {
                            actionLink(title: "Show on Home", tone: CareTapTheme.sageStrong) {
                                onSelectCareProfile(relationship.careProfileID)
                            }
                        }

                        actionLink(title: "Details", tone: CareTapTheme.textSecondary) {
                            onOpenPersonDetail(relationship)
                        }

                        actionLink(title: "Remove", tone: CareTapTheme.alert) {
                            relationshipToRevoke = relationship.id
                        }
                        .accessibilityHint("Removes shared access for this person")
                    }
                }
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: 8) {
                    alertPreferenceChip(
                        title: "Missed dose",
                        isOn: relationship.receivesMissedDoseAlerts
                    ) {
                        onMissedDoseAlertsChanged(relationship.id, !$0)
                    }

                    alertPreferenceChip(
                        title: "Refill",
                        isOn: relationship.receivesRefillAlerts
                    ) {
                        onRefillAlertsChanged(relationship.id, !$0)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    alertPreferenceChip(
                        title: "Missed dose",
                        isOn: relationship.receivesMissedDoseAlerts
                    ) {
                        onMissedDoseAlertsChanged(relationship.id, !$0)
                    }

                    alertPreferenceChip(
                        title: "Refill",
                        isOn: relationship.receivesRefillAlerts
                    ) {
                        onRefillAlertsChanged(relationship.id, !$0)
                    }
                }
            }
        }
        .padding(14)
        .careTapGlassFill(opacity: 0.5)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.25)
    }

    // MARK: - Pending

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Pending")

            if invitations.isEmpty {
                emptyRow(
                    icon: "paperplane",
                    title: "No pending invites",
                    detail: "Any invites you send or share later will stay here until they’re used or revoked."
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(invitations) { inv in
                        invitationTile(inv)
                    }
                }
            }
        }
    }

    private var premiumSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Care Circle")

            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        summaryChip(value: "\(relationships.count)", label: "People")
                        summaryChip(value: "\(activeAlertRelationships)", label: "Alerts")
                        summaryChip(value: "\(pairedMedicationCount)", label: "Tap-ready")
                    }

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            summaryChip(value: "\(relationships.count)", label: "People")
                            summaryChip(value: "\(activeAlertRelationships)", label: "Alerts")
                        }
                        summaryChip(value: "\(pairedMedicationCount)", label: "Tap-ready")
                    }
                }

                premiumSummaryRow(
                    icon: "clock.badge.exclamationmark",
                    text: refillMedicationCount == 0
                        ? "No linked routine currently stands out as a refill risk."
                        : "\(refillMedicationCount) linked item\(refillMedicationCount == 1 ? "" : "s") currently look like they need a refill plan."
                )

                premiumSummaryRow(
                    icon: "bell.badge.fill",
                    text: activeAlertRelationships == 0
                        ? "No one in the care circle currently has attention-heavy alerts turned on."
                        : "\(activeAlertRelationships) shared connection\(activeAlertRelationships == 1 ? "" : "s") currently receive active care alerts."
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .careTapGlassFill(opacity: 0.48)
            .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.025), cornerRadius: 18)
            .careTapGlassStroke(cornerRadius: 18, opacity: 0.22)
        }
    }

    private func invitationTile(_ invitation: CaregiverInvitationRowState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.recipient)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)

                Text(invitation.statusText)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(invitation.inviteCode)
                    .font(CareTapTypography.micro.monospaced())
                    .foregroundStyle(CareTapTheme.sageStrong)

                Button("Revoke") { invitationToRevoke = invitation.id }
                    .buttonStyle(.plain)
                    .font(CareTapTypography.micro)
                    .foregroundStyle(CareTapTheme.alert)
                    .accessibilityHint("Stops this invite code from working")
            }
        }
        .padding(14)
        .careTapGlassFill(opacity: 0.5)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.25)
    }

    // MARK: - Preferences

    private func preferencesSection(_ state: SettingsViewState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Preferences")

            ForEach(state.sections) { section in
                CareTapSettingsSectionView(
                    section: section,
                    onRowTap: onSettingsRowTap,
                    onToggle: onSettingsToggle
                )
            }
        }
    }

    // MARK: - Shared

    private func sectionLabel(_ text: String) -> some View {
        CareTapSectionLabel(text)
    }

    private func emptyRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(CareTapTheme.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text(detail)
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .careTapGlassFill(opacity: 0.4)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.02), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.2)
    }

    private func summaryChip(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(CareTapTypography.section)
                .foregroundStyle(CareTapTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(label)
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.025), cornerRadius: 14)
        .careTapGlassStroke(cornerRadius: 14, opacity: 0.18)
    }

    private var trimmedInviteCode: String {
        draftInviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var activeAlertRelationships: Int {
        relationships.filter { $0.receivesMissedDoseAlerts || $0.receivesRefillAlerts }.count
    }

    private var refillMedicationCount: Int {
        medicationRows.filter(\.hasRefillRisk).count
    }

    private var pairedMedicationCount: Int {
        medicationRows.filter(\.isTagPaired).count
    }

    private func premiumSummaryRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 18)

            Text(text)
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func alertPreferenceChip(title: String, isOn: Bool, action: @escaping (Bool) -> Void) -> some View {
        Button {
            action(isOn)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isOn ? CareTapTheme.sageStrong : CareTapTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .careTapLiquidGlass(
                tint: isOn ? CareTapTheme.sage.opacity(0.08) : CareTapTheme.glassTint.opacity(0.03),
                cornerRadius: 12,
                interactive: true
            )
            .careTapGlassStroke(cornerRadius: 12, opacity: isOn ? 0.3 : 0.18)
        }
        .buttonStyle(.plain)
    }

    private func actionLink(title: String, tone: Color, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(CareTapTypography.footnote.weight(.semibold))
            .foregroundStyle(tone)
    }
}

private struct FlexibleTagRow: View {
    let tags: [String]

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    CareTapStatusBadge(text: tag, tone: .mist)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    CareTapStatusBadge(text: tag, tone: .mist)
                }
            }
        }
    }
}
