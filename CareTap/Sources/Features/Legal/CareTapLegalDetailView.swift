import SwiftUI

struct CareTapLegalDetailView: View {
    let page: CareTapLegalPage
    var onDismiss: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    bodyText
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(CareTapTheme.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(CareTapTypography.bodyStrong)
                        .foregroundStyle(CareTapTheme.sageStrong)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: page.icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(CareTapTheme.sage)
                .padding(.top, 12)

            Text(page.rawValue)
                .font(CareTapTypography.section)
                .foregroundStyle(CareTapTheme.textPrimary)

            Text("Last updated \(page.effectiveDate)")
                .font(CareTapTypography.micro)
                .foregroundStyle(CareTapTheme.textTertiary)
        }
    }

    private var bodyText: some View {
        Text(page.body)
            .font(.system(.footnote, design: .default))
            .foregroundStyle(CareTapTheme.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CareTapLegalLinksFooter: View {
    @State private var presentedPage: CareTapLegalPage?

    private let primaryLinks: [CareTapLegalPage] = [
        .termsOfService, .privacyPolicy, .consumerHealthData
    ]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(primaryLinks.enumerated()), id: \.element.id) { index, page in
                    if index > 0 {
                        Text(" · ")
                            .font(.system(size: 10))
                            .foregroundStyle(CareTapTheme.textTertiary.opacity(0.5))
                    }
                    Button { presentedPage = page } label: {
                        Text(shortLabel(for: page))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CareTapTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .sheet(item: $presentedPage) { page in
            CareTapLegalDetailView(page: page) {
                presentedPage = nil
            }
        }
    }

    private func shortLabel(for page: CareTapLegalPage) -> String {
        switch page {
        case .termsOfService: return "Terms"
        case .privacyPolicy: return "Privacy"
        case .consumerHealthData: return "Health Data"
        default: return page.rawValue
        }
    }
}

#Preview("Privacy Policy") {
    CareTapLegalDetailView(page: .privacyPolicy)
}

#Preview("Legal Footer") {
    CareTapLegalLinksFooter()
        .padding()
}
