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
  let videoId: String?
  let feedbackId: String?
  let replyId: String?
  let type: String
  let reportContentType: String
  let description: String
  var createdAt: Date? = nil
  
  init(
    reportId: UUID,
    reporterId: String,
    reportedId: String,
    status: ReportStatus = .pending,
    videoId: String? = nil,
    feedbackId: String? = nil,
    replyId: String? = nil,
    type: ReportType,
    reportContentType: ReportContentType,
    description: String,
    createdAt: Date? = nil
  ) {
    self.reportId = reportId
    self.reporterId = reporterId
    self.reportedId = reportedId
    self.status = status.rawValue
    self.videoId = videoId
    self.feedbackId = feedbackId
    self.replyId = replyId
    self.type = type.rawValue
    self.reportContentType = reportContentType.rawValue
    self.description = description
    self.createdAt = createdAt
  }
  
  enum CodingKeys: String, CodingKey {
    case reportId = "report_id"
    case reporterId = "reporter_id"
    case reportedId = "reported_id"
    case status
    case videoId = "video_id"
    case feedbackId = "feedback_id"
    case replyId = "reply_id"
    case type
    case reportContentType = "report_content_type"
    case description
    case createdAt = "created_at"
  }
}

extension Report: EntityRepresentable {
  var entityName: CollectionType { .report }
  var documentID: String { reportId.uuidString }
}
