//
//  Notification.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Notification: Codable {
    let notificationId: UUID
    let senderId: String
    let receiverIds: [String]
    let feedbackId: String
    let replyId: String?
    let createdAt: Date
    let videoId: String
    let content: String
    let teamspaceId: String
    
    init(
        notificationId: UUID,
        senderId: String,
        receiverIds: [String],
        feedbackId: String,
        replyId: String?,
        createdAt: Date,
        videoId: String,
        content: String,
        teamspaceId: String
    ) {
        self.notificationId = notificationId
        self.senderId = senderId
        self.receiverIds = receiverIds
        self.feedbackId = feedbackId
        self.replyId = replyId
        self.createdAt = createdAt
        self.videoId = videoId
        self.content = content
        self.teamspaceId = teamspaceId
    }
    
    enum CodingKeys: String, CodingKey {
        case notificationId   = "notification_id"
        case senderId = "sender_id"
        case receiverIds   = "receiver_ids"
        case feedbackId = "feedback_id"
        case replyId = "reply_id"
        case createdAt = "created_at"
        case videoId = "video_id"
        case content = "content"
        case teamspaceId = "teamspace_id"
    }
    
}

extension Notification: EntityRepresentable {
    var entityName: CollectionType { .notification }
    var documentID: String { notificationId.uuidString }
}


