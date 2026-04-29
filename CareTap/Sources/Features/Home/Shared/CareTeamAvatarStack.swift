import SwiftUI

struct CareTeamAvatarStack: View {
    let initials: [String]
    let totalCount: Int

    var body: some View {
        HStack(spacing: -10) {
            if displayedCount == 0 {
                Circle()
                    .fill(CareTapTheme.surfaceMuted)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CareTapTheme.textSecondary)
                    }
                    .overlay {
                        Circle()
                            .stroke(CareTapTheme.canvas, lineWidth: 2)
                    }
            } else {
                ForEach(Array(displayedValues.enumerated()), id: \.offset) { index, value in
                    let profile = PersonProfile(
                        displayName: value.isEmpty ? "Caregiver" : value,
                        initials: value.isEmpty ? "CG" : value,
                        style: index.isMultiple(of: 2) ? .helper : .caregiver
                    )
                    CareTapAvatarView(profile: profile, size: 32)
                        .overlay {
                            Circle()
                                .stroke(CareTapTheme.canvas, lineWidth: 2)
                        }
                }

                if totalCount > displayedCount {
                    Circle()
                        .fill(CareTapTheme.surface)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("+\(min(totalCount - displayedCount, 99))")
                                .font(.system(size: 11, weight: .semibold, design: .default))
                                .foregroundStyle(CareTapTheme.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 4)
                        }
                        .overlay {
                            Circle()
                                .stroke(CareTapTheme.canvas, lineWidth: 2)
                        }
                }
            }
        }
    }

    private var displayedCount: Int {
        min(totalCount, 3)
    }

    private var displayedValues: [String] {
        if initials.isEmpty {
            return Array(repeating: "", count: displayedCount)
        }

        return Array(initials.prefix(displayedCount))
    }
}
