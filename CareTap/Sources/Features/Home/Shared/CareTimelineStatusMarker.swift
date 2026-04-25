import SwiftUI

struct CareTimelineStatusMarker: View {
    let status: CareTimelineStatus
    let drawsConnector: Bool

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(markerColor)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: markerSymbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(markerForeground)
                }

            if drawsConnector {
                Rectangle()
                    .fill(CareTapTheme.stroke)
                    .frame(width: 2)
            }
        }
    }

    private var markerColor: Color {
        switch status {
        case .missed:
            return CareTapTheme.alert.opacity(0.22)
        case .upcoming:
            return CareTapTheme.warm
        case .bedtime:
            return CareTapTheme.surfaceElevated
        case .completed:
            return CareTapTheme.success.opacity(0.26)
        }
    }

    private var markerForeground: Color {
        switch status {
        case .upcoming:
            return .white
        case .missed:
            return CareTapTheme.alert
        case .bedtime:
            return CareTapTheme.textSecondary
        case .completed:
            return CareTapTheme.success
        }
    }

    private var markerSymbol: String {
        switch status {
        case .missed:
            return "xmark"
        case .upcoming:
            return "link"
        case .bedtime:
            return "bed.double.fill"
        case .completed:
            return "checkmark"
        }
    }
}

