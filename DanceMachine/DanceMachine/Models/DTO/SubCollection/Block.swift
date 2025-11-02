//
//  Block.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Block: Codable {
    let blockedUserId: String

    init(
        blockedUserId: String,
    ) {
        self.blockedUserId = blockedUserId
    }

    enum CodingKeys: String, CodingKey {
        case blockedUserId = "blocked_user_id"
    }
}
