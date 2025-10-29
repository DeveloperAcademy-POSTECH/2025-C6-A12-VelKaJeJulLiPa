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
    static var pendingDeeplinkURL: URL?   // 딥링크를 임시 저장하는 변수
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        print("🔥 FirebaseApp configured")
        return true
    }
    
    // 푸시 알림 등록 실패 시 호출되는 메서드
    // 푸시 알림 등록(registerForRemoteNotifications)은 현재 홈화면에서 최초 로그인 하면 실행하고 있음
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        print("2️⃣ 2번: 포그라운드에서 알림 올 때 작동함") // FIXME: - 디버그 코드 제거
        
        let userInfo = notification.request.content.userInfo
        print("userInfo - 2: \(userInfo)") // FIXME: - 디버그 코드 제거
        
        return [[.list, .banner, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        print("3️⃣ 3번: 백그라운드에서 푸시 눌렀을 때 작동함") // FIXME: - 디버그 코드 제거
        
        let userInfo = response.notification.request.content.userInfo
        print("userInfo - 3: \(userInfo)") // FIXME: - 디버그 코드 제거
        
        if let deeplinkString = userInfo["deeplink"] as? String,
           let deeplinkURL = URL(string: deeplinkString) {
            print("🌐 Deeplink detected:", deeplinkURL.absoluteString)
            
            print(UIApplication.shared.applicationState)
            
            // 포그라운드이면 딥링크 알림(이벤트)를 전달
            // 종료 또는 백드라운드 상태이면, 나중에 처리할 수 있도록 링크 저장
            if UIApplication.shared.applicationState == .active {
                print("🔥 포그라운드")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .didReceiveDeeplink,
                        object: deeplinkURL
                    )
                }
            } else {
                AppDelegate.pendingDeeplinkURL = deeplinkURL
            }
        } else {
            print("⚠️ No deeplink found in notification payload")
        }
        
        
    }
}


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
