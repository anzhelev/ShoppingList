import Foundation
import UserNotifications

enum NotificationServiceError: LocalizedError, Equatable {

    // MARK: - Constants
    case invalidDate
    case permissionDenied
    case schedulingFailed

    // MARK: - Public Properties
    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return .notificationInvalidDate
        case .permissionDenied:
            return .notificationPermissionDenied
        case .schedulingFailed:
            return .notificationSchedulingFailed
        }
    }
}

protocol NotificationServiceProtocol {
    func cancelNotification(for listID: UUID)
    func scheduleNotification(for listID: UUID, listTitle: String, date: Date) async throws
}

final class NotificationService: NotificationServiceProtocol {

    // MARK: - Private Properties
    private let notificationCenter: UNUserNotificationCenter

    // MARK: - Initializers
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public Methods
    func cancelNotification(for listID: UUID) {
        let identifier = notificationIdentifier(for: listID)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func scheduleNotification(for listID: UUID, listTitle: String, date: Date) async throws {
        guard date > Date() else {
            throw NotificationServiceError.invalidDate
        }

        try await requestAuthorizationIfNeeded()

        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval >= 1 else {
            throw NotificationServiceError.invalidDate
        }

        let content = UNMutableNotificationContent()
        content.body = String(format: .notificationText, listTitle)
        content.sound = .default
        content.title = .appName

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: listID),
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)

        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        guard pendingRequests.contains(where: { $0.identifier == request.identifier }) else {
            throw NotificationServiceError.schedulingFailed
        }
    }

    // MARK: - Private Methods
    private func notificationIdentifier(for listID: UUID) -> String {
        "shopping-list-\(listID.uuidString)"
    }

    private func requestAuthorizationIfNeeded() async throws {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            guard settings.alertSetting == .enabled else {
                throw NotificationServiceError.permissionDenied
            }
        case .notDetermined:
            guard try await notificationCenter.requestAuthorization(options: [.alert, .sound]) else {
                throw NotificationServiceError.permissionDenied
            }
        case .denied:
            throw NotificationServiceError.permissionDenied
        @unknown default:
            throw NotificationServiceError.permissionDenied
        }
    }
}
