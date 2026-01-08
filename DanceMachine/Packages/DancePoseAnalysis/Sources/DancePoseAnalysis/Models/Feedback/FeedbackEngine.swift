//
//  File.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/5/26.
//

import Foundation

public protocol FeedbackEngine {
  
  /// 1. 단체 안무 분석 (여러 명이 한 영상)
  ///
  /// **입력 :** 한 영상에서 추출한 여러 사람의 포즈
  /// **출력 :** 누가 다른지, 어떻게 다른지
  ///
  /// **예시 :**
  /// ```swift
  /// // 5명의 포즈 데이터
  /// let groupPoses = [
  ///     (personId: "A", poses: [PoseData]),
  ///     (personId: "B", poses: [PoseData]),
  ///     (personId: "C", poses: [PoseData]),
  ///     (personId: "D", poses: [PoseData]),
  ///     (personId: "E", poses: [PoseData])
  /// ]
  ///
  /// let analysis = try await engine.analyzeGroup(groupPoses)
  /// // 결과: "B의 왼팔이 다른 팀원들과 평균 20도 차이"
  /// ```
  ///
  func analyzeGroup(_ groupPoses: [PersonPoses]) async throws -> GroupFeedback
  
  /// 2. 원본 vs 사용자 비교 (1:1)
  ///
  /// **입력 :** 원본 안무 + 사용자 동작
  /// **출력 :** 프레임별 차이점
  func compare(
    reference referencePoses: [PoseData],
    user userPoses: [PoseData]
  ) async throws -> ComparisonFeedback
}
