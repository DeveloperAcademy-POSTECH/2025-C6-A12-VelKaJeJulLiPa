//
//  Feedback.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Feedback: Codable {
    let feedbackId: UUID
    let videoId: String
    let authorId: String
    let content: String
    let taggedUserIds: [String]
    let startTime: Double?
    let endTime: Double?

    init(
        feedbackId: UUID,
        videoId: String,
        authorId: String,
        content: String,
        taggedUserIds: [String] = [],
        startTime: Double? = nil,
        endTime: Double? = nil
    ) {
        self.feedbackId = feedbackId
        self.videoId = videoId
        self.authorId = authorId
        self.content = content
        self.taggedUserIds = taggedUserIds
        self.startTime = startTime
        self.endTime = endTime
    }

    enum CodingKeys: String, CodingKey {
        case feedbackId    = "feedback_id"
        case videoId       = "video_id"
        case authorId      = "author_id"
        case content
        case taggedUserIds = "tagged_user_ids"
        case startTime     = "start_time"
        case endTime       = "end_time"
    }
}

extension Feedback: EntityRepresentable {
    var entityName: CollectionType { .feedback }
    var documentID: String { feedbackId.uuidString }
}
