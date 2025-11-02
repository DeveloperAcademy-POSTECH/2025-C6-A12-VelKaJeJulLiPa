//
//  UserTeamspace.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct UserTeamspace: Codable, Equatable, Hashable {
    let teamspaceId: String

    init(teamspaceId: String) {
        self.teamspaceId = teamspaceId
    }
    
    enum CodingKeys: String, CodingKey {
        case teamspaceId = "teamspace_id"
    }
}

extension UserTeamspace: EntityRepresentable {
    var entityName: CollectionType { .userTeamspace }
    var documentID: String { teamspaceId }
    var asDictionary: [String: Any]? {
        [CodingKeys.teamspaceId.rawValue: teamspaceId]
    }
}
