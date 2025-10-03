//
//  UserStatus.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

// 계정 상태
enum UserStatus: String, Codable {
    case active = "active"
    case suspended = "suspended"
    case deleted = "deleted"
}
