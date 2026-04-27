import XCTest
@testable import CareTap

final class PhaseFourBackendTests: XCTestCase {
    private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
        nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let handler = Self.requestHandler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }

            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private func makeTemporaryDiskStore() throws -> CareTapBackendDiskStore {
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(path: "CareTapTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = try CareTapBackendDiskStore(directoryURL: directoryURL)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        return store
    }

    func testUserRowRoundTripPreservesAuthLink() {
        let user = CareTapPhaseThreePreviewScenarios.user
        let row = UserRow(domainModel: user, syncVersion: 3)
        let mapped = row.toDomainModel()

        XCTAssertEqual(mapped.id, user.id)
        XCTAssertEqual(mapped.authUserID, user.authUserID)
        XCTAssertEqual(mapped.appleSubject, user.appleSubject)
        XCTAssertEqual(row.syncVersion, 3)
    }

    func testDoseOccurrenceRowRoundTripPreservesDismissedReminderState() {
        let occurrence = CareTapPhaseThreePreviewScenarios.overdueOccurrence
        let row = DoseOccurrenceRow(domainModel: occurrence)
        let mapped = row.toDomainModel()

        XCTAssertEqual(mapped.status, .overdue)
        XCTAssertEqual(mapped.reminderState, .dismissed)
        XCTAssertTrue(mapped.reminderDismissalDoesNotCountAsTaken)
    }

    func testMedicationRowDecodeDefaultsV2FieldsWhenMissingFromOlderPayload() throws {
        let createdAt = Date(timeIntervalSinceReferenceDate: 10_000)
        let payload: [String: Any] = [
            "id": UUID().uuidString.lowercased(),
            "care_profile_id": UUID().uuidString.lowercased(),
            "name": "Legacy Medication",
            "dosage": "1 tablet",
            "bottle_label": "Nightstand bottle",
            "form": MedicationForm.bottle.rawValue,
            "schedule_summary": "Every day at 8:00 AM",
            "is_active": true,
            "created_at": createdAt.timeIntervalSinceReferenceDate,
            "updated_at": createdAt.timeIntervalSinceReferenceDate,
            "sync_state": CareTapSyncState.localOnly.rawValue
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let row = try JSONDecoder().decode(MedicationRow.self, from: data)

        XCTAssertEqual(row.category, .prescription)
        XCTAssertEqual(row.containerKind, .bottle)
        XCTAssertEqual(row.toDomainModel().category, .prescription)
        XCTAssertEqual(row.toDomainModel().containerKind, .bottle)
    }

    func testDoseLogRowDecodeDefaultsV2ResolutionFieldsWhenMissingFromOlderPayload() throws {
        let timestamp = Date(timeIntervalSinceReferenceDate: 20_000)
        let payload: [String: Any] = [
            "id": UUID().uuidString.lowercased(),
            "care_profile_id": UUID().uuidString.lowercased(),
            "medication_id": UUID().uuidString.lowercased(),
            "source": DoseLogSource.manualPatientConfirmation.rawValue,
            "action": DoseLogAction.confirmTaken.rawValue,
            "validation_state": DoseLogValidationState.accepted.rawValue,
            "effective_at": timestamp.timeIntervalSinceReferenceDate,
            "logged_at": timestamp.timeIntervalSinceReferenceDate,
            "created_at": timestamp.timeIntervalSinceReferenceDate,
            "updated_at": timestamp.timeIntervalSinceReferenceDate,
            "sync_state": CareTapSyncState.localOnly.rawValue
        ]

        let data = try JSONSerialization.data(withJSONObject: payload)
        let row = try JSONDecoder().decode(DoseLogRow.self, from: data)

        XCTAssertEqual(row.resolutionKind, .standard)
        XCTAssertNil(row.resolutionReason)
        XCTAssertNil(row.undoesLogID)
        XCTAssertEqual(row.toDomainModel().resolutionKind, .standard)
    }

    func testPreviewBackendReadsSeededData() async throws {
        let backend = SupabaseBackendRepository.previewSeeded()
        let interval = DateInterval(
            start: CareTapPhaseThreePreviewScenarios.referenceDate.addingTimeInterval(-24 * 60 * 60),
            end: CareTapPhaseThreePreviewScenarios.referenceDate.addingTimeInterval(24 * 60 * 60)
        )

        let medications = try await backend.fetchMedications(careProfileID: CareTapPhaseThreePreviewScenarios.careProfile.id)
        let occurrences = try await backend.fetchDoseOccurrences(
            careProfileID: CareTapPhaseThreePreviewScenarios.careProfile.id,
            within: interval
        )

        XCTAssertEqual(medications.map(\.name), ["Lisinopril"])
        XCTAssertEqual(occurrences.count, 3)
    }

    func testSyncConflictKeepsOlderMutationOutOfRemoteWrite() async throws {
        let backend = SupabaseBackendRepository.previewSeeded()
        let localMedication = Medication(
            id: CareTapPhaseThreePreviewScenarios.medication.id,
            careProfileID: CareTapPhaseThreePreviewScenarios.medication.careProfileID,
            nfcTagID: CareTapPhaseThreePreviewScenarios.medication.nfcTagID,
            name: "Lisinopril Updated Locally",
            dosage: CareTapPhaseThreePreviewScenarios.medication.dosage,
            doseQuantity: CareTapPhaseThreePreviewScenarios.medication.doseQuantity,
            doseQuantityUnit: CareTapPhaseThreePreviewScenarios.medication.doseQuantityUnit,
            instructions: CareTapPhaseThreePreviewScenarios.medication.instructions,
            bottleLabel: CareTapPhaseThreePreviewScenarios.medication.bottleLabel,
            bottlePhotoLocalPath: CareTapPhaseThreePreviewScenarios.medication.bottlePhotoLocalPath,
            form: CareTapPhaseThreePreviewScenarios.medication.form,
            scheduleSummary: CareTapPhaseThreePreviewScenarios.medication.scheduleSummary,
            isActive: CareTapPhaseThreePreviewScenarios.medication.isActive,
            supplyCount: CareTapPhaseThreePreviewScenarios.medication.supplyCount,
            createdAt: CareTapPhaseThreePreviewScenarios.medication.createdAt,
            updatedAt: CareTapPhaseThreePreviewScenarios.medication.updatedAt.addingTimeInterval(-60),
            archivedAt: CareTapPhaseThreePreviewScenarios.medication.archivedAt,
            syncState: .pendingUpload
        )

        await backend.stage(
            CareTapSyncMutationBatch(
                medications: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: localMedication.updatedAt,
                        row: MedicationRow(domainModel: localMedication)
                    )
                ]
            )
        )

        let snapshotBefore = await backend.syncSnapshot()
        let result = try await backend.syncPendingChanges()

        XCTAssertEqual(snapshotBefore.pendingUploadCount, 1)
        XCTAssertEqual(result.uploadedCount, 0)
        XCTAssertEqual(result.conflicts.count, 1)
        XCTAssertEqual(result.conflicts.first?.entityName, CareTapSupabaseTable.medications.rawValue)
    }

    func testSoftDeletedMedicationIsHiddenFromActiveQueriesButIncludedInSyncFetch() async throws {
        let transport = InMemorySupabaseTransport()
        let repositories = CareTapSupabaseRepositorySet(transport: transport)
        let deletedAt = CareTapPhaseThreePreviewScenarios.referenceDate

        _ = try await transport.upsert(
            [
                MedicationRow(
                    domainModel: CareTapPhaseThreePreviewScenarios.medication,
                    deletedAt: deletedAt,
                    lastClientUpdatedAt: deletedAt
                )
            ],
            into: .medications,
            onConflict: ["id"]
        )

        let activeMedications = try await repositories.medications.medications(
            for: CareTapPhaseThreePreviewScenarios.careProfile.id
        )
        let syncVisibleMedications = try await repositories.medications.fetchModified(since: nil)

        XCTAssertTrue(activeMedications.isEmpty)
        XCTAssertEqual(syncVisibleMedications.map(\.id), [CareTapPhaseThreePreviewScenarios.medication.id])
    }

    func testNFCTagRepositoryFetchesByPayloadIdentifier() async throws {
        let transport = InMemorySupabaseTransport()
        let repositories = CareTapSupabaseRepositorySet(transport: transport)
        let tag = CareTapPhaseThreePreviewScenarios.nfcTag

        _ = try await transport.upsert(
            [NfcTagRow(domainModel: tag)],
            into: .nfcTags,
            onConflict: ["id"]
        )

        let fetchedTag = try await repositories.nfcTags.tag(payloadIdentifier: tag.payloadIdentifier)

        XCTAssertEqual(fetchedTag?.id, tag.id)
        XCTAssertEqual(fetchedTag?.stableUID, tag.stableUID)
    }

    func testPersistentSupabaseTransportRestoresCachedRowsAcrossInstances() async throws {
        let store = try makeTemporaryDiskStore()
        let transport = try PersistentSupabaseTransport(store: store)
        let row = MedicationRow(domainModel: CareTapPhaseThreePreviewScenarios.medication)

        _ = try await transport.upsert([row], into: .medications, onConflict: ["id"])

        let reloadedTransport = try PersistentSupabaseTransport(store: store)
        let restoredRows: [MedicationRow] = try await reloadedTransport.select(
            from: .medications,
            filters: [],
            orderBy: nil,
            limit: nil
        )

        XCTAssertEqual(restoredRows.map(\.id), [row.id])
    }

    func testSyncStateStoreRestoresQueuedMutationsFromDisk() async throws {
        let store = try makeTemporaryDiskStore()
        let localMedication = MedicationRow(domainModel: CareTapPhaseThreePreviewScenarios.medication)

        let stateStore = CareTapSyncStateStore(cursor: nil, persistence: store)
        stateStore.queue(
            CareTapSyncMutationBatch(
                medications: [
                    CareTapSyncMutation(
                        operation: .upsert,
                        clientUpdatedAt: localMedication.updatedAt,
                        row: localMedication
                    )
                ]
            )
        )

        let restoredStore = CareTapSyncStateStore(cursor: nil, persistence: store)
        XCTAssertEqual(restoredStore.pendingRequest().mutations.totalMutationCount, 1)
    }

    func testSupabaseAuthCoordinatorRestoresPersistedLinkedSession() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        let user = CareTapPhaseThreePreviewScenarios.user

        try store.saveAuthSession(
            CareTapPersistedAuthSession(
                authUserID: try XCTUnwrap(user.authUserID),
                accessToken: "access-token",
                refreshToken: "refresh-token",
                expiresAt: Date().addingTimeInterval(60 * 60),
                provider: "apple"
            )
        )

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore
        )
        let snapshot = await coordinator.sessionSnapshot()

        XCTAssertEqual(snapshot.state, .linkedForSync)
        XCTAssertEqual(snapshot.user?.id, user.id)
    }

    @MainActor
    func testFailsafeUnavailableServicesStaySignedOutAndEmpty() async throws {
        let services = CareTapServiceContainer.failsafeUnavailable()

        let snapshot = await services.auth.sessionSnapshot()
        let medications = try await services.backend.fetchMedications(
            careProfileID: CareTapPhaseThreePreviewScenarios.careProfile.id
        )

        XCTAssertEqual(snapshot.state, .signedOut)
        XCTAssertNil(snapshot.user)
        XCTAssertTrue(medications.isEmpty)
    }

    func testSupabaseAuthCoordinatorUsesAuthV1TokenEndpointForAppleSignIn() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/auth/v1/token")
            let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.queryItems?.first(where: { $0.name == "grant_type" })?.value, "id_token")
            XCTAssertEqual(request.httpMethod, "POST")

            let responseData = """
            {
              "access_token": "access-token",
              "refresh_token": "refresh-token",
              "expires_in": 3600,
              "user": {
                "id": "\(UUID().uuidString.lowercased())",
                "email": "mia@example.com"
              }
            }
            """.data(using: .utf8)!

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore,
            session: session
        )

        let snapshot = try await coordinator.signInWithApple(
            with: AppleIdentityTokenPayload(
                idToken: "test-id-token",
                rawNonce: "raw-nonce",
                authorizationCode: nil,
                appleSubject: "apple-subject",
                email: "mia@example.com",
                givenName: "Mia",
                familyName: "Patient"
            ),
            preferredRole: .patient
        )

        XCTAssertEqual(snapshot.state, .linkedForSync)
        XCTAssertEqual(snapshot.user?.preferredRole, .patient)
    }

    func testSupabaseAuthCoordinatorSurfacesSupabaseErrorBody() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        MockURLProtocol.requestHandler = { request in
            let responseData = """
            {
              "error": "invalid_request",
              "error_description": "provider is not enabled"
            }
            """.data(using: .utf8)!

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore,
            session: session
        )

        do {
            _ = try await coordinator.signInWithApple(
                with: AppleIdentityTokenPayload(
                    idToken: "test-id-token",
                    rawNonce: "raw-nonce",
                    authorizationCode: nil,
                    appleSubject: "apple-subject",
                    email: nil,
                    givenName: nil,
                    familyName: nil
                ),
                preferredRole: .patient
            )
            XCTFail("Expected sign-in to fail")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            XCTAssertTrue(message.contains("provider is not enabled"))
            XCTAssertTrue(message.contains("400"))
        }
    }

    func testDeleteAccountUsesDeleteAccountEdgeFunctionEndpoint() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        let user = CareTapPhaseThreePreviewScenarios.user

        try store.saveAuthSession(
            CareTapPersistedAuthSession(
                authUserID: try XCTUnwrap(user.authUserID),
                accessToken: "access-token",
                refreshToken: "refresh-token",
                expiresAt: Date().addingTimeInterval(60 * 60),
                provider: "apple"
            )
        )

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        nonisolated(unsafe) var requestPaths: [String] = []

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            requestPaths.append(path)

            if path == "/auth/v1/token" {
                XCTAssertEqual(request.url?.query, "grant_type=refresh_token")

                let responseData = """
                {
                  "access_token": "fresh-token",
                  "refresh_token": "fresh-refresh-token",
                  "expires_in": 3600,
                  "user": {
                    "id": "\(try XCTUnwrap(user.authUserID).uuidString.lowercased())",
                    "email": "maya@example.com"
                  }
                }
                """.data(using: .utf8)!

                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                )
                return (response, responseData)
            }

            XCTAssertEqual(path, "/functions/v1/delete-account")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")

            let responseData = """
            {
              "success": true
            }
            """.data(using: .utf8)!

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore,
            session: session
        )

        try await coordinator.deleteAccount()

        XCTAssertEqual(requestPaths, ["/auth/v1/token", "/functions/v1/delete-account"])
        XCTAssertNil(try store.loadAuthSession())
    }

    func testDeleteAccountSurfacesMissingEdgeFunctionClearly() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        let user = CareTapPhaseThreePreviewScenarios.user

        try store.saveAuthSession(
            CareTapPersistedAuthSession(
                authUserID: try XCTUnwrap(user.authUserID),
                accessToken: "access-token",
                refreshToken: "refresh-token",
                expiresAt: Date().addingTimeInterval(60 * 60),
                provider: "apple"
            )
        )

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/auth/v1/token" {
                let responseData = """
                {
                  "access_token": "fresh-token",
                  "refresh_token": "fresh-refresh-token",
                  "expires_in": 3600,
                  "user": {
                    "id": "\(try XCTUnwrap(user.authUserID).uuidString.lowercased())",
                    "email": "maya@example.com"
                  }
                }
                """.data(using: .utf8)!

                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                )
                return (response, responseData)
            }

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, Data())
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore,
            session: session
        )

        do {
            try await coordinator.deleteAccount()
            XCTFail("Expected account deletion to fail")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            XCTAssertTrue(message.contains("Account deletion"))
        }
    }

    func testDeleteAccountRefreshesExpiredSessionBeforeCallingEdgeFunction() async throws {
        let store = try makeTemporaryDiskStore()
        let backend = SupabaseBackendRepository.previewSeeded()
        let recordStore = RepositoryBackedCareTapRecordStore(backend: backend)
        let user = CareTapPhaseThreePreviewScenarios.user

        try store.saveAuthSession(
            CareTapPersistedAuthSession(
                authUserID: try XCTUnwrap(user.authUserID),
                accessToken: "expired-token",
                refreshToken: "refresh-token",
                expiresAt: Date().addingTimeInterval(-60),
                provider: "apple"
            )
        )

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        nonisolated(unsafe) var requestPaths: [String] = []

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            requestPaths.append(path)

            if path == "/auth/v1/token" {
                XCTAssertEqual(request.url?.query, "grant_type=refresh_token")
                let responseData = """
                {
                  "access_token": "fresh-token",
                  "refresh_token": "fresh-refresh-token",
                  "expires_in": 3600,
                  "user": {
                    "id": "\(try XCTUnwrap(user.authUserID).uuidString.lowercased())",
                    "email": "maya@example.com"
                  }
                }
                """.data(using: .utf8)!

                let response = try XCTUnwrap(
                    HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )
                )
                return (response, responseData)
            }

            XCTAssertEqual(path, "/functions/v1/delete-account")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer fresh-token")

            let responseData = """
            {
              "success": true
            }
            """.data(using: .utf8)!

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let coordinator = SupabaseAuthCoordinator(
            configuration: SupabaseConfiguration(
                projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                apiKey: "sb_publishable_test"
            ),
            sessionStore: store,
            recordStore: recordStore,
            session: session
        )

        try await coordinator.deleteAccount()

        XCTAssertEqual(requestPaths, ["/auth/v1/token", "/functions/v1/delete-account"])
    }

    func testLiveRedeemInvitationDecodesRPCRowArray() async throws {
        let careProfileID = UUID()
        let relationshipID = UUID()
        let invitationID = UUID()
        let alertPolicyID = UUID()

        let localTransport = InMemorySupabaseTransport()
        let remoteCache = InMemorySupabaseTransport()
        let remoteGateway = SupabaseSyncGatewayClient(repositories: CareTapSupabaseRepositorySet(transport: remoteCache))
        let syncEngine = try OfflineFirstSyncEngine(localTransport: localTransport, remoteGateway: remoteGateway)

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/rest/v1/rpc/caretap_redeem_invitation")
            XCTAssertEqual(request.httpMethod, "POST")

            let responseData = """
            [
              {
                "care_profile_id": "\(careProfileID.uuidString.lowercased())",
                "relationship_id": "\(relationshipID.uuidString.lowercased())",
                "invitation_id": "\(invitationID.uuidString.lowercased())",
                "alert_policy_id": "\(alertPolicyID.uuidString.lowercased())"
              }
            ]
            """.data(using: .utf8)!

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            return (response, responseData)
        }
        addTeardownBlock {
            MockURLProtocol.requestHandler = nil
        }

        let backend = SupabaseBackendRepository(
            syncEngine: syncEngine,
            remoteTransport: URLSessionSupabaseTransport(
                configuration: SupabaseConfiguration(
                    projectURL: try XCTUnwrap(URL(string: "https://qznwkvezqsxcbbvgqjci.supabase.co")),
                    apiKey: "sb_publishable_test"
                ),
                session: session
            )
        )

        let redemption = try await backend.redeemInvitation(token: "ABC12345", caregiverUserID: UUID())

        XCTAssertEqual(redemption.careProfileID, careProfileID)
        XCTAssertEqual(redemption.relationshipID, relationshipID)
        XCTAssertEqual(redemption.invitationID, invitationID)
        XCTAssertEqual(redemption.alertPolicyID, alertPolicyID)
    }

    func testPreviewBackendDeclineInvitationMarksPendingInviteDeclined() async throws {
        let backend = SupabaseBackendRepository.previewSeeded()
        let invitation = Invitation(
            id: UUID(),
            careProfileID: CareTapPhaseThreePreviewScenarios.careProfile.id,
            createdByUserID: CareTapPhaseThreePreviewScenarios.user.id,
            recipientDisplayName: "Chris Caregiver",
            recipientContact: "invite-code:DECLINE-BACKEND",
            offeredRole: .caregiver,
            relationshipLabel: .friend,
            status: .pending,
            inviteToken: "DECLINE-BACKEND",
            expiresAt: Date().addingTimeInterval(60 * 60),
            acceptedAt: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )

        _ = try await backend.localRepositories.invitations.upsert(invitation)

        try await backend.declineInvitation(token: invitation.inviteToken)

        let updatedInvitations = try await backend.localRepositories.invitations.invitations(
            for: invitation.careProfileID
        )

        XCTAssertEqual(updatedInvitations.first?.id, invitation.id)
        XCTAssertEqual(updatedInvitations.first?.status, .declined)
    }
}
