//
//  Project.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Project: Codable, Equatable {
    let projectId: UUID
    let teamspaceId: String
    let creatorId: String
    let projectName: String

    init(
        projectId: UUID,
        teamspaceId: String,
        creatorId: String,
        projectName: String
    ) {
        self.projectId = projectId
        self.teamspaceId = teamspaceId
        self.creatorId = creatorId
        self.projectName = projectName
    }

    enum CodingKeys: String, CodingKey {
        case projectId   = "project_id"
        case teamspaceId = "teamspace_id"
        case creatorId   = "creator_id"
        case projectName = "project_name"
    }
}

extension Project: Identifiable {
    var id: UUID { projectId }
}

extension Project: EntityRepresentable {
    var entityName: CollectionType { .project }
    var documentID: String { projectId.uuidString }
}
