//
//  Block.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Block: Codable {
    let blockedUserID: String

    init(
        blockedUserID: String,
    ) {
        self.blockedUserID = blockedUserID
    }

    enum CodingKeys: String, CodingKey {
        case blockedUserID = "blocked_user_id"
    }
}
