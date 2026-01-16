//
//  User.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation
import FirebaseAuth

struct User: Codable, Equatable {

  let userId: String
  let email: String
  let name: String
  let loginType: LoginType.RawValue
  let status: UserStatus.RawValue
  let fcmToken: String
  let termsAgreed: Bool
  let privacyAgreed: Bool
  let country: String
  var updatedAt: Date?

  init(
    userId: String,
    email: String,
    name: String,
    loginType: LoginType,
    status: UserStatus = .active,
    fcmToken: String,
    termsAgreed: Bool,
    privacyAgreed: Bool,
    country: String = User.detectCountryFromLocale(),
    updatedAt: Date? = nil
  ) {
    self.userId = userId
    self.email = email
    self.name = name
    self.loginType = loginType.rawValue
    self.status = status.rawValue
    self.fcmToken = fcmToken
    self.termsAgreed = termsAgreed
    self.privacyAgreed = privacyAgreed
    self.country = country
    self.updatedAt = updatedAt
  }

  /// 기기 Locale에서 국가 코드 감지
  /// - Returns: 소문자 국가 코드 (kr, us, jp) - 지원하지 않는 국가는 "kr" 반환
  static func detectCountryFromLocale() -> String {
    let regionCode = Locale.current.region?.identifier ?? "KR"
    let countryCode = regionCode.lowercased()

    // 지원하는 국가 목록
    let supportedCountries = ["kr", "us", "jp"]

    if supportedCountries.contains(countryCode) {
      return countryCode
    } else {
      // 지원하지 않는 국가는 기본값 "kr"
      return "kr"
    }
  }

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case email
    case name
    case loginType = "login_type"
    case status
    case fcmToken = "fcm_token"
    case termsAgreed = "terms_agreed"
    case privacyAgreed = "privacy_agreed"
    case country
    case updatedAt     = "updated_at"
  }

  // Custom decoder: country 필드가 없으면 자동 감지
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userId = try container.decode(String.self, forKey: .userId)
    email = try container.decode(String.self, forKey: .email)
    name = try container.decode(String.self, forKey: .name)
    loginType = try container.decode(String.self, forKey: .loginType)
    status = try container.decode(String.self, forKey: .status)
    fcmToken = try container.decode(String.self, forKey: .fcmToken)
    termsAgreed = try container.decode(Bool.self, forKey: .termsAgreed)
    privacyAgreed = try container.decode(Bool.self, forKey: .privacyAgreed)

    // country 필드가 없으면 자동 감지
    country = try container.decodeIfPresent(String.self, forKey: .country) ?? User.detectCountryFromLocale()

    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
  }
}

extension User: Identifiable {
  var id: String { UUID().uuidString }
}

extension User: EntityRepresentable {
  var entityName: CollectionType { .users }
  var documentID: String { userId }
}
