import SwiftUI
import SafariServices

/// A SwiftUI wrapper around `SFSafariViewController` used to host the Stripe
/// Checkout flow in-app. We deliberately use Safari (not ASWebAuthenticationSession)
/// so users see the calm "Stripe.com" address bar — it makes the purchase feel
/// official without an OAuth-style "this app wants to sign in" prompt.
///
/// Stripe Payment Links redirect to `caretap://tapkit/success` on completion,
/// which surfaces back through the app's `onOpenURL` handler.
struct TapKitCheckoutSafariView: UIViewControllerRepresentable {
    let url: URL
    var onFinish: () -> Void = {}

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = true
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .close
        controller.preferredBarTintColor = UIColor.systemBackground
        controller.preferredControlTintColor = UIColor(named: "SageStrong")
            ?? UIColor.systemGreen
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // SFSafariViewController loads the URL once at init time; nothing to refresh.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onFinish()
        }
    }
}
