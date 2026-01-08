//
//  File.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/5/26.
//

import Foundation

// MARK: - PoseData

/// 특정 시점의 포즈 데이터
///
/// MediaPipe가 추출한 33개 랜드마크를 담는 구조체 입니다.
/// 비디오의 각 프레임마다 하나의 PoseData가 생성됩니다.
///
/// **설계 이유 :**
/// - Codable: Firestore 저장 및 JSON 직렬화 가능
/// - Hashable: 중복 제거, Dictionary 키로 사용 가능
/// - 타임 스탬프: 비디오 재생 시점과 동기화
public struct PoseData: Codable, Hashable {
  
  /// 비디오에서의 타임 스탬프 (초 단위)
  ///
  /// **예시 :** 1.5초 시점의 포즈라면 timestamp = 1.5
  public let timestamp: Double
  
  /// 33개의 신체 랜드마크 좌표
  ///
  /// **MediaPipe 랜드마크 순서 :**
  /// - 0-10: 얼굴 (코, 눈, 귀, 입)
  /// - 11-16: 상체 (어꺠, 팔꿈치, 손목)
  /// - 17-22: 손 (핀치, 검지, 엄지)
  /// - 23-28: 하체 (엉덩이, 무릎, 발목)
  /// - 29-32: 발 (뒤꿈치, 발가락)
  public let landmarks: [LandmarkPoint]
  
  /// 포즈 검출 신뢰도 ( 0.0 ~ 1.0 )
  ///
  /// **의미 :**
  /// - 1.0에 가까울수록 "이게 사람이다" 라는 확신이 높음
  /// - 0.5 미만이면 오검출 가능성 높음
  ///
  /// **iOS API 제약 :**
  /// - MediaPipe iOS에서는 프레임별 신뢰도를 직접 제공하지 않음
  /// - PoseLandmarkerOptions의 minPoseDetectionConfidence로 필터링
  /// - 이 값은 수동으로 설정하거나 1.0으로 고정
  public let confidence: Float
  
  public init(timestamp: Double, landmarks: [LandmarkPoint], confidence: Float) {
    self.timestamp = timestamp
    self.landmarks = landmarks
    self.confidence = confidence
  }
  
  /// Firestore 저장용 딕셔너리 변환
  ///
  /// **사용 예시 :**
  ///```swift
  ///try await db.collection("poses").addDocument(data: poseData.asDictionary)
  ///```
  public var asDictionary: [String: Any] {
    [
      "timestamp": timestamp,
      "landmarks": landmarks.map { $0.asDictionary },
      "confidence": confidence
    ]
  }
}
