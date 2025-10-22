//
//  AppDelegate.swift
//  DanceMachine
//
//  Created by Paidion on 10/21/25.
//

import UIKit
import UserNotifications

import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate { // TODO: If necessary change UIResponder into NSObject
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        print("🔥 FirebaseApp configured")
        return true
    }
    
    // [START receive_message]
    /// 백그라운드에서 푸시 알림을 탭했을 때 실행되는 메서드
    @MainActor
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        print("Call exportDeliveryMetricsToBigQuery() from AppDelegate")
        Messaging.serviceExtension().exportDeliveryMetricsToBigQuery(withMessageInfo: userInfo)
        return UIBackgroundFetchResult.newData
    }
    
    // [END receive_message]
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs token retrieved: \(token)")
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
}

// [START ios_10_message_handling]

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        return [[.list, .banner, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // [START_EXCLUDE]
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        // [END_EXCLUDE]
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
    }
}

//extension AppDelegate: UNUserNotificationCenterDelegate {
//
//    // 백그라운드에서 푸시 알림을 탭했을 때 실행
//    func application(_ application: UIApplication,
//                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Messaging.messaging().apnsToken = deviceToken
//        print("APNS token: \(deviceToken)")
//    }
//
//    // Foreground(앱 켜진 상태)에서도 알림 오는 설정
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.list, .banner])
//    }
//}

// [END ios_10_message_handling]

//extension AppDelegate: MessagingDelegate {
//    // [START refresh_token]
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase registration token: \(String(describing: fcmToken))")
//        
//        let dataDict: [String: String] = ["token": fcmToken ?? ""]
//        NotificationCenter.default.post(
//            name: NSNotification.Name("FCMToken"),
//            object: nil,
//            userInfo: dataDict
//        )
//        // TODO: If necessary send token to application server.
//        // Note: This callback is fired at each app startup and whenever a new token is generated.
//        if let userId = FirebaseAuthManager.shared.user?.uid, let fcmToken = fcmToken {
//            Task {
//                try await FirestoreManager.shared.updateFields(collection: .users, documentId: userId, asDictionary: [ User.CodingKeys.fcmToken.rawValue: fcmToken])
//            }
//            print("Updated fcmToken")
//        }
//        
//        print("AppDelegate Auth uid", FirebaseAuthManager.shared.user?.uid)
//        print("AppDelegate fcmToken", fcmToken)
//        
//    }
//}

/// FCM 토큰이 갱신되면 사용자 정보에 업데이트
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("📲 FCM token updated: \(fcmToken)")
        
        let dataDict: [String: String] = ["token": fcmToken]
        NotificationCenter.default.post(
            name: NSNotification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        // 로그인 상태일 때 Firestore에 업데이트
        if let userId = FirebaseAuthManager.shared.user?.uid {
            Task {
                try await FirestoreManager.shared.updateFields(
                    collection: .users,
                    documentId: userId,
                    asDictionary: [User.CodingKeys.fcmToken.rawValue: fcmToken]
                )
                print("✅ Firestore updated with new fcmToken for \(userId)")
            }
        }
    }
}

// [END refresh_token]
