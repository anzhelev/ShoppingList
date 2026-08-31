import UserNotifications
import XCTest
@testable import GotItAll

final class NotificationServiceTests: XCTestCase {

    // MARK: - Public Methods
    func testCancelRemovesPendingAndDeliveredNotification() {
        let center = MockUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)
        let listID = UUID()

        service.cancelNotification(for: listID)

        let expectedIdentifier = "shopping-list-\(listID.uuidString)"
        XCTAssertEqual(center.removedDeliveredIdentifiers, [expectedIdentifier])
        XCTAssertEqual(center.removedPendingIdentifiers, [expectedIdentifier])
    }

    func testDeniedPermissionPreventsScheduling() async {
        let center = MockUserNotificationCenter(
            settings: UserNotificationSettings(alertSetting: .disabled, authorizationStatus: .denied)
        )
        let service = NotificationService(notificationCenter: center)

        await assertScheduleThrows(.permissionDenied, service: service)
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testInvalidDatePreventsScheduling() async {
        let center = MockUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)

        await assertScheduleThrows(.invalidDate, service: service, date: Date().addingTimeInterval(-1))
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testMissingPendingRequestReportsSchedulingFailure() async {
        let center = MockUserNotificationCenter()
        center.pendingRequestsOverride = []
        let service = NotificationService(notificationCenter: center)

        await assertScheduleThrows(.schedulingFailed, service: service)
    }

    func testNotDeterminedPermissionRequestsAuthorization() async throws {
        let center = MockUserNotificationCenter(
            settings: UserNotificationSettings(alertSetting: .notSupported, authorizationStatus: .notDetermined)
        )
        let service = NotificationService(notificationCenter: center)

        try await service.scheduleNotification(
            for: UUID(),
            listTitle: "Groceries",
            date: Date().addingTimeInterval(60)
        )

        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertEqual(center.requestedAuthorizationOptions, [.alert, .sound])
        XCTAssertEqual(center.addedRequests.count, 1)
    }

    func testScheduleCreatesExpectedNotificationRequest() async throws {
        let center = MockUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)
        let listID = UUID()
        let listTitle = "Groceries"

        try await service.scheduleNotification(
            for: listID,
            listTitle: listTitle,
            date: Date().addingTimeInterval(60)
        )

        let request = try XCTUnwrap(center.addedRequests.first)
        XCTAssertEqual(request.identifier, "shopping-list-\(listID.uuidString)")
        XCTAssertEqual(request.content.title, String.appName)
        XCTAssertEqual(request.content.body, String(format: .notificationText, listTitle))
        XCTAssertNotNil(request.content.sound)
        XCTAssertNotNil(request.trigger as? UNTimeIntervalNotificationTrigger)
    }

    // MARK: - Private Methods
    private func assertScheduleThrows(
        _ expectedError: NotificationServiceError,
        service: NotificationService,
        date: Date = Date().addingTimeInterval(60)
    ) async {
        do {
            try await service.scheduleNotification(for: UUID(), listTitle: "Groceries", date: date)
            XCTFail("Expected \(expectedError), but scheduling succeeded")
        } catch {
            XCTAssertEqual(error as? NotificationServiceError, expectedError)
        }
    }
}

private final class MockUserNotificationCenter: UserNotificationCenterProtocol {

    // MARK: - Public Properties
    var addedRequests: [UNNotificationRequest] = []
    var authorizationRequestCount = 0
    var authorizationResult = true
    var pendingRequestsOverride: [UNNotificationRequest]?
    var removedDeliveredIdentifiers: [String] = []
    var removedPendingIdentifiers: [String] = []
    var requestedAuthorizationOptions: UNAuthorizationOptions = []
    var settings: UserNotificationSettings

    // MARK: - Initializers
    init(
        settings: UserNotificationSettings = UserNotificationSettings(
            alertSetting: .enabled,
            authorizationStatus: .authorized
        )
    ) {
        self.settings = settings
    }

    // MARK: - Public Methods
    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func notificationSettings() async -> UserNotificationSettings {
        settings
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pendingRequestsOverride ?? addedRequests
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers = identifiers
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedPendingIdentifiers = identifiers
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationRequestCount += 1
        requestedAuthorizationOptions = options
        return authorizationResult
    }
}
