//
//  CreateReportViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import Foundation


final class CreateReportViewModel {
  
  /// 신고 기능 메서드
  /// - 영상 / 피드백 / 답글 모두 신고 가능합니다. 각각 필요한 정보만 메서드에 넣어서 신고합니다.
  /// - 예를 들어, 영상만 있다면, 영상 정보만 메서드로 넘겨주어서 처리합니다.
  /// - 신고 유형은 추후 확장성을 고려해서 미리 만들어두었습니다. 현재는 기타(other) 유형으로 모두 저장합니다.
  /// - Parameters:
  ///   - reportedId: 신고 당하는 사용자 ID
  ///   - video: 영상 정보
  ///   - feedback: 피드백 정보
  ///   - reply: 댓글 정보
  ///   - type: 신고 유형
  ///   - reportContentType: 신고 콘텐츠 유형 (영상, 피드백, 답글)
  ///   - description: 신고 사유
  func createReport(
    reportedId: String,
    video: Video?,
    feedback: Feedback?,
    reply: Reply?,
    type: ReportType = .other,
    reportContentType: ReportContentType,
    description: String,
    
  ) async throws {
    do {
      try await ReportManager.shared.createReport(
        by: FirebaseAuthManager.shared.userInfo?.userId ?? "",
        to: reportedId,
        videoId: video?.id ?? "",
        feedbackId: feedback?.id ?? "",
        replyId: reply?.replyId ?? "",
        type: type,
        reportContentType: reportContentType,
        reason: description
      )
    } catch {
      print(ReportError.reportFailed(underlying: error))
    }
  }
}

