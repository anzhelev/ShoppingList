import CoreData
import UIKit
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Public Properties
    private(set) var persistentStoreError: Error?

    // MARK: - Private Properties
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ShoppingList")
        container.persistentStoreDescriptions.forEach {
            $0.shouldInferMappingModelAutomatically = true
            $0.shouldMigrateStoreAutomatically = true
        }
        container.loadPersistentStores { [weak self] _, error in
            guard let error else {
                return
            }

            self?.persistentStoreError = error
            debugPrint("@@@ Persistent store loading failed: \(error.localizedDescription)")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    // MARK: - Public Methods
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func saveContext() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

// MARK: - Shared Core Data Context
extension AppDelegate {

    static var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    static var context: NSManagedObjectContext {
        guard let appDelegate else {
            preconditionFailure("UIApplication delegate is unavailable")
        }

        return appDelegate.persistentContainer.viewContext
    }
}
