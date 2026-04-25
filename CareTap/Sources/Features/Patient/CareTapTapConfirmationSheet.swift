import SwiftUI

/// Rich, tactile confirmation sheet shown after an NFC tap (or a manual tap
/// routed through the same flow). Replaces the tiny banner-only feedback so the
/// day-to-day tap loop feels like a confident Apple-style acknowledgement.
struct CareTapTapConfirmationSheet: View {
    let state: NFCTapConfirmationState
    var onDismiss: () -> Void = {}
    var onLogAnyway: () -> Void = {}
    var onLogOutsideWindow: () -> Void = {}
    var onReviewHistory: () -> Void = {}
    var onSetupAutomation: () -> Void = {}

    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        ZStack {
            CareTapTheme.canvas.ignoresSafeArea()
            CareTapScreenBackground().opacity(0.9)

            ScrollView {
                VStack(spacing: 20) {
                    heroHeader
                    detailCard
                    actions

                    if showsAutomationHint {
                        automationHintCard
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .presentationCornerRadius(32)
        .onAppear(perform: playHaptic)
    }

    // MARK: - Hero

    private var heroHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tone.color.opacity(0.18))
                    .frame(width: 120, height: 120)
                    .blur(radius: 6)
                Circle()
                    .stroke(tone.color.opacity(0.45), lineWidth: 1)
                    .frame(width: 104, height: 104)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(tone.color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(CareTapTypography.title)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(CareTapTypography.callout)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Detail card

    @ViewBuilder
    private var detailCard: some View {
        switch state.outcome {
        case .logged(let details):
            loggedDetailCard(details)
        case .alreadyLogged(let details):
            duplicateDetailCard(details)
        case .tooEarly(let details):
            timingDetailCard(details)
        case .noActiveDose(let details):
            idleDetailCard(details)
        case .unknownTag:
            EmptyView()
        }
    }

    private func loggedDetailCard(_ details: NFCTapConfirmationState.LoggedDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            medicationRow(name: details.medicationName, dosage: details.dosage)

            divider

            detailRow(
                icon: "clock.fill",
                label: "Logged",
                value: relativeTime(from: details.loggedAt)
            )

            if let nextDose = details.nextDoseLabel {
                detailRow(
                    icon: "calendar.badge.clock",
                    label: "Next dose",
                    value: nextDose
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.6)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.04), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
    }

    private func duplicateDetailCard(_ details: NFCTapConfirmationState.DuplicateDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            medicationRow(name: details.medicationName, dosage: details.dosage)

            divider

            detailRow(
                icon: "checkmark.seal.fill",
                label: "Last logged",
                value: relativeDescription(minutesAgo: details.minutesAgo, from: details.previousLoggedAt)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Was this a second dose?")
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text("If you just confirmed this already, you can keep the first log as-is. Tap Log anyway only when this really is another dose.")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.6)
        .careTapLiquidGlass(tint: CareTapTheme.warm.opacity(0.04), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
    }

    private func timingDetailCard(_ details: NFCTapConfirmationState.TimingDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            medicationRow(name: details.medicationName, dosage: details.dosage)

            divider

            detailRow(
                icon: "hourglass",
                label: "Window opens",
                value: details.windowOpensAt.formatted(date: .omitted, time: .shortened)
            )

            Text("TapCare waits for the scheduled window so the log stays accurate. You can still mark it as taken if you're confident about the time.")
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.6)
        .careTapLiquidGlass(tint: CareTapTheme.warm.opacity(0.04), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.28)
    }

    private func idleDetailCard(_ details: NFCTapConfirmationState.IdleDetails) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            medicationRow(name: details.medicationName, dosage: details.dosage)

            divider

            if let next = details.nextScheduledAt {
                detailRow(
                    icon: "calendar.badge.clock",
                    label: "Next scheduled",
                    value: next.formatted(date: .abbreviated, time: .shortened)
                )
            } else {
                detailRow(
                    icon: "sparkles",
                    label: "Schedule",
                    value: "No recurring schedule"
                )
            }

            Text("This is a safe moment to log an off-schedule dose if you took it — TapCare will tag the entry as outside the usual routine.")
                .font(CareTapTypography.footnote)
                .foregroundStyle(CareTapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapGlassFill(opacity: 0.55)
        .careTapLiquidGlass(tint: CareTapTheme.glassTint.opacity(0.03), cornerRadius: 22)
        .careTapGlassStroke(cornerRadius: 22, opacity: 0.22)
    }

    // MARK: - Actions

    @ViewBuilder
    private var actions: some View {
        switch state.outcome {
        case .logged:
            primaryButton(title: "Done", icon: "checkmark") { dismissAll() }
            secondaryButton(title: "See History", icon: "clock.arrow.circlepath") {
                onReviewHistory()
                dismissAll()
            }
        case .alreadyLogged:
            primaryButton(title: "Keep first log", icon: "lock.fill") { dismissAll() }
            secondaryButton(title: "Log anyway (new dose)", icon: "plus.circle.fill") {
                onLogAnyway()
                dismissAll()
            }
        case .tooEarly:
            primaryButton(title: "Wait for window", icon: "hourglass") { dismissAll() }
            secondaryButton(title: "Mark as taken now", icon: "checkmark.circle.fill") {
                onLogOutsideWindow()
                dismissAll()
            }
        case .noActiveDose:
            primaryButton(title: "Log as taken", icon: "checkmark.circle.fill") {
                onLogOutsideWindow()
                dismissAll()
            }
            secondaryButton(title: "Not now", icon: "xmark") { dismissAll() }
        case .unknownTag:
            primaryButton(title: "Close", icon: "xmark") { dismissAll() }
        }
    }

    // MARK: - Automation hint

    private var showsAutomationHint: Bool {
        guard state.isNFCSource else { return false }
        switch state.outcome {
        case .logged(let details): return !details.isAutomationConfigured
        default: return false
        }
    }

    private var automationHintCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(CareTapTheme.sageStrong)
                .frame(width: 34, height: 34)
                .background(CareTapTheme.sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Make tapping even faster")
                    .font(CareTapTypography.footnote.weight(.semibold))
                    .foregroundStyle(CareTapTheme.textPrimary)
                Text("Add the TapCare Shortcuts automation so a bottle tap logs without opening the app.")
                    .font(CareTapTypography.footnote)
                    .foregroundStyle(CareTapTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Set up automation") {
                    onSetupAutomation()
                    dismissAll()
                }
                .buttonStyle(.plain)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.sageStrong)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .careTapLiquidGlass(tint: CareTapTheme.sage.opacity(0.03), cornerRadius: 16)
        .careTapGlassStroke(cornerRadius: 16, opacity: 0.22)
    }

    // MARK: - Building blocks

    private func medicationRow(name: String, dosage: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tone.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "pills.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tone.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !dosage.isEmpty {
                    Text(dosage)
                        .font(CareTapTypography.footnote)
                        .foregroundStyle(CareTapTheme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CareTapTheme.textTertiary)
                .frame(width: 20)
            Text(label)
                .font(CareTapTypography.footnote.weight(.medium))
                .foregroundStyle(CareTapTheme.textTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(CareTapTypography.footnote.weight(.semibold))
                .foregroundStyle(CareTapTheme.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(CareTapTheme.separator.opacity(0.35))
            .frame(height: 1)
    }

    private func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tone.color, tone.strongColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(color: tone.color.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .buttonStyle(CareTapPressableButtonStyle())
    }

    private func secondaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CareTapTheme.textSecondary)
                Text(title)
                    .font(CareTapTypography.bodyStrong)
                    .foregroundStyle(CareTapTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .careTapLiquidGlass(
                tint: CareTapTheme.glassTint.opacity(0.04),
                cornerRadius: 16,
                interactive: true
            )
            .careTapGlassStroke(cornerRadius: 16, opacity: 0.22)
        }
        .buttonStyle(CareTapPressableButtonStyle())
    }

    // MARK: - Tone & copy

    private struct TonePalette {
        let color: Color
        let strongColor: Color
    }

    private var tone: TonePalette {
        switch state.outcome {
        case .logged:
            return TonePalette(color: CareTapTheme.sage, strongColor: CareTapTheme.sageStrong)
        case .alreadyLogged, .tooEarly, .noActiveDose:
            return TonePalette(color: CareTapTheme.warm, strongColor: CareTapTheme.warm)
        case .unknownTag:
            return TonePalette(color: CareTapTheme.alert, strongColor: CareTapTheme.alert)
        }
    }

    private var icon: String {
        switch state.outcome {
        case .logged: return "checkmark.seal.fill"
        case .alreadyLogged: return "clock.badge.checkmark.fill"
        case .tooEarly: return "hourglass"
        case .noActiveDose: return "sparkles"
        case .unknownTag: return "questionmark.circle.fill"
        }
    }

    private var title: String {
        switch state.outcome {
        case .logged: return "Dose logged"
        case .alreadyLogged(let details):
            return "Already logged \(minutesAgoPhrase(details.minutesAgo))"
        case .tooEarly: return "A little early"
        case .noActiveDose: return "Off-schedule tap"
        case .unknownTag: return "Tag not recognized"
        }
    }

    private var subtitle: String {
        switch state.outcome {
        case .logged(let details):
            return state.isNFCSource
                ? "Tap registered from the bottle for \(details.medicationName)."
                : "Confirmed \(details.medicationName) manually."
        case .alreadyLogged(let details):
            return "You confirmed \(details.medicationName) recently. Keep the first log or mark this as a brand new dose."
        case .tooEarly(let details):
            return "This tap arrived before the \(details.medicationName) window opens."
        case .noActiveDose(let details):
            return "No scheduled dose for \(details.medicationName) is open right now."
        case .unknownTag(let details):
            return details.message
        }
    }

    // MARK: - Helpers

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func relativeDescription(minutesAgo: Int, from date: Date) -> String {
        if minutesAgo <= 0 {
            return "Just now · \(date.formatted(date: .omitted, time: .shortened))"
        }
        if minutesAgo == 1 {
            return "1 min ago · \(date.formatted(date: .omitted, time: .shortened))"
        }
        if minutesAgo < 60 {
            return "\(minutesAgo) min ago · \(date.formatted(date: .omitted, time: .shortened))"
        }
        let hours = minutesAgo / 60
        return "\(hours)h ago · \(date.formatted(date: .omitted, time: .shortened))"
    }

    private func minutesAgoPhrase(_ minutes: Int) -> String {
        if minutes <= 0 { return "just now" }
        if minutes == 1 { return "1 minute ago" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
    }

    private func dismissAll() {
        onDismiss()
        dismissSheet()
    }

    private func playHaptic() {
        switch state.outcome {
        case .logged:
            CareTapHaptics.success()
        case .alreadyLogged, .tooEarly, .noActiveDose:
            CareTapHaptics.warning()
        case .unknownTag:
            CareTapHaptics.error()
        }
    }
}
