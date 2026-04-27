import XCTest
@testable import CareTap

final class CareTapStateTests: XCTestCase {
    func testDailyProgressFractionCompleteUsesCompletedOverTotal() {
        let progress = DailyProgress(completedCount: 3, totalCount: 4)
        XCTAssertEqual(progress.fractionComplete, 0.75, accuracy: 0.0001)
    }

    func testCaregiverAlertHeadlineIncludesLovedOneName() {
        XCTAssertEqual(
            CaregiverAlertLevel.needsAttention.headline(for: "Arthur"),
            "Arthur needs attention"
        )
    }

    func testDoseFocusCompletedUsesTakenChipText() {
        XCTAssertEqual(DoseFocusState.completed.chipText, "Taken")
    }

    func testDoseFocusUpcomingUsesNextChipText() {
        XCTAssertEqual(DoseFocusState.upcoming.chipText, "Next")
    }

    func testPatientHomeStateUsesUpcomingFocusBeforeDoseWindowOpens() {
        let user = User(
            id: UUID(),
            authUserID: nil,
            appleSubject: nil,
            preferredRole: .patient,
            displayName: "Maya Patient",
            initials: "MP",
            timezoneIdentifier: "America/Los_Angeles",
            localeIdentifier: "en_US",
            isSignInWithAppleLinked: true,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )
        let profile = CareProfile(
            id: UUID(),
            createdByUserID: user.id,
            patientUserID: user.id,
            displayName: "Maya Patient",
            preferredName: "Maya",
            initials: "MP",
            avatarStyle: .patient,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let medication = Medication(
            id: UUID(),
            careProfileID: profile.id,
            nfcTagID: UUID(),
            name: "Protein Powder",
            dosage: "1 scoop",
            doseQuantity: nil,
            doseQuantityUnit: nil,
            instructions: nil,
            bottleLabel: "Tub",
            bottlePhotoLocalPath: nil,
            form: .other,
            scheduleSummary: "Every day at 9:00 AM",
            isActive: true,
            supplyCount: nil,
            createdAt: .now,
            updatedAt: .now,
            archivedAt: nil,
            syncState: .localOnly
        )
        let scheduledAt = Date().addingTimeInterval(2 * 60 * 60)
        let occurrence = DoseOccurrence(
            id: UUID(),
            careProfileID: profile.id,
            medicationID: medication.id,
            scheduleRuleID: UUID(),
            scheduledAt: scheduledAt,
            windowOpensAt: scheduledAt.addingTimeInterval(-15 * 60),
            windowClosesAt: scheduledAt.addingTimeInterval(60 * 60),
            snoozedUntil: nil,
            status: .scheduled,
            reminderState: .scheduled,
            flags: [],
            resolvedByLogID: nil,
            resolvedAt: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )

        let state = CareTapStateBuilder.patientHomeState(
            user: user,
            careProfile: profile,
            relationships: [],
            medications: [medication],
            occurrences: [occurrence],
            destination: .home
        )

        XCTAssertEqual(state.currentDose.focusState, .upcoming)
        XCTAssertEqual(state.currentDose.primaryActionTitle, "See Schedule")
    }

    func testPatientHomeStateShowsSharedCareCountWhenMultipleCaregivers() {
        let user = User(
            id: UUID(),
            authUserID: nil,
            appleSubject: nil,
            preferredRole: .patient,
            displayName: "Maya Patient",
            initials: "MP",
            timezoneIdentifier: "America/Los_Angeles",
            localeIdentifier: "en_US",
            isSignInWithAppleLinked: true,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )
        let profile = CareProfile(
            id: UUID(),
            createdByUserID: user.id,
            patientUserID: user.id,
            displayName: "Maya Patient",
            preferredName: "Maya",
            initials: "MP",
            avatarStyle: .patient,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let relationships = [
            CareRelationship(
                id: UUID(),
                caregiverUserID: UUID(),
                careProfileID: profile.id,
                label: .spouse,
                status: .active,
                permissions: [.viewAdherence],
                receivesMissedDoseAlerts: true,
                receivesRefillAlerts: true,
                createdAt: .now,
                updatedAt: .now,
                acceptedAt: .now,
                syncState: .localOnly
            ),
            CareRelationship(
                id: UUID(),
                caregiverUserID: UUID(),
                careProfileID: profile.id,
                label: .child,
                status: .active,
                permissions: [.viewAdherence],
                receivesMissedDoseAlerts: true,
                receivesRefillAlerts: true,
                createdAt: .now,
                updatedAt: .now,
                acceptedAt: .now,
                syncState: .localOnly
            )
        ]

        let state = CareTapStateBuilder.patientHomeState(
            user: user,
            careProfile: profile,
            relationships: relationships,
            medications: [],
            occurrences: [],
            destination: .home
        )

        XCTAssertEqual(state.careTeamBanner.title, "Shared with 2 caregivers")
        XCTAssertEqual(state.careTeamBanner.memberCount, 2)
    }

    func testCaregiverHomeStateReflectsMultipleLinkedPeople() {
        let caregiver = User(
            id: UUID(),
            authUserID: nil,
            appleSubject: nil,
            preferredRole: .caregiver,
            displayName: "Ella Caregiver",
            initials: "EC",
            timezoneIdentifier: "America/Los_Angeles",
            localeIdentifier: "en_US",
            isSignInWithAppleLinked: true,
            createdAt: .now,
            updatedAt: .now,
            lastActiveAt: .now,
            syncState: .localOnly
        )
        let activeProfile = CareProfile(
            id: UUID(),
            createdByUserID: UUID(),
            patientUserID: UUID(),
            displayName: "Arthur",
            preferredName: nil,
            initials: "AR",
            avatarStyle: .lovedOne,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let secondProfile = CareProfile(
            id: UUID(),
            createdByUserID: UUID(),
            patientUserID: UUID(),
            displayName: "Maya",
            preferredName: nil,
            initials: "MY",
            avatarStyle: .lovedOne,
            timezoneIdentifier: "America/Los_Angeles",
            notes: nil,
            createdAt: .now,
            updatedAt: .now,
            syncState: .localOnly
        )
        let activeRelationships = [
            CareRelationship(
                id: UUID(),
                caregiverUserID: caregiver.id,
                careProfileID: activeProfile.id,
                label: .friend,
                status: .active,
                permissions: [.viewAdherence],
                receivesMissedDoseAlerts: true,
                receivesRefillAlerts: true,
                createdAt: .now,
                updatedAt: .now,
                acceptedAt: .now,
                syncState: .localOnly
            ),
            CareRelationship(
                id: UUID(),
                caregiverUserID: UUID(),
                careProfileID: activeProfile.id,
                label: .sibling,
                status: .active,
                permissions: [.viewAdherence],
                receivesMissedDoseAlerts: true,
                receivesRefillAlerts: true,
                createdAt: .now,
                updatedAt: .now,
                acceptedAt: .now,
                syncState: .localOnly
            )
        ]

        let state = CareTapStateBuilder.caregiverHomeState(
            caregiver: caregiver,
            lovedOne: activeProfile,
            linkedProfiles: [activeProfile, secondProfile],
            activeProfileRelationships: activeRelationships,
            medications: [],
            occurrences: [],
            refillStates: [],
            destination: .home
        )

        XCTAssertEqual(state.householdSummary, "2 people linked")
        XCTAssertEqual(state.careCircleSummary, "2 caregivers on this care circle")
        XCTAssertEqual(state.linkedPeople.count, 2)
        XCTAssertEqual(state.linkedPeople.first?.displayName, "Arthur")
        XCTAssertTrue(state.linkedPeople.first?.isSelected == true)
    }

    func testCareTapDeepLinkParsesPayloadFromUniversalLinkPath() {
        let url = URL(string: "https://example.com/tag/caretap_abc-123")!

        XCTAssertEqual(CareTapDeepLink.payloadIdentifier(from: url), "caretap_abc-123")
        XCTAssertEqual(CareTapDeepLink(url: url), .tagTap(payloadIdentifier: "caretap_abc-123"))
    }

    func testCareTapDeepLinkBuildsShortcutFriendlyTagURL() {
        let medicationID = UUID(uuidString: "3F2504E0-4F89-11D3-9A0C-0305E82C3301")!
        let payloadIdentifier = CareTapDeepLink.payloadIdentifier(for: medicationID)

        XCTAssertEqual(payloadIdentifier, "caretap-3f2504e0-4f89-11d3-9a0c-0305e82c3301")
        XCTAssertEqual(
            CareTapDeepLink.tagURL(payloadIdentifier: payloadIdentifier),
            URL(string: "caretap://tag/\(payloadIdentifier)")
        )
    }

    func testCareTapDeepLinkRejectsUnexpectedPayloadCharacters() {
        let url = URL(string: "https://example.com/tag/caretap bad")!

        XCTAssertNil(CareTapDeepLink.payloadIdentifier(from: url))
        XCTAssertNil(CareTapDeepLink(url: url))
    }

    func testCareTapDeepLinkRejectsOverlongPayloads() {
        let payload = String(repeating: "a", count: 129)
        let url = URL(string: "https://example.com/tag/\(payload)")!

        XCTAssertNil(CareTapDeepLink.payloadIdentifier(from: url))
        XCTAssertNil(CareTapDeepLink.universalLinkURL(host: "example.com", payloadIdentifier: payload))
    }

    func testCareTapDeepLinkParsesWidgetDestinationScheme() {
        let url = URL(string: "caretap://workspace")!

        XCTAssertEqual(CareTapDeepLink(url: url), .destination(.workspace))
        XCTAssertEqual(CareTapDeepLink.widgetURL(destination: .home), URL(string: "caretap://home"))
    }
}
