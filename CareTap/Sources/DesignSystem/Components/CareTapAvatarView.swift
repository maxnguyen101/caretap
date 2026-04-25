import SwiftUI

struct CareTapAvatarView: View {
    let profile: PersonProfile
    var size: CGFloat = 40
    var isSquare: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarShape
                .fill(backgroundGradient)
                .overlay {
                    Group {
                        if isSquare {
                            Image(systemName: "person.crop.square.fill")
                                .font(.system(size: size * 0.42, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        } else {
                            Text(displayInitials)
                                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
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

    private var backgroundGradient: LinearGradient {
        switch profile.style {
        case .patient:
            return LinearGradient(colors: [CareTapTheme.sageStrong, CareTapTheme.sage], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .caregiver:
            return LinearGradient(colors: [CareTapTheme.success, CareTapTheme.sage], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lovedOne:
            return LinearGradient(colors: [Color(red: 0.13, green: 0.17, blue: 0.20), Color(red: 0.31, green: 0.39, blue: 0.42)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .helper:
            return LinearGradient(colors: [CareTapTheme.warm.opacity(0.8), CareTapTheme.alert.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
