//
//  UserDefaultsKey.swift
//  DanceMachine
//
//  Created by Paidion on 10/13/25.
//

import Foundation

enum UserDefaultsKey: String, CaseIterable {
  case hasLaunchedBefore
  case fcmToken
  case didCompleteAuthFlow
  case appLaunchCount
  case hasRequestedReview
}
