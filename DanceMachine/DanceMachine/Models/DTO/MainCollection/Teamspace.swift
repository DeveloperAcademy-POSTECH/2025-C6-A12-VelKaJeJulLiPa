//
//  Teamspace.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

nonisolated
struct Teamspace: Codable, Equatable {
    let teamspaceId: UUID
    let ownerId: String
    let teamspaceName: String

    init(
        teamspaceId: UUID,
        ownerId: String,
        teamspaceName: String
    ) {
        self.teamspaceId = teamspaceId
        self.ownerId = ownerId
        self.teamspaceName = teamspaceName
    }

    enum CodingKeys: String, CodingKey {
        case teamspaceId   = "teamspace_id"
        case ownerId       = "owner_id"
        case teamspaceName = "teamspace_name"
    }
}

extension Teamspace: EntityRepresentable {
    var entityName: CollectionType { .teamspace }
    var documentID: String { teamspaceId.uuidString }
}
