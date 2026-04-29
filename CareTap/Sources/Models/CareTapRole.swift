import Foundation

enum CareTapRole: String, CaseIterable, Identifiable, Codable, Hashable {
    case patient
    case caregiver

    var id: String { rawValue }
}

enum CareTapDestination: String, CaseIterable, Identifiable, Hashable {
    case home
    case workspace
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .workspace:
            return "Workspace"
        case .settings:
            return "Settings"
        }
    }

    /// Shorter label for the tab bar so it fits narrow widths without clipping.
    var tabBarTitle: String {
        switch self {
        case .home:
            return "Home"
        case .workspace:
            return "Work"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .workspace:
            return "square.stack.3d.up"
        case .settings:
            return "gearshape"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .workspace:
            return "square.stack.3d.up.fill"
        case .settings:
            return "gearshape.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .home:
            return "Show today's doses"
        case .workspace:
            return "Open your items, people, and history"
        case .settings:
            return "Open settings"
        }
    }
}

extension CareTapDestination: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "home":
            self = .home
        case "workspace", "schedule", "progress":
            self = .workspace
        case "settings", "support":
            self = .settings
        default:
            self = .home
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
