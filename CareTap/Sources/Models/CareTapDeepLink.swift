import Foundation

enum CareTapDeepLink: Hashable {
    case tagTap(payloadIdentifier: String)
    case destination(CareTapDestination)
    case tapKitOrderResult(success: Bool, packSlug: String?)
    private static let maxPayloadLength = 128

    init?(url: URL) {
        if let result = Self.tapKitOrderResult(from: url) {
            self = result
            return
        }

        if let destination = Self.destination(from: url) {
            self = .destination(destination)
            return
        }

        guard let payloadIdentifier = Self.payloadIdentifier(from: url) else {
            return nil
        }

        self = .tagTap(payloadIdentifier: payloadIdentifier)
    }

    static func tapKitOrderURL(success: Bool, packSlug: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "caretap"
        components.host = "tapkit"
        components.path = success ? "/success" : "/cancel"
        if let packSlug, !packSlug.isEmpty {
            components.queryItems = [URLQueryItem(name: "pack", value: packSlug)]
        }
        return components.url
    }

    private static func tapKitOrderResult(from url: URL) -> CareTapDeepLink? {
        guard let scheme = url.scheme?.lowercased(), scheme == "caretap" else {
            return nil
        }

        let host = url.host?.lowercased()
        let trimmedPathComponents = url.pathComponents.filter { $0 != "/" }

        let isTapKit = host == "tapkit" || trimmedPathComponents.first?.lowercased() == "tapkit"
        guard isTapKit else { return nil }

        let resultPath: String?
        if host == "tapkit" {
            resultPath = trimmedPathComponents.first?.lowercased()
        } else {
            resultPath = trimmedPathComponents.dropFirst().first?.lowercased()
        }

        let success: Bool
        switch resultPath {
        case "success":
            success = true
        case "cancel", "canceled", "cancelled":
            success = false
        default:
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let packSlug = components?.queryItems?.first(where: { $0.name == "pack" })?.value
        return .tapKitOrderResult(success: success, packSlug: packSlug)
    }

    static func universalLinkURL(host: String, payloadIdentifier: String) -> URL? {
        guard !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let safePayloadIdentifier = sanitizedPayloadIdentifier(payloadIdentifier) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/tag/\(safePayloadIdentifier)"
        return components.url
    }

    static func widgetURL(destination: CareTapDestination) -> URL? {
        var components = URLComponents()
        components.scheme = "caretap"
        components.host = destination.rawValue
        return components.url
    }

    static func payloadIdentifier(for medicationID: UUID) -> String {
        "caretap-\(medicationID.uuidString.lowercased())"
    }

    static func tagURL(payloadIdentifier: String) -> URL? {
        guard let safePayloadIdentifier = sanitizedPayloadIdentifier(payloadIdentifier) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "caretap"
        components.host = "tag"
        components.path = "/\(safePayloadIdentifier)"
        return components.url
    }

    static func payloadIdentifier(from url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(),
              ["https", "caretap"].contains(scheme) else {
            return nil
        }

        let trimmedPathComponents = url.pathComponents.filter { $0 != "/" }
        if trimmedPathComponents.count >= 2,
           ["tag", "nfc"].contains(trimmedPathComponents[0].lowercased()) {
            return sanitizedPayloadIdentifier(trimmedPathComponents[1])
        }

        if scheme == "caretap" {
            let host = url.host?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let host,
               ["tag", "nfc"].contains(host.lowercased()),
               let payloadIdentifier = trimmedPathComponents.first,
               let safePayloadIdentifier = sanitizedPayloadIdentifier(payloadIdentifier) {
                return safePayloadIdentifier
            }

            if let host,
               let safeHost = sanitizedPayloadIdentifier(host) {
                return safeHost
            }
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value,
              let safePayload = sanitizedPayloadIdentifier(payload) else {
            return nil
        }

        return safePayload
    }

    private static func destination(from url: URL) -> CareTapDestination? {
        guard let scheme = url.scheme?.lowercased(), scheme == "caretap" else {
            return nil
        }

        if let host = url.host?.lowercased(),
           let destination = CareTapDestination(rawValue: host) {
            return destination
        }

        let trimmedPathComponents = url.pathComponents.filter { $0 != "/" }
        if let firstComponent = trimmedPathComponents.first?.lowercased(),
           let destination = CareTapDestination(rawValue: firstComponent) {
            return destination
        }

        return nil
    }

    private static func sanitizedPayloadIdentifier(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxPayloadLength else {
            return nil
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard trimmed.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            return nil
        }

        return trimmed
    }
}
