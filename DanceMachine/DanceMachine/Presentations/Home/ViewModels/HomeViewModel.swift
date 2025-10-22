//
//  HomeViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import UserNotifications
import UIKit


final class HomeViewModel {
    
    /// 홈 진입 시 푸시 알림 권한 상태를 점검하고, 필요할 경우만 요청
    func setupNotificationAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        // 한 번도 요청하지 않은 경우에만 푸시 알림 권한 요청
        case .notDetermined:
            requestNotificationAuthorization()
        case .denied:
            print("User has denied notifications")
        case .authorized, .provisional, .ephemeral:
            print("Notifications already authorized.")
        @unknown default:
            print("Unknown notification authorization status.")
        }
    }
    
    /// 푸시 알림 권한을 사용자에게 물어봄 + 권한 승인하면 APNs에 등록
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        center.requestAuthorization(options: authOptions) { granted, error in
            print("Notification permission state: \(granted)")
            if granted {
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Error requesting notifications: \(error)")
            }
        }
    }
}
