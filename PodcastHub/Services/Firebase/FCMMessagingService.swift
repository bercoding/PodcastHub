import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

protocol FCMMessagingServiceType: UNUserNotificationCenterDelegate {
    func requestAuthorization() async throws -> Bool
    func registerForRemoteNotifications()
    func token() async throws -> String?
}

final class FCMMessagingService: NSObject, FCMMessagingServiceType {
    private let messaging = Messaging.messaging()

    override init() {
        super.init()
        messaging.delegate = self
    }

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func token() async throws -> String? {
        try await messaging.token()
    }
}

extension FCMMessagingService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "nil")")
    }
}

extension FCMMessagingService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
