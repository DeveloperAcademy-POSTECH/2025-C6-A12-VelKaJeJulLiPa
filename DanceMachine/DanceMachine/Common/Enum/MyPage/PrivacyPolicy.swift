//
//  PrivacyPolicy.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/31/25.
//

import Foundation

enum PrivacyPolicy: String {
  // 현재 언어 코드(ko, en, ja)
  case ko
  case en
  case ja
  
  var privacyPolicyURL: String {
    switch self {
    case .ko:
      return "https://mammoth-eyelash-f4f.notion.site/29610840462c8014ba1be32d01ef3edb"
    case .en:
      return "https://mammoth-eyelash-f4f.notion.site/Privacy-Policy-2d810840462c800fa6e2f746d27cc5fc?source=copy_link"
    case .ja:
      return "https://mammoth-eyelash-f4f.notion.site/2d810840462c803c8d6be91b8fb5615d?source=copy_link"
    }
  }
  
  var termsAgreeURL: String {
    switch self {
    case .ko:
      return "https://mammoth-eyelash-f4f.notion.site/29610840462c8038a85bf08362518b03?source=copy_link"
    case .en:
      return "https://mammoth-eyelash-f4f.notion.site/Terms-of-Service-2d810840462c807d8c2aff265c10ff38?source=copy_link"
    case .ja:
      return "https://mammoth-eyelash-f4f.notion.site/2d810840462c80dc85dcca3f3891d57d?source=copy_link"
    }
  }
  
  static var current: PrivacyPolicy {
    let languageCode = Locale.current.language.languageCode?.identifier ?? "ko"
    return PrivacyPolicy(rawValue: languageCode) ?? .ko
  }
}
