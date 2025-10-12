//
//  User.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation
import FirebaseAuth

struct User: Codable {
    
    let userId: String
    let email: String?
    let name: String?
    let loginType: LoginType.RawValue
    let status: UserStatus.RawValue
    let fcmToken: String
    let termsAgreed: Bool
    let privacyAgreed: Bool
    
    //FIXME: FCM TOKEN MUST BE SAVED
    init(user: FirebaseAuth.User) {
        self.userId = user.uid
        self.email = user.email
        self.name = user.displayName
        self.loginType = LoginType.apple.rawValue
        self.status = UserStatus.active.rawValue
        self.fcmToken = "FAKE_FCM_TOKEN"
        self.termsAgreed = true
        self.privacyAgreed = true
    }

    init(
        userId: String,
        email: String,
        name: String,
        loginType: LoginType,
        status: UserStatus = .active,
        fcmToken: String,
        termsAgreed: Bool,
        privacyAgreed: Bool
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.loginType = loginType.rawValue
        self.status = status.rawValue
        self.fcmToken = fcmToken
        self.termsAgreed = termsAgreed
        self.privacyAgreed = privacyAgreed
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
    }
}

extension User: EntityRepresentable {
    var entityName: CollectionType { .users }
    var documentID: String { userId }
}
