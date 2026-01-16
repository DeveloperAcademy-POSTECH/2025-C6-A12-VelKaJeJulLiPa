//
//  Reply.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Reply: Codable {
    
    let replyId: String
    let feedbackId: String
    let authorId: String
    let content: String
    let taggedUserIds: [String]
    var createdAt: Date? = nil
    
    init(
        replyId: String,
        feedbackId: String,
        authorId: String,
        content: String,
        taggedUserIds: [String],
        createdAt: Date? = nil
    ) {
        self.replyId = replyId
        self.feedbackId = feedbackId
        self.authorId = authorId
        self.content = content
        self.taggedUserIds = taggedUserIds
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case replyId = "reply_id"
        case feedbackId = "feedback_id"
        case authorId = "author_id"
        case content = "content"
        case taggedUserIds = "tagged_user_ids"
        case createdAt = "created_at"
    }
}

extension Reply: EntityRepresentable {
    var entityName: CollectionType { .feedback }
    var documentID: String { replyId }
}

extension Reply: Identifiable {
  var id: String { replyId }
}
