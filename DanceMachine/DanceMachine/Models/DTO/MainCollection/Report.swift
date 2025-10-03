//
//  Report.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

struct Report: Codable {
    let reportId: UUID
    let reporterId: String
    let reportedId: String
    let status: ReportStatus.RawValue
    let feedbackId: String?
    let replyId: String?
    let videoId: String?
    let type: String
    let description: String

    init(
        reportId: UUID,
        reporterId: String,
        reportedId: String,
        status: ReportStatus = .reviewing,
        feedbackId: String? = nil,
        replyId: String? = nil,
        videoId: String? = nil,
        type: String,
        description: String
    ) {
        self.reportId = reportId
        self.reporterId = reporterId
        self.reportedId = reportedId
        self.status = status.rawValue
        self.feedbackId = feedbackId
        self.replyId = replyId
        self.videoId = videoId
        self.type = type
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case reportId     = "report_id"
        case reporterId   = "reporter_id"
        case reportedId   = "reported_id"
        case status
        case feedbackId   = "feedback_id"
        case replyId      = "reply_id"
        case videoId      = "video_id"
        case type
        case description
    }
}

extension Report: EntityRepresentable {
    var entityName: CollectionType { .report }
    var documentID: String { reportId.uuidString }
}
