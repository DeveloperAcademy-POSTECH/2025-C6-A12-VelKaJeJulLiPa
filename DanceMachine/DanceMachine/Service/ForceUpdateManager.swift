//
//  ForceUpdateManager.swift
//  DanceMachine
//
//  Created by Claude on 12/15/25.
//

import Foundation
import FirebaseRemoteConfig
import Combine
import UIKit

/// 앱 강제 업데이트를 관리하는 매니저
final class ForceUpdateManager: ObservableObject {

  static let shared = ForceUpdateManager()
  private init() {
    configureRemoteConfig()
  }

  private let remoteConfig = RemoteConfig.remoteConfig()

  @Published var needsForceUpdate: Bool = false
  @Published var isCheckingVersion: Bool = true
  @Published var latestVersion: String = ""
  @Published var updateMessage: String = ""

  // MARK: - Remote Config Keys
  private enum ConfigKey {
    static let minimumAppVersion = "minimum_app_version"
    static let forceUpdateEnabled = "force_update_enabled"
    static let updateMessage = "update_message"
    static let appStoreURL = "app_store_url"
  }

  // MARK: - Default Values
  private enum DefaultValue {
    static let minimumVersion = "1.0.0"
    static let forceUpdateEnabled = false
    static let updateMessage = "새로운 버전이 출시되었습니다.\n더 나은 서비스를 위해 업데이트해 주세요."
    static let appStoreURL = "https://apps.apple.com/app/id6738984498"
  }

  // MARK: - Configuration
  private func configureRemoteConfig() {
    let settings = RemoteConfigSettings()
    // 개발 중에는 빠른 테스트를 위해 0초, 프로덕션에서는 1시간 권장
    #if DEBUG
    settings.minimumFetchInterval = 0
    #else
    settings.minimumFetchInterval = 3600
    #endif
    remoteConfig.configSettings = settings

    // 기본값 설정
    remoteConfig.setDefaults([
      ConfigKey.minimumAppVersion: DefaultValue.minimumVersion as NSObject,
      ConfigKey.forceUpdateEnabled: DefaultValue.forceUpdateEnabled as NSObject,
      ConfigKey.updateMessage: DefaultValue.updateMessage as NSObject,
      ConfigKey.appStoreURL: DefaultValue.appStoreURL as NSObject
    ])
  }

  // MARK: - Public Methods

  /// Remote Config에서 버전 정보를 가져와 강제 업데이트 필요 여부를 확인
  @MainActor
  func checkForUpdate() async {
    isCheckingVersion = true

    do {
      // Remote Config fetch 및 activate
      let status = try await remoteConfig.fetch()

      if status == .success {
        try await remoteConfig.activate()
      }

      // 강제 업데이트 활성화 여부 확인
      let isForceUpdateEnabled = remoteConfig.configValue(forKey: ConfigKey.forceUpdateEnabled).boolValue

      guard isForceUpdateEnabled else {
        print("✅ 강제 업데이트가 비활성화 상태입니다.")
        needsForceUpdate = false
        isCheckingVersion = false
        return
      }

      // 최소 버전 가져오기
      let minimumVersion = remoteConfig.configValue(forKey: ConfigKey.minimumAppVersion).stringValue
      latestVersion = minimumVersion

      // 업데이트 메시지 가져오기
      updateMessage = remoteConfig.configValue(forKey: ConfigKey.updateMessage).stringValue

      // 현재 앱 버전 가져오기
      let currentVersion = getCurrentAppVersion()

      // 버전 비교
      let comparisonResult = compareVersions(current: currentVersion, minimum: minimumVersion)

      if comparisonResult == .orderedAscending {
        print("⚠️ 강제 업데이트 필요: 현재 버전(\(currentVersion)) < 최소 버전(\(minimumVersion))")
        needsForceUpdate = true
      } else {
        print("✅ 앱이 최신 상태입니다: 현재 버전(\(currentVersion)) >= 최소 버전(\(minimumVersion))")
        needsForceUpdate = false
      }

    } catch {
      print("❌ Remote Config fetch 실패:", error.localizedDescription)
      // fetch 실패 시 앱 사용 차단하지 않음 (fail-open 정책)
      needsForceUpdate = false
    }

    isCheckingVersion = false
  }

  /// App Store 앱 페이지 열기
  func openAppStore() {
    let urlString = remoteConfig.configValue(forKey: ConfigKey.appStoreURL).stringValue

    guard let url = URL(string: urlString) else {
      print("❌ 잘못된 App Store URL:", urlString)
      return
    }

    Task { @MainActor in
      await UIApplication.shared.open(url)
    }
  }

  // MARK: - Private Methods

  /// 현재 앱 버전 가져오기 (CFBundleShortVersionString)
  private func getCurrentAppVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }

  /// 시맨틱 버전 비교 (예: "1.2.0" vs "1.1.3")
  /// - Returns: .orderedAscending (current < minimum), .orderedSame, .orderedDescending (current > minimum)
  private func compareVersions(current: String, minimum: String) -> ComparisonResult {
    let currentComponents = current.split(separator: ".").compactMap { Int($0) }
    let minimumComponents = minimum.split(separator: ".").compactMap { Int($0) }

    let maxLength = max(currentComponents.count, minimumComponents.count)

    for i in 0..<maxLength {
      let currentPart = i < currentComponents.count ? currentComponents[i] : 0
      let minimumPart = i < minimumComponents.count ? minimumComponents[i] : 0

      if currentPart < minimumPart {
        return .orderedAscending
      } else if currentPart > minimumPart {
        return .orderedDescending
      }
    }

    return .orderedSame
  }
}
