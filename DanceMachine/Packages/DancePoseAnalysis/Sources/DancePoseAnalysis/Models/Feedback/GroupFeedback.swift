//
//  File.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/5/26.
//

import Foundation

/// 단체 안무 분석 결과
///
/// **사용 사례 :** 여러 명이 한 영상에서 춤 -> 누가 틀렸는지 찾기
///
/// **예시 :**
/// "5명 중 B와 D의 팔 각도가 다른 팀원들과 차이가 큽니다."
public struct GroupFeedback: Codable {
  
  /// 전체 팀 동기화 점수 (0 ~ 100)
  ///
  /// **의미 :**
  /// - 100: 모두 완벽히 일치
  /// - 80: 대부분 일치, 일부 차이
  /// - 60: 몇 명이 확실히 다름
  public let syncScore: Double
  
  /// 종합 분석
  ///
  /// **예시 :**
  /// "전체적으로 팀워크가 좋습니다. 다만 2번과 4번 댄서의 팔 동작이
  /// 다른 팀원들과 차이가 있습니다."
  public let summary: String
  
  /// 이상치 댄서 (각도/위치가 다른 사람들)
  ///
  /// **정렬 :** 차이가 큰 순서대로
  ///
  /// **예시 :**
  /// - Person B: "왼팔 각도가 평균 20도 높음"
  /// - Person D: "무릎 높이가 평균 10CM 낮음"
  public let outliers: [OutlierPerson]
  
  /// 시점별 동기화 이슈
  ///
  /// **예시 :**
  /// - 0:05 - "B와 D가 다른 팀원보다 0.3초 늦음"
  /// - 0:12 - "C의 팔 각도가 다름"
  public let timelineIssues: [TimelineIssue]
  
  /// 잘 맞춘 부분
  ///
  /// **예시 :**
  /// - "다리 동작은 모두 일치합니다 !"
  /// - "리듬감이 좋아요"
  public let strengths: [String]
  
  public let analyzedAt: Date
}

// MARK: - OutlierPerson

/// 이상치 댄서 정보
public struct OutlierPerson: Codable {
  
  /// 댄서 식별자
  ///
  /// **생성 방법 :**
  /// - MediaPipe 추적 ID 또는
  /// - 화면 위치 기반 (왼쪽부터 1, 2, 3 ....)
  ///
  /// **예시 :** "Person 2", "왼쪽에서 두 번째"
  public let personId: String
  
  /// 차이 설명
  ///
  /// **예시 :**
  /// "왼팔 각도가 다른 팀원들보다 평균 20도 높습니다"
  public let description: String
  
  /// 심각도 (0.0 ~ 1.0)
  ///
  /// **기준 :**
  /// - 0.8 이상 : 매우 다름 (즉시 수정 필요)
  /// - 0.5~0.8: 다름 (연습 필요)
  /// - 0.5 미만: 미세한 차이
  public let severity: Double
  
  /// 영향 받는 신체 부위
  ///
  /// **예시 :** ["왼팔", "오른쪽 무릎"]
  public let affectedParts: [String]
}

// MARK: - TimelineIssue

/// 특정 시점의 팀 동기화 이슈
public struct TimelineIssue: Codable {
  
  /// 타임 스탬프 (초)
  public let timestamp: Double
  
  /// 이슈 설명
  ///
  /// **예시 :**
  /// "B와 D가 다른 팀원보다 0.3초 늦습니다"
  public let description: String
  
  /// 관련 댄서들
  ///
  /// **예시 :** ["Person B", "Person D"]
  public let involvedPersons: [String]
}

// MARK: - PersonPoses

/// 한 사람의 포즈 데이터 모음
///
/// **사용:**
/// - 단체 영상에서 각 사람별로 포즈 그룹화
public struct PersonPoses: Codable {

    /// 사람 식별자
    ///
    /// **생성 방법:**
    /// 1. MediaPipe 추적 ID (이상적)
    /// 2. 화면 위치 기반 (왼쪽부터 "Person 1", "Person 2"...)
    /// 3. 바운딩 박스 위치 기반
    ///
    /// **주의:** MediaPipe iOS는 추적 ID를 제공하지 않음
    /// → 화면 위치로 식별해야 함
    public let personId: String

    /// 이 사람의 모든 포즈 데이터
    public let poses: [PoseData]

    /// 화면상 위치 (선택적)
    ///
    /// **활용:**
    /// - UI에 표시할 때 누구인지 시각화
    /// - 예: 왼쪽부터 1번, 2번, 3번...
    public let screenPosition: Int?

    public init(personId: String, poses: [PoseData], screenPosition: Int? = nil) {
        self.personId = personId
        self.poses = poses
        self.screenPosition = screenPosition
    }
}
