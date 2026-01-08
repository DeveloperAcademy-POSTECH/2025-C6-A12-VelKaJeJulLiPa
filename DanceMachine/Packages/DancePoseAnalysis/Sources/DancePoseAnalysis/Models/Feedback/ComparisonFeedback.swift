//
//  File.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/6/26.
//

import Foundation

// MARK: - ComparisonFeedback (원본 vs 사용자 비교 분석)

 /// 원본 안무 vs 사용자 동작 1:1 비교 분석
 ///
 /// **사용 사례:**
 /// - 선생님 안무 영상 vs 학생 연습 영상
 /// - 정확한 차이점 파악
 /// - 개인 맞춤 피드백
 ///
 /// **흐름:**
 /// 1. 디렉터가 원본 안무 업로드 → Project에 저장
 /// 2. 학생이 자기 동작 촬영 → 업로드
 /// 3. 두 포즈 데이터를 프레임별로 비교
 /// 4. Gemini가 차이점을 자연어로 설명
 ///
 /// **Gemini 프롬프트 구조:**
 /// ```
 /// 원본 안무: [포즈 데이터]
 /// 사용자 동작: [포즈 데이터]
 ///
 /// 비교해서 알려줘:
 /// 1. 전체 일치도
 /// 2. 시점별 차이 (3초에 팔이 15도 부족 등)
 /// 3. 가장 큰 차이 Top 3
 /// 4. 잘한 부분
 /// ```
 public struct ComparisonFeedback: Codable {

     /// 전체 일치도 점수 (0 ~ 100)
     ///
     /// **계산 방식:**
     /// - Gemini가 원본과 사용자 포즈를 비교
     /// - 각 관절의 각도 차이, 위치 차이를 종합
     ///
     /// **점수 의미:**
     /// - 95-100: 거의 완벽 (프로 수준)
     /// - 85-94: 매우 우수 (대부분 일치)
     /// - 70-84: 우수 (주요 동작 일치, 디테일 차이)
     /// - 50-69: 보통 (일부 차이 있음)
     /// - 50 미만: 많은 연습 필요
     ///
     /// **활용:**
     /// - 리더보드 순위
     /// - 진행도 트래킹 (이번주 85점 → 다음주 90점)
     public let similarityScore: Double

     /// 종합 비교 메시지 (2-3문장, 한국어)
     ///
     /// **톤:**
     /// - 긍정적 시작 (격려)
     /// - 개선점 언급 (건설적)
     /// - 구체적 조언 (실행 가능)
     ///
     /// **예시:**
     /// "전체적으로 원본 안무를 잘 따라하셨습니다. 특히 다리 동작과 리듬감이 좋아요.
     ///  다만 팔 동작이 원본보다 조금 작고, 무릎을 더 구부려야 완벽할 것 같습니다."
     public let summary: String

     /// 타임라인별 차이점 (시간순 정렬)
     ///
     /// **구조:**
     /// - 중요한 차이점만 포함 (모든 프레임 X)
     /// - 시간순 정렬 (0초 → 끝)
     /// - 심각도 순으로 필터링 (severity > 0.5)
     ///
     /// **사용 예시:**
     /// ```swift
     /// for diff in feedback.timelineDifferences {
     ///     print("\(diff.timestamp)초: \(diff.description)")
     /// }
     /// // 출력:
     /// // 0:03초: 왼팔이 15도 더 올라가야 합니다
     /// // 0:07초: 무릎을 10cm 더 구부리세요
     /// // 0:12초: 시선이 아래를 향하고 있습니다
     /// ```
     ///
     /// **UI 표시:**
     /// - 비디오 타임라인에 마커로 표시
     /// - 탭하면 해당 시점으로 이동 + 설명 표시
     public let timelineDifferences: [TimelineDifference]

     /// 가장 큰 차이가 나는 부위 Top 3-5개
     ///
     /// **정렬 기준:**
     /// - 평균 차이가 큰 순서
     /// - 예: 왼팔 평균 18도 차이 > 무릎 평균 12cm 차이
     ///
     /// **활용:**
     /// - 연습 우선순위 결정
     /// - "이 부분부터 먼저 고치세요" 가이드
     ///
     /// **UI 표시:**
     /// - 차트나 막대그래프로 시각화
     /// - "개선 필요 부위" 섹션에 카드로 표시
     public let majorDifferences: [BodyPartDifference]

     /// 잘 따라한 부분 (격려, 2-3개)
     ///
     /// **목적:**
     /// - 사용자 동기부여
     /// - 긍정적 피드백 균형
     /// - "이건 잘하고 있어요!" 메시지
     ///
     /// **예시:**
     /// - "다리 동작은 원본과 거의 완벽하게 일치합니다!"
     /// - "리듬감이 원본과 똑같아요"
     /// - "점프 타이밍이 정확합니다"
     public let strengths: [String]

     /// 프레임 동기화 정보 (선택적)
     ///
     /// **문제 상황:**
     /// - 사용자가 음악보다 0.3초 늦게 시작
     /// - 또는 빠르게 시작
     /// - 템포가 다름
     ///
     /// **해결:**
     /// - 오프셋 계산 (사용자가 0.3초 늦음)
     /// - 타임라인 자동 조정
     /// - "동작은 맞는데 타이밍만 늦어요" 피드백
     public let timingOffset: Double?

     /// 분석 생성 시각
     ///
     /// **활용:**
     /// - 피드백 히스토리 ("3일 전 분석")
     /// - 캐싱 만료 시간 계산
     /// - 재분석 여부 판단
     public let analyzedAt: Date

     // MARK: - Initializer

     public init(
         similarityScore: Double,
         summary: String,
         timelineDifferences: [TimelineDifference],
         majorDifferences: [BodyPartDifference],
         strengths: [String],
         timingOffset: Double? = nil,
         analyzedAt: Date = Date()
     ) {
         self.similarityScore = similarityScore
         self.summary = summary
         self.timelineDifferences = timelineDifferences
         self.majorDifferences = majorDifferences
         self.strengths = strengths
         self.timingOffset = timingOffset
         self.analyzedAt = analyzedAt
     }

     // MARK: - JSON Coding Keys

     /// Gemini API JSON 응답 키 매핑
     ///
     /// **Gemini 응답 형식:**
     /// ```json
     /// {
     ///   "similarity_score": 85,
     ///   "summary": "...",
     ///   "timeline_differences": [...],
     ///   "major_differences": [...],
     ///   "strengths": [...]
     /// }
     /// ```
     enum CodingKeys: String, CodingKey {
         case similarityScore = "similarity_score"
         case summary
         case timelineDifferences = "timeline_differences"
         case majorDifferences = "major_differences"
         case strengths
         case timingOffset = "timing_offset"
         case analyzedAt = "analyzed_at"
     }
 }

 // MARK: - TimelineDifference

 /// 특정 시점의 차이점
 ///
 /// **역할:**
 /// - 비디오 재생 중 "여기가 틀렸어요" 알림
 /// - 타임라인에 마커로 표시
 ///
 /// **예시 UI:**
 /// ```
 /// [비디오 플레이어]
 /// ━━━━━●━━━━━━━●━━━━●━━━ (●는 차이점 마커)
 ///      3초    7초    12초
 /// ```
 public struct TimelineDifference: Codable, Identifiable {

     /// 고유 ID (UI용)
     public let id: UUID

     /// 타임스탬프 (초)
     ///
     /// **예시:** 3.5초 시점
     ///
     /// **비디오 동기화:**
     /// ```swift
     /// player.seek(to: CMTime(seconds: diff.timestamp, preferredTimescale: 600))
     /// ```
     public let timestamp: Double

     /// 차이점 설명 (한국어, 1문장)
     ///
     /// **형식:**
     /// - 명확하고 구체적
     /// - 측정 가능한 값 포함 (각도, 거리)
     /// - 실행 가능한 조언
     ///
     /// **좋은 예시:**
     /// - "왼팔이 15도 더 올라가야 합니다"
     /// - "무릎을 10cm 더 구부리세요"
     /// - "시선을 정면으로 향하세요"
     ///
     /// **나쁜 예시:**
     /// - "팔이 이상해요" (모호함)
     /// - "더 잘하세요" (실행 불가능)
     public let description: String

     /// 심각도 (0.0 ~ 1.0)
     ///
     /// **기준:**
     /// - 0.8 이상: 크리티컬 (완전히 다른 동작)
     /// - 0.5~0.8: 중간 (눈에 띄는 차이)
     /// - 0.5 미만: 미세 (전문가만 알아챔)
     ///
     /// **활용:**
     /// - UI 색상: 0.8 이상 빨강, 0.5~0.8 노랑, 0.5 미만 초록
     /// - 알림 우선순위: 0.8 이상만 푸시
     /// - 필터링: "중요한 차이만 보기" 기능
     public let severity: Double

     /// 관련 신체 부위 (영어 키)
     ///
     /// **값:**
     /// - "leftArm", "rightArm"
     /// - "leftLeg", "rightLeg"
     /// - "torso", "head"
     ///
     /// **활용:**
     /// - 비디오에 해당 부위 하이라이트
     /// - 스켈레톤 오버레이에서 강조
     /// - 부위별 필터링 ("팔 차이만 보기")
     public let bodyPart: String

     // MARK: - Initializer

     public init(
         id: UUID = UUID(),
         timestamp: Double,
         description: String,
         severity: Double,
         bodyPart: String
     ) {
         self.id = id
         self.timestamp = timestamp
         self.description = description
         self.severity = severity
         self.bodyPart = bodyPart
     }
 }

 // MARK: - BodyPartDifference

 /// 신체 부위별 차이점 통계
 ///
 /// **역할:**
 /// - 전체 영상에서 특정 부위의 평균 차이
 /// - "어느 부분을 집중적으로 연습해야 하나" 가이드
 ///
 /// **예시 UI:**
 /// ```
 /// 개선 필요 부위:
 /// 1. 왼팔      [█████████░] 평균 18도 차이
 /// 2. 오른쪽 무릎 [███████░░░] 평균 12cm 차이
 /// 3. 허리      [█████░░░░░] 평균 8도 차이
 /// ```
 public struct BodyPartDifference: Codable, Identifiable {

     /// 고유 ID (UI용)
     public let id: UUID

     /// 신체 부위 이름 (한국어)
     ///
     /// **예시:** "왼팔", "오른쪽 무릎", "허리"
     public let bodyPartName: String

     /// 평균 차이 (측정값 + 단위)
     ///
     /// **형식:**
     /// - 각도: "평균 18도 차이"
     /// - 거리: "평균 12cm 차이"
     /// - 타이밍: "평균 0.3초 늦음"
     ///
     /// **계산:**
     /// - 전체 프레임에서 해당 부위의 차이 평균
     /// - 예: 120개 프레임 중 왼팔 각도 차이의 평균 = 18도
     public let averageDifference: String

     /// 개선 방법 (실행 가능한 조언)
     ///
     /// **형식:**
     /// - 구체적
     /// - 실행 가능
     /// - 측정 가능
     ///
     /// **좋은 예시:**
     /// - "팔을 어깨 높이까지 올리세요"
     /// - "무릎을 90도로 구부리세요"
     /// - "허리를 곧게 펴세요"
     ///
     /// **나쁜 예시:**
     /// - "더 열심히 하세요" (모호함)
     /// - "잘하세요" (실행 불가능)
     public let improvement: String

     /// 차이 심각도 (0.0 ~ 1.0)
     ///
     /// **활용:**
     /// - 정렬 순서 (높은 순)
     /// - UI 색상 (빨강 → 노랑 → 초록)
     public let severity: Double

     // MARK: - Initializer

     public init(
         id: UUID = UUID(),
         bodyPartName: String,
         averageDifference: String,
         improvement: String,
         severity: Double
     ) {
         self.id = id
         self.bodyPartName = bodyPartName
         self.averageDifference = averageDifference
         self.improvement = improvement
         self.severity = severity
     }
 }

 // MARK: - 편의 확장

 extension ComparisonFeedback {

     /// 심각한 차이점만 필터링 (severity >= 0.7)
     ///
     /// **활용:**
     /// - "중요한 문제만 보기" 기능
     /// - 푸시 알림 (심각한 것만)
     public var criticalDifferences: [TimelineDifference] {
         return timelineDifferences.filter { $0.severity >= 0.7 }
     }

     /// 특정 신체 부위의 차이점만 필터링
     ///
     /// **예시:**
     /// ```swift
     /// let armIssues = feedback.differences(for: "arm")
     /// ```
     public func differences(for bodyPart: String) -> [TimelineDifference] {
         return timelineDifferences.filter { $0.bodyPart.contains(bodyPart) }
     }

     /// 성적 등급 계산
     ///
     /// **반환:**
     /// - A: 90점 이상
     /// - B: 80-89점
     /// - C: 70-79점
     /// - D: 60-69점
     /// - F: 60점 미만
     public var grade: String {
         switch similarityScore {
         case 90...100: return "A"
         case 80..<90: return "B"
         case 70..<80: return "C"
         case 60..<70: return "D"
         default: return "F"
         }
     }

     /// 진행률 (0.0 ~ 1.0)
     ///
     /// **활용:**
     /// - 프로그레스 바
     /// - 원형 차트
     public var progressPercentage: Double {
         return similarityScore / 100.0
     }
 }
