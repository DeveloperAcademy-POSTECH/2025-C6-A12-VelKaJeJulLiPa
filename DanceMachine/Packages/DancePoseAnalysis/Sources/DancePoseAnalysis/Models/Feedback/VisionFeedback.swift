//
//  VisionFeedback.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/26/26.
//
//  Gemini 3 Vision API 응답 모델
//  Performance Director 시점의 피드백

import Foundation

/// Gemini 3 Vision으로 분석한 단체 안무 피드백
///
/// **특징:**
/// - 실제 영상 기반 분석 (포즈 좌표 X)
/// - 15년 경력 디렉터 관점
/// - 구체적인 위치 표현 ("중앙 뒤편", "왼쪽 끝")
/// - 타임스탬프 mm:ss 형식
public struct VisionFeedback: Codable, Hashable, Sendable {
  /// 전체 동작 점수 (0-100)
  public let overallScore: Int

  /// 치명적 오류 (반드시 고쳐야 할 부분)
  public let criticalErrors: [CriticalError]

  /// 하이라이트 순간 (잘한 부분, optional)
  public let highlightMoment: HighlightMoment?

  public init(
    overallScore: Int,
    criticalErrors: [CriticalError],
    highlightMoment: HighlightMoment?
  ) {
    self.overallScore = overallScore
    self.criticalErrors = criticalErrors
    self.highlightMoment = highlightMoment
  }

  enum CodingKeys: String, CodingKey {
    case overallScore = "overall_score"
    case criticalErrors = "critical_errors"
    case highlightMoment = "highlight_moment"
  }

  // MARK: - Nested Types

  /// 치명적 오류 (반드시 교정 필요)
  public struct CriticalError: Codable, Hashable, Sendable, Identifiable {
    public var id: String { "\(timestamp)-\(who)" }

    /// 시점 (mm:ss 형식, 예: "01:23")
    public let timestamp: String

    /// 누구 (위치 기반 설명, 예: "중앙 뒤편", "왼쪽 끝")
    public let who: String

    /// 문제점 (짧고 명확하게)
    public let issue: String

    /// 해결 방법 (구체적 교정 지시)
    public let fix: String

    public init(timestamp: String, who: String, issue: String, fix: String) {
      self.timestamp = timestamp
      self.who = who
      self.issue = issue
      self.fix = fix
    }
  }

  /// 하이라이트 순간 (잘한 부분)
  public struct HighlightMoment: Codable, Hashable, Sendable {
    /// 시점 (mm:ss 형식)
    public let timestamp: String

    /// 설명 (칭찬 및 긍정적 피드백)
    public let description: String

    public init(timestamp: String, description: String) {
      self.timestamp = timestamp
      self.description = description
    }
  }
}

// MARK: - Preview Mock Data

extension VisionFeedback {
  /// 프리뷰용 목 데이터 (좋은 케이스)
  public static let mockGood = VisionFeedback(
    overallScore: 85,
    criticalErrors: [
      CriticalError(
        timestamp: "00:12",
        who: "오른쪽 끝",
        issue: "팔 각도 낮음",
        fix: "팔 더 들어"
      ),
      CriticalError(
        timestamp: "00:28",
        who: "중앙 뒤편",
        issue: "타이밍 0.3초 느림",
        fix: "음악 먼저 듣고 시작"
      )
    ],
    highlightMoment: HighlightMoment(
      timestamp: "00:45",
      description: "전체 에너지 통일감 좋음"
    )
  )

  /// 프리뷰용 목 데이터 (문제 많은 케이스)
  public static let mockBad = VisionFeedback(
    overallScore: 62,
    criticalErrors: [
      CriticalError(
        timestamp: "00:08",
        who: "왼쪽 앞",
        issue: "무게중심 왼쪽 쏠림",
        fix: "오른다리 힘 더 주기"
      ),
      CriticalError(
        timestamp: "00:15",
        who: "중앙",
        issue: "상체 각도 부족",
        fix: "허리 더 숙여"
      ),
      CriticalError(
        timestamp: "00:22",
        who: "오른쪽 뒤",
        issue: "손목 꺾임 없음",
        fix: "손목 90도 스냅"
      ),
      CriticalError(
        timestamp: "00:35",
        who: "왼쪽 끝",
        issue: "타이밍 0.5초 빠름",
        fix: "2번째 박자에 시작"
      )
    ],
    highlightMoment: nil
  )
}
