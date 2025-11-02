//
//  UserNotification.swift
//  DanceMachine
//
//  Created by Paidion on 10/30/25.
//

struct UserNotification: Codable, Equatable, Hashable {
  let notificationId: String
  let teamspaceId: String
  let isRead: Bool
  
  init(notificationId: String, teamspaceId: String, isRead: Bool) {
    self.notificationId = notificationId
    self.teamspaceId = teamspaceId
    self.isRead = isRead
  }
  
  enum CodingKeys: String, CodingKey {
    case notificationId = "notification_id"
    case teamspaceId = "teamspace_id"
    case isRead = "is_read"
  }
}

extension UserNotification: EntityRepresentable {
  var entityName: CollectionType { .userNotification }
  var documentID: String { notificationId }
  var asDictionary: [String: Any]? {
    [
      CodingKeys.notificationId.rawValue: notificationId,
      CodingKeys.teamspaceId.rawValue: teamspaceId,
      CodingKeys.isRead.rawValue: isRead
    ]
  }
}
