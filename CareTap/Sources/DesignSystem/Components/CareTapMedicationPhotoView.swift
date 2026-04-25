import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CareTapMedicationPhotoView: View {
    let photoPath: String?
    var title: String
    var size: CGSize = CGSize(width: 72, height: 88)

    private var cornerRadius: CGFloat {
        min(size.width, size.height) * 0.2
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(CareTapTheme.stroke.opacity(0.25), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        CareTapTheme.sage.opacity(0.14),
                        CareTapTheme.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "pill.fill")
                        .font(.system(size: min(size.width * 0.28, 22), weight: .semibold))
                        .foregroundStyle(CareTapTheme.sageStrong)

                    if size.height > 60 {
                        Text(title)
                            .font(CareTapTypography.micro)
                            .foregroundStyle(CareTapTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 6)
                    }
                }
            }
    }

    private var image: UIImage? {
        guard let photoPath, !photoPath.isEmpty else {
            return nil
        }
        return UIImage(contentsOfFile: photoPath)
    }
}
