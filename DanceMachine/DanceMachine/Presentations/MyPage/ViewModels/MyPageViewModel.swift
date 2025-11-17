//
//  MyPageViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import Combine
import SwiftUI


final class MyPageViewModel: ObservableObject {
  
  var myId: String { FirebaseAuthManager.shared.userInfo?.email ?? "Unknown" }
  var myName: String { FirebaseAuthManager.shared.userInfo?.name ?? "Unknown" }
  var appVersion: String {
    guard let info = Bundle.main.infoDictionary,
          let currentVersion = info["CFBundleShortVersionString"] as? String,
          let buildNumber = info["CFBundleVersion"] as? String else {
      return "Unknown"
    }
    
    return "\(currentVersion) (\(buildNumber))"
  }
  
  //MARK: - 알림 수신(기본 설정앱으로 이동)
  func openAppSettings() {
    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(settingsURL)
  }
}
