@preconcurrency import CoreNFC
import Foundation

final class CoreNFCTagService: NSObject, NFCTagServicing, @unchecked Sendable {
    private enum Operation {
        case read
        case write(NFCTagWriteRequest)
    }

    private let recordStore: any CareTapRecordStoring
    private let universalLinkHost: String?
    private var continuation: CheckedContinuation<NFCTagResultEnvelope, Error>?
    private var pendingOperation: Operation?
    private var session: NFCReaderSession?

    init(
        recordStore: any CareTapRecordStoring,
        universalLinkHost: String? = nil
    ) {
        self.recordStore = recordStore
        self.universalLinkHost = universalLinkHost?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func scanTag() async throws -> NFCTagReadResult {
        let result = try await beginSession(for: .read)
        switch result {
        case .read(let response):
            return response
        case .write:
            throw CareTapServiceError.unavailable
        }
    }

    func readTag(stableUID: String) async throws -> NFCTagReadResult {
        guard let tag = try await recordStore.tag(stableUID: stableUID) else {
            throw CareTapServiceError.missingRecord
        }

        return NFCTagReadResult(tag: tag, matchedMedicationID: tag.medicationID)
    }

    func writeTag(_ request: NFCTagWriteRequest) async throws -> NFCTagWriteResult {
        let result = try await beginSession(for: .write(request))
        switch result {
        case .write(let response):
            return response
        case .read:
            throw CareTapServiceError.unavailable
        }
    }

    private func beginSession(for operation: Operation) async throws -> NFCTagResultEnvelope {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NFCTagResultEnvelope, Error>) in
            guard NFCNDEFReaderSession.readingAvailable else {
                continuation.resume(throwing: CareTapServiceError.unavailable)
                return
            }

            self.pendingOperation = operation
            self.continuation = continuation

            let session = NFCNDEFReaderSession(
                delegate: self,
                queue: nil,
                invalidateAfterFirstRead: false
            )

            session.alertMessage = alertMessage(for: operation)
            self.session = session
            session.begin()
        }
    }

    private func alertMessage(for operation: Operation) -> String {
        switch operation {
        case .read:
            return "Hold the iPhone near the tag."
        case .write:
            return "Hold the iPhone near the tag to pair this item."
        }
    }

    private func finish(with result: Result<NFCTagResultEnvelope, Error>) {
        let continuation = continuation
        self.continuation = nil
        pendingOperation = nil
        session = nil

        switch result {
        case .success(let envelope):
            continuation?.resume(returning: envelope)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }

    private func payloadIdentifier(from message: NFCNDEFMessage) -> String? {
        for record in message.records {
            if let value = record.wellKnownTypeTextPayload().0, !value.isEmpty {
                return value
            }

            if let url = record.wellKnownTypeURIPayload(),
               let value = CareTapDeepLink.payloadIdentifier(from: url),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func ndefMessage(for request: NFCTagWriteRequest) -> NFCNDEFMessage? {
        if let universalLinkHost,
           let universalLink = CareTapDeepLink.universalLinkURL(
                host: universalLinkHost,
                payloadIdentifier: request.payloadIdentifier
           ),
           let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: universalLink) {
            return NFCNDEFMessage(records: [payload])
        }

        guard let payload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: request.payloadIdentifier,
            locale: Locale(identifier: "en")
        ) else {
            return nil
        }

        return NFCNDEFMessage(records: [payload])
    }

    private func stableUID(from tag: any NFCNDEFTag) -> String {
        if let mifareTag = tag as? NFCMiFareTag {
            return stableUID(from: mifareTag.identifier)
        }

        if let iso15693Tag = tag as? NFCISO15693Tag {
            return stableUID(from: iso15693Tag.identifier)
        }

        if let felicaTag = tag as? NFCFeliCaTag {
            return stableUID(from: felicaTag.currentIDm)
        }

        if let iso7816Tag = tag as? NFCISO7816Tag {
            return stableUID(from: iso7816Tag.identifier)
        }

        return ""
    }

    private func stableUID(from data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func resolveStoredTag(
        stableUID: String,
        ndefTagHandle: NFCNDEFTagHandle?
    ) async throws -> NfcTag {
        if let storedTag = try await recordStore.tag(stableUID: stableUID) {
            return storedTag
        }

        guard let ndefTagHandle,
              let payloadIdentifier = try await readPayloadIdentifier(from: ndefTagHandle),
              let storedTag = try await recordStore.tag(payloadIdentifier: payloadIdentifier) else {
            throw CareTapServiceError.missingRecord
        }

        return storedTag
    }

    private func queryNDEFStatus(for ndefTagHandle: NFCNDEFTagHandle) async throws -> NFCNDEFStatus {
        try await withCheckedThrowingContinuation { continuation in
            ndefTagHandle.tag.queryNDEFStatus { status, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: status)
            }
        }
    }

    private func readPayloadIdentifier(from ndefTagHandle: NFCNDEFTagHandle) async throws -> String? {
        let status = try await queryNDEFStatus(for: ndefTagHandle)
        guard status == .readOnly || status == .readWrite else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            ndefTagHandle.tag.readNDEF { [weak self] message, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: message.flatMap { self?.payloadIdentifier(from: $0) })
            }
        }
    }

    private func completeWrite(
        request: NFCTagWriteRequest,
        stableUID: String,
        sessionHandle: NFCReaderSessionHandle,
        ndefTagHandle: NFCNDEFTagHandle
    ) {
        ndefTagHandle.tag.queryNDEFStatus { [weak self] status, _, error in
            guard let self else { return }
            if let error {
                sessionHandle.session.invalidate(errorMessage: "CareTap could not verify this tag.")
                self.finish(with: .failure(error))
                return
            }

            guard status == .readWrite else {
                let message = switch status {
                case .readOnly:
                    "This tag is read-only. Use a new writable NFC sticker."
                case .notSupported:
                    "This tag is not NDEF formatted. Use a writable NDEF sticker."
                case .readWrite:
                    "This tag cannot be written."
                @unknown default:
                    "This tag cannot be written."
                }
                sessionHandle.session.invalidate(errorMessage: message)
                self.finish(with: .failure(CareTapServiceError.invalidTag))
                return
            }

            guard let message = self.ndefMessage(for: request) else {
                sessionHandle.session.invalidate(errorMessage: "CareTap could not encode that tag payload.")
                self.finish(with: .failure(CareTapServiceError.invalidTag))
                return
            }

            ndefTagHandle.tag.writeNDEF(message) { [weak self] error in
                guard let self else { return }
                if let error {
                    sessionHandle.session.invalidate(errorMessage: "CareTap could not finish pairing this tag.")
                    self.finish(with: .failure(error))
                    return
                }

                let pairedTag = NfcTag(
                    id: UUID(),
                    careProfileID: request.careProfileID,
                    medicationID: request.medicationID,
                    stableUID: stableUID.isEmpty ? request.stableUID : stableUID,
                    payloadIdentifier: request.payloadIdentifier,
                    label: request.label,
                    status: .paired,
                    pairedAt: .now,
                    lastReadAt: nil,
                    lastWrittenAt: .now,
                    createdAt: .now,
                    updatedAt: .now,
                    syncState: .pendingUpload
                )

                sessionHandle.session.alertMessage = "CareTap paired the tag successfully."
                sessionHandle.session.invalidate()
                self.finish(with: .success(.write(NFCTagWriteResult(tag: pairedTag, pairingState: .success))))
            }
        }
    }
}

extension CoreNFCTagService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled {
            finish(with: .failure(CareTapServiceError.unavailable))
            return
        }

        finish(with: .failure(error))
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let operation = pendingOperation, let tag = tags.first else {
            session.invalidate(errorMessage: "CareTap could not pair that tag.")
            finish(with: .failure(CareTapServiceError.invalidTag))
            return
        }

        if tags.count > 1 {
            session.alertMessage = "More than one tag was detected. Please try again with one tag."
            session.restartPolling()
            return
        }

        let sessionHandle = NFCReaderSessionHandle(session: session)
        let stableUID = stableUID(from: tag)
        let ndefTagHandle = NFCNDEFTagHandle(tag: tag)

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                sessionHandle.session.invalidate(errorMessage: "CareTap could not connect to that tag.")
                self.finish(with: .failure(error))
                return
            }

            switch operation {
            case .read:
                Task { [stableUID, ndefTagHandle, sessionHandle] in
                    do {
                        let storedTag = try await self.resolveStoredTag(
                            stableUID: stableUID,
                            ndefTagHandle: ndefTagHandle
                        )
                        let result = NFCTagReadResult(tag: storedTag, matchedMedicationID: storedTag.medicationID)
                        sessionHandle.session.alertMessage = "CareTap recognized the tag."
                        sessionHandle.session.invalidate()
                        self.finish(with: .success(.read(result)))
                    } catch {
                        sessionHandle.session.invalidate(errorMessage: "This tag has not been paired in CareTap yet.")
                        self.finish(with: .failure(error))
                    }
                }
            case .write(let request):
                self.completeWrite(
                    request: request,
                    stableUID: stableUID,
                    sessionHandle: sessionHandle,
                    ndefTagHandle: ndefTagHandle
                )
            }
        }
    }
}

private enum NFCTagResultEnvelope {
    case read(NFCTagReadResult)
    case write(NFCTagWriteResult)
}

private struct NFCReaderSessionHandle: @unchecked Sendable {
    let session: NFCReaderSession
}

private struct NFCNDEFTagHandle: @unchecked Sendable {
    let tag: any NFCNDEFTag
}
