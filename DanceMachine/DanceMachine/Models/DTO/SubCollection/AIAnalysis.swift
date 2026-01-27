//
//  AIAnalysis.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/23/26.
//

import Foundation
import DancePoseAnalysis

struct AIAnalysis: Codable, Hashable {
  let analysisId: UUID
  let videoId: String
  let feedback: VisionFeedback  // Gemini 3 Vision 피드백

  init(
    analysisId: UUID = UUID(),
    feedback: VisionFeedback,
    videoId: String
  ) {
    self.analysisId = analysisId
    self.videoId = videoId
    self.feedback = feedback
  }

  enum CodingKeys: String, CodingKey {
    case analysisId  = "analysis_id"
    case videoId     = "video_id"
    case feedback
  }
}

// MARK: - EntityRepresentable

extension AIAnalysis: EntityRepresentable {
  var entityName: CollectionType { .aiAnalysis }
  var documentID: String { analysisId.uuidString }
}

// MARK: - Identifiable

extension AIAnalysis: Identifiable {
  var id: String { analysisId.uuidString }
}
