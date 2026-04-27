import Foundation

enum CareTapLegalPage: String, CaseIterable, Identifiable {
    case privacyPolicy = "Privacy Policy"
    case termsOfService = "Terms of Service"
    case consumerHealthData = "Consumer Health Data Policy"
    case dataDeletion = "Data Deletion"
    case privacyChoices = "Privacy Choices"
    case contactSupport = "Contact Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .privacyPolicy: return "hand.raised.fill"
        case .termsOfService: return "doc.text.fill"
        case .consumerHealthData: return "heart.text.square.fill"
        case .dataDeletion: return "trash.fill"
        case .privacyChoices: return "slider.horizontal.3"
        case .contactSupport: return "envelope.fill"
        }
    }

    var effectiveDate: String { "April 13, 2026" }

    var body: String {
        switch self {
        case .privacyPolicy: return Self.privacyPolicyText
        case .termsOfService: return Self.termsOfServiceText
        case .consumerHealthData: return Self.consumerHealthDataText
        case .dataDeletion: return Self.dataDeletionText
        case .privacyChoices: return Self.privacyChoicesText
        case .contactSupport: return Self.contactSupportText
        }
    }

    /// Public HTTPS URL hosted on tapcare.app for Apple review and external links.
    var webURL: URL? {
        let base = "https://tapcare.app/legal"
        switch self {
        case .privacyPolicy: return URL(string: "\(base)/privacy")
        case .termsOfService: return URL(string: "\(base)/terms")
        case .consumerHealthData: return URL(string: "\(base)/consumer-health-data")
        case .dataDeletion: return URL(string: "\(base)/data-deletion")
        case .privacyChoices: return nil
        case .contactSupport: return URL(string: "\(base)/support")
        }
    }
}

// MARK: - Full Policy Text

extension CareTapLegalPage {

    // MARK: Privacy Policy

    static let privacyPolicyText: String = """
    Effective: April 13, 2026

    TapCare ("we," "us," "our") operates the TapCare mobile application. This Privacy Policy explains what information we collect, how we use it, and your choices.

    1. Information We Collect

    Account information. When you create an account we collect your email address or Apple ID identifier, display name, and the role you choose (personal or caregiver). If you sign in with Apple and choose to share your name or email, Apple provides that information to us.

    Health and routine data. TapCare stores the medications, vitamins, supplements, or routines you add, the schedule rules you set, check-in records, logs (including timestamps, source such as NFC tap or manual entry, and optional notes), reminder preferences, and refill estimates. This data is considered consumer health data.

    Device and usage data. TapCare uses your device time zone and locale so schedules, reminders, and dates display correctly on your device. We do not include third-party analytics SDKs or advertising SDKs.

    NFC tag data. When you pair an NFC sticker, TapCare writes a payload identifier to the tag and stores the association between the tag and a routine locally and in your synced account.

    Shared support data. If you link a trusted family member or support person, we store the relationship record and invitation status so both parties can view the schedules and logs you choose to share.

    2. How We Use Your Information

    • To operate TapCare — displaying your routine schedule, logging check-ins, sending reminders, and syncing across sessions.
    • To authenticate your identity and maintain your session securely.
    • To enable shared support relationships you explicitly create.
    • To generate local notifications and Live Activities on your device.
    • To present reminder timing and dates correctly for your locale and time zone.

    We do not sell your personal information. We do not use your health data for advertising.

    3. Data Storage and Security

    Your account and synced data are stored in a Supabase-hosted PostgreSQL database secured with row-level security policies, TLS in transit, and AES-256 encryption at rest. Authentication tokens are stored locally in the app's sandboxed Application Support directory. Offline data is cached on-device and uploaded when connectivity returns.

    4. Data Sharing

    We share your information only in these situations:
    • With caregivers you explicitly link through the invitation flow.
    • With Supabase Inc. as our database and authentication infrastructure provider, governed by their data processing agreement.
    • With Apple Inc. when you use Sign in with Apple, governed by Apple's privacy policy.
    • If required by law, regulation, or valid legal process.

    We do not share data with data brokers, advertisers, or any third party for marketing purposes.

    5. Data Retention

    We retain your data for as long as your account exists. When you delete your account, we permanently remove your authentication record and all associated data from our servers within 30 days. Locally cached data is erased immediately on the device that initiated the deletion.

    6. Children's Privacy

    TapCare is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us and we will delete it promptly.

    7. International Users

    Our servers are located in the United States. By using TapCare you consent to the transfer of your data to the United States.

    8. Changes to This Policy

    We may update this policy from time to time. If we make material changes we will notify you through the app or by email. Continued use after changes constitutes acceptance.

    9. Contact

    TapCare
    Email: support@tapcare.app
    """

    // MARK: Terms of Service

    static let termsOfServiceText: String = """
    Effective: April 13, 2026

    Please read these Terms of Service ("Terms") carefully before using TapCare.

    1. Acceptance

    By creating an account or using TapCare you agree to these Terms. If you do not agree, do not use the app.

    2. Description of Service

    TapCare is a routine-support application. It lets you log check-ins via NFC taps or manual entry, set reminders, view schedules, track refill estimates, and optionally share visibility with a trusted family member or support person. TapCare does not provide medical advice, diagnosis, or treatment.

    3. Not Medical Advice

    TapCare is a personal organization tool. It does not replace professional medical guidance. Always follow your healthcare provider's instructions regarding medications. We are not liable for any health outcome related to your use of TapCare.

    4. Account Responsibilities

    You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information and to notify us if you suspect unauthorized access. You may not share your account with others or use another person's account without permission.

    5. Acceptable Use

    You agree not to:
    • Use TapCare for any unlawful purpose.
    • Attempt to reverse-engineer, decompile, or disassemble the app.
    • Interfere with or disrupt the service or its infrastructure.
    • Impersonate another person or misrepresent your affiliation.
    • Circumvent any security or access controls.

    6. Intellectual Property

    TapCare, its design, code, icons, and content are owned by TapCare and protected by intellectual property laws. You receive a limited, non-exclusive, non-transferable license to use the app for personal, non-commercial purposes.

    7. Caregiver Features

    When you invite a support person, you grant that person read access to the schedules and logs you choose to share. You can revoke this access at any time. You are responsible for managing who you share access with.

    8. Availability and Updates

    We strive to keep TapCare available but do not guarantee uninterrupted access. We may release updates, change features, or discontinue the service at our discretion. We will make reasonable efforts to notify you of material changes.

    9. Limitation of Liability

    To the maximum extent permitted by law, TapCare and its officers, employees, and affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of TapCare, including but not limited to incorrect entries, medication errors, data loss, or health outcomes. Our total liability for any claim shall not exceed the amount you paid us in the twelve months preceding the claim, or $50, whichever is greater.

    10. Disclaimer of Warranties

    TapCare is provided "as is" and "as available" without warranties of any kind, whether express or implied, including implied warranties of merchantability, fitness for a particular purpose, and non-infringement.

    11. Indemnification

    You agree to indemnify and hold harmless TapCare from any claims, damages, or expenses arising from your use of TapCare or violation of these Terms.

    12. Termination

    We may suspend or terminate your account if you violate these Terms. You may delete your account at any time through Settings. Upon termination, your right to use TapCare ceases immediately.

    13. Governing Law

    These Terms are governed by the laws of the State of California, United States, without regard to conflict of law principles.

    14. Dispute Resolution

    Any dispute arising from these Terms or your use of TapCare shall be resolved through binding arbitration under the rules of the American Arbitration Association, conducted in San Francisco, California. You waive any right to participate in a class action.

    15. Severability

    If any provision of these Terms is found unenforceable, the remaining provisions remain in full force.

    16. Entire Agreement

    These Terms, together with our Privacy Policy and Consumer Health Data Policy, constitute the entire agreement between you and TapCare regarding TapCare.

    17. Contact

    TapCare
    Email: support@tapcare.app
    """

    // MARK: Consumer Health Data Policy

    static let consumerHealthDataText: String = """
    Effective: April 13, 2026

    This Consumer Health Data Policy supplements our Privacy Policy and specifically addresses the collection, use, and protection of consumer health data as defined by applicable state laws including the Washington My Health My Data Act and similar legislation.

    1. What Is Consumer Health Data?

    Consumer health data means personal information that is linked or reasonably linkable to you and identifies your past, present, or future physical or mental health status. In TapCare this includes:
    • Medication, vitamin, supplement, or routine names, dosages, and instructions you enter.
    • Schedules, occurrence records, and completion logs.
    • Timestamps and sources of check-in confirmations (NFC tap, manual entry, support-person log).
    • Reminder preferences and refill estimates.
    • Notes you attach to dose logs.

    2. How We Collect Health Data

    We collect health data only when you directly provide it by adding routines, logging check-ins, setting schedules, or writing notes within TapCare. We do not infer health data from other sources, purchase health data, or derive it from non-health signals.

    3. Purpose of Collection

    We collect and process your health data solely to:
    • Display your routine schedule and check-in history.
    • Send you reminders at times you configure.
    • Sync your data between sessions so it persists across sign-ins.
    • Enable shared support access you explicitly authorize.
    • Generate on-device refill estimates.

    4. Consent

    By adding routine data to TapCare you consent to our collection and processing of that data for the purposes above. You may withdraw consent at any time by deleting your data or your account.

    5. Sharing

    We do not sell consumer health data. We do not share it for advertising. Health data is shared only:
    • With support people you invite and authorize.
    • With our infrastructure provider (Supabase Inc.) for storage and sync, under a data processing agreement that restricts their use of your data.
    • When required by law.

    6. Data Retention and Deletion

    Health-related routine data is retained while your account is active. You can export your information or delete your entire account at any time. Account deletion permanently removes the associated TapCare data from our servers within 30 days. See our Data Deletion page for step-by-step instructions.

    7. Security

    We protect consumer health data with TLS encryption in transit, AES-256 encryption at rest, row-level security in our database, and secure token-based authentication. Access to production data is limited to essential personnel.

    8. Your Rights

    Depending on your jurisdiction you may have the right to:
    • Access the health data we hold about you.
    • Request correction of inaccurate data.
    • Request deletion of your health data.
    • Withdraw consent to processing.
    • Receive a copy of your data in a portable format (use the Export feature in Settings).

    To exercise these rights, contact us at support@tapcare.app.

    9. Changes

    We will notify you of material changes to this policy through the app or by email. Continued use after notice constitutes acceptance.

    10. Contact

    TapCare
    Email: support@tapcare.app
    """

    // MARK: Data Deletion

    static let dataDeletionText: String = """
    Effective: April 13, 2026

    TapCare gives you full control over your data. You can export your information or delete your entire account at any time.

    How to Delete Your Account

    1. Open TapCare and go to Settings (tap the gear icon or navigate to the Settings tab).
    2. Scroll to the Account section.
    3. Tap "Delete account."
    4. Confirm the deletion when prompted.

    What Happens When You Delete Your Account

    • Your authentication record is permanently removed from our servers.
    • All routines, schedules, logs, reminders, NFC tag associations, shared support relationships, and invitations tied to your account are permanently deleted from our database within 30 days.
    • Locally cached data on the device that initiated the deletion is erased immediately.
    • Any shared support links are severed, so linked people will no longer see your data.
    • If you signed in with Apple, TapCare's access to your Apple ID is revoked. You can also revoke it manually in your Apple ID settings under Sign-In & Security > Sign in with Apple.

    Deleting Individual Data

    • To export your data before deletion, use the "Export data" option in Settings to create a backup copy.
    • To remove synced data today, use the in-app account deletion flow described above.

    Data Retention After Deletion

    Once deletion is processed, your data is permanently removed from active database systems. Encrypted backups that may contain fragments of deleted data are automatically purged within 30 days.

    If You Need Help

    If you are unable to delete your account through the app (for example, due to a technical issue), contact us at support@tapcare.app with the email address associated with your account and we will process the deletion manually within 10 business days.
    """

    // MARK: Privacy Choices

    static let privacyChoicesText: String = """
    Effective: April 13, 2026

    TapCare is designed to give you control over your information. Here are the choices available to you.

    Sign-In Method

    You can choose to sign in with Apple (which can hide your real email address) or with an email and password. Sign in with Apple's "Hide My Email" feature generates a private relay address so your real email is never shared with us.

    Family Support Sharing

    Sharing is always opt-in. You decide whether to invite a support person and can revoke their access at any time from Settings. Support people only see the schedules and logs you have shared, and they cannot modify your routines or account.

    Notifications and Reminders

    You control whether TapCare can send notifications. You can enable or disable reminders entirely, adjust the lead time, and configure quiet hours from Settings. TapCare never sends marketing or promotional notifications.

    Data Export

    You can export a copy of your routine data at any time from Settings > Export data. The export is provided as a human-readable file you can save or share as you choose.

    Data Deletion

    You can delete your entire account and all associated data from Settings > Delete account. See our Data Deletion page for full details.

    Analytics and Tracking

    TapCare does not use third-party analytics, advertising SDKs, or cross-app tracking. We do not participate in ad networks. We do not fingerprint your device. If you choose to share Apple diagnostics with Apple, that setting remains under your control in Settings > Privacy & Security > Analytics & Improvements.

    Location Data

    TapCare does not request or collect location data.

    Contacts and Photos

    TapCare does not access your contacts or camera. If you add a bottle photo during setup, iOS presents the system photo picker so you can choose an image to store locally on your device.

    Changes to Your Choices

    You can change any of these settings at any time within the app. If new choices become available we will surface them in Settings.

    Contact

    If you have questions about your privacy choices, email us at support@tapcare.app.
    """

    // MARK: Contact Support

    static let contactSupportText: String = """
    We're here to help. If you're experiencing an issue, have a question, or want to share feedback, here's how to reach us.

    Email

    support@tapcare.app

    When contacting us, please include:
    • A description of the issue or question.
    • Your device model and iOS version.
    • Whether you're using the personal or caregiver view.
    • Any error messages you see.

    We aim to respond within 2 business days.

    In-App Support

    From Settings, tap "How logging works" for answers to common questions about how dose confirmations, reminders, and NFC taps interact.

    Use the "Export data" option to generate a support package you can attach to your email if we need to troubleshoot a sync or data issue.

    Account Issues

    If you can't sign in, try signing out and signing in again. If your account was deleted by mistake, contact us as soon as possible so we can confirm whether deletion has already completed. Once deletion is complete, it cannot be undone.

    Reporting a Bug

    If something doesn't look right, please describe what you expected to happen, what actually happened, and the steps to reproduce it. Screenshots are always helpful.

    Feedback and Feature Requests

    We love hearing what would make TapCare more useful for you. Send ideas to the same email address — every message is read.

    TapCare
    support@tapcare.app
    """
}
