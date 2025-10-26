//
//  WriteStrategy.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

/// 쓰기 전략 → 타임스탬프 필드명 매핑
/// - create: created_at
/// - update: updated_at
/// - join: joined_at
/// - userStrategy: last_login_at
/// - invite:
enum WriteStrategy: String {
    case create = "created_at"
    case update = "updated_at"
    case join = "joined_at"
    case userStrategy = "last_login_at"
    case userUpdateStrategy
    case invite = "expires_at"
}
