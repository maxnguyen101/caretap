import SwiftUI

struct CareTapAvatarView: View {
    let profile: PersonProfile
    var size: CGFloat = 40
    var isSquare: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarShape
                .fill(backgroundColor)
                .overlay {
                    Group {
                        if isSquare {
                            Image(systemName: "person.crop.square.fill")
                                .font(.system(size: size * 0.42, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        } else {
                            Text(displayInitials)
                                .font(.system(size: size * 0.34, weight: .semibold, design: .default))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .allowsTightening(true)
                                .frame(maxWidth: size * 0.82)
                        }
                    }
                }
                .overlay {
                    avatarShape
                        .stroke(CareTapTheme.surface.opacity(0.7), lineWidth: isSquare ? 2 : 0)
                }

            if profile.showsAlertDot {
                Circle()
                    .fill(CareTapTheme.alert)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .overlay {
                        Circle()
                            .stroke(CareTapTheme.surface, lineWidth: 2)
                    }
                    .offset(x: isSquare ? 6 : 2, y: isSquare ? 6 : 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(profile.displayName)
    }

    private var displayInitials: String {
        let trimmed = profile.initials.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "?" }
        return String(trimmed.prefix(3)).uppercased()
    }

    private var backgroundColor: Color {
        switch profile.style {
        case .patient:
            return CareTapTheme.sageStrong
        case .caregiver:
            return CareTapTheme.success
        case .lovedOne:
            return Color(red: 0.22, green: 0.26, blue: 0.27)
        case .helper:
            return CareTapTheme.warm
        }
    }

    private var avatarShape: AnyShape {
        if isSquare {
            AnyShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        } else {
            AnyShape(Circle())
        }
    }
}
