//
//  Members.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Members: Codable {
    
    let userID: String
    
    init(userID: String) {
        self.userID = userID
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
    
}
