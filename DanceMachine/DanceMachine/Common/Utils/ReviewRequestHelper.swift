//
//  ReviewRequestHelper.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/20/25.
//

import SwiftUI
import StoreKit

/// 앱 리뷰 요청을 관리하는 헬퍼
struct ReviewRequestHelper {

  /// 리뷰 요청 조건을 확인하고 표시
  /// - Parameter requestReview: SwiftUI의 requestReview 환경 액션
  static func requestReviewIfNeeded(requestReview: RequestReviewAction) {
    // 이미 리뷰 요청했는지 확인
    let hasRequestedReview = UserDefaults.standard.bool(
      forKey: UserDefaultsKey.hasRequestedReview.rawValue
    )

    guard !hasRequestedReview else { return }

    // 리뷰 요청 표시
    requestReview()

    // 플래그 설정 (한 번만 표시)
    UserDefaults.standard.set(
      true,
      forKey: UserDefaultsKey.hasRequestedReview.rawValue
    )
  }

  /// 앱 실행 횟수 증가 및 5번째 실행 시 리뷰 요청
  /// - Parameter requestReview: SwiftUI의 requestReview 환경 액션
  static func incrementLaunchCountAndRequestReviewIfNeeded(requestReview: RequestReviewAction) {
    let currentCount = UserDefaults.standard.integer(
      forKey: UserDefaultsKey.appLaunchCount.rawValue
    )
    let newCount = currentCount + 1

    UserDefaults.standard.set(
      newCount,
      forKey: UserDefaultsKey.appLaunchCount.rawValue
    )

    // 5번째 실행 시 리뷰 요청
    if newCount == 1 {
      requestReviewIfNeeded(requestReview: requestReview)
    }
  }
}
