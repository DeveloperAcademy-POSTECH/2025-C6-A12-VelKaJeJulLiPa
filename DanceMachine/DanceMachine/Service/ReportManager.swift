//
//  ReportManager.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import Foundation

import FirebaseFirestore

final class ReportManager {
  static let shared = ReportManager()
  private init() {}
  
  /// 신고하기
  /// - 영상 / 피드백 / 답글 모두 신고 가능합니다. 각각 필요한 정보만 메서드에 넣어서 신고합니다.
  /// - 예를 들어, 영상 관련 신고를 한다면, 영상 document ID만 제대로 저장되고, 나머지는 빈 문자열로 서버에 저장합니다.
  /// - 신고 유형은 추후 확장성을 고려해서 미리 만들어두었습니다. 현재는 기타(other) 유형으로 모두 저장합니다.
  /// - Parameters:
  ///   - reporterId: 현재 사용자 ID
  ///   - reportedId: 신고 당하는 사용자 ID
  ///   - videoId: 영상 document ID
  ///   - feedback: 피드백 document ID
  ///   - reply: 댓글 document ID
  ///   - type: 신고 유형 (현재는 모두 기타 유형으로 저장됨)
  ///   - reportContentType: 신고 콘텐츠 유형 (영상, 피드백, 답글)
  ///   - description: 신고 사유
  func createReport(
    by reporterId: String,
    to reportedId: String,
    videoId: String? = nil,
    feedbackId: String? = nil,
    replyId: String? = nil,
    type: ReportType,
    reportContentType: ReportContentType,
    reason desciption: String,
  ) async throws {
    let report = Report(
      reportId: UUID(),
      reporterId: reporterId,
      reportedId: reportedId,
      videoId: videoId,
      feedbackId: feedbackId,
      replyId: replyId,
      type: ReportType.other,
      reportContentType: reportContentType,
      description: desciption
    )
    
    do {
      try await FirestoreManager.shared.create(report)
    } catch {
      throw ReportError.reportFailed(underlying: error)
    }
  }
}
