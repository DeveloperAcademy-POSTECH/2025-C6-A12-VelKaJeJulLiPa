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
  var projectName: String
  var updatedAt: Date?
  
  init(
    projectId: UUID,
    teamspaceId: String,
    creatorId: String,
    projectName: String,
    updatedAt: Date? = nil
  ) {
    self.projectId = projectId
    self.teamspaceId = teamspaceId
    self.creatorId = creatorId
    self.projectName = projectName
    self.updatedAt = updatedAt
  }
  
  enum CodingKeys: String, CodingKey {
    case projectId   = "project_id"
    case teamspaceId = "teamspace_id"
    case creatorId   = "creator_id"
    case projectName = "project_name"
    case updatedAt   = "updated_at"
  }
}

extension Project: Identifiable {
  var id: UUID { projectId }
}

extension Project: EntityRepresentable {
  var entityName: CollectionType { .project }
  var documentID: String { projectId.uuidString }
}
