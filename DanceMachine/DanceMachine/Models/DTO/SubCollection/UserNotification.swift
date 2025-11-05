//
//  UserNotification.swift
//  DanceMachine
//
//  Created by Paidion on 10/30/25.
//

import Foundation

struct UserNotification: Codable, Equatable, Hashable {
  let notificationId: String
  let teamspaceId: String
  let isRead: Bool
  let createdAt: Date?
  
  init(
    notificationId: String,
    teamspaceId: String,
    isRead: Bool,
    createdAt: Date? = nil,
  ) {
    self.notificationId = notificationId
    self.teamspaceId = teamspaceId
    self.isRead = isRead
    self.createdAt = createdAt
  }
  
  enum CodingKeys: String, CodingKey {
    case notificationId = "notification_id"
    case teamspaceId = "teamspace_id"
    case isRead = "is_read"
    case createdAt = "created_at"
  }
}

extension UserNotification: EntityRepresentable {
  var entityName: CollectionType { .userNotification }
  var documentID: String { notificationId }
}
