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
    
    init(
        replyId: String,
        feedbackId: String,
        authorId: String,
        content: String,
        taggedUserIds: [String]
    ) {
        self.replyId = replyId
        self.feedbackId = feedbackId
        self.authorId = authorId
        self.content = content
        self.taggedUserIds = taggedUserIds
    }
    
    enum CodingKeys: String, CodingKey {
        case replyId = "reply_id"
        case feedbackId = "feedback_id"
        case authorId = "author_id"
        case content = "content"
        case taggedUserIds = "tagged_user_ids"
    }
    
}
