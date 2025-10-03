//
//  UserTeamspace.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct UserTeamspace {
    
    let teamspaceID: String
    
    init(teamspaceID: String) {
        self.teamspaceID = teamspaceID
    }
    
    enum CodingKeys: String, CodingKey {
        case teamspaceID = "teamspace_id"
    }
}
