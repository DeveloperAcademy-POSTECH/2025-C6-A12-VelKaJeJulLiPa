//
//  Members.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Members: Codable {
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

extension Members: EntityRepresentable {
    var entityName: CollectionType { .members }
    var documentID: String { userId }
    var asDictionary: [String : Any]? {
        [Members.CodingKeys.userId.rawValue: userId]
    }
}
