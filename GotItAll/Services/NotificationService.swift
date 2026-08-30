import Foundation
import UserNotifications

enum NotificationServiceError: LocalizedError, Equatable {

    // MARK: - Constants
    case invalidDate
    case permissionDenied

    // MARK: - Public Properties
    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return .notificationInvalidDate
        case .permissionDenied:
            return .notificationPermissionDenied
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

        let content = UNMutableNotificationContent()
        content.body = String(format: .notificationText, listTitle)
        content.sound = .default
        content.title = .appName

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: listID),
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Private Methods
    private func notificationIdentifier(for listID: UUID) -> String {
        "shopping-list-\(listID.uuidString)"
    }

    private func requestAuthorizationIfNeeded() async throws {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            return
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
