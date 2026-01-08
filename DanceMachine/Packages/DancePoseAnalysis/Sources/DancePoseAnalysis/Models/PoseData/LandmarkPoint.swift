//
//  File.swift
//  DancePoseAnalysis
//
//  Created by 조재훈 on 1/5/26.
//

import Foundation

// MARK: - LandmarkPoint

/// 개별 랜드마크 포인트 (신체 관절 하나)
///
/// **좌표계 :**
/// - x, y: 정규화된 이미지 좌표 (0.0 ~ 1.0)
///   - (0, 0) = 왼쪽 위
///   - (1, 1) = 오른쪽 아래
/// - z: 깊이 (엉덩이 중점 기준, 음수 = 앞, 양수 = 뒤)
///
/// **설계 이유 :**
/// - Float 사용 : MediaPipe 출력 타입과 일치
/// - index 포함 : 어느 관절인지 식별 ( 0 = 코, 11= 왼쪽 어깨 등)
public struct LandmarkPoint: Codable, Hashable {
  
  /// X 좌표 (0.0 ~ 1.0, 왼쪽이 0)
  ///
  /// **정규화된 좌표 :**
  /// - 이미지 너비에 무관하게 항상 0~1 범위
  /// - 실제 픽셀 좌표 = x * 이미지 너비
  public let x: Float
  
  /// Y 좌표 (0.0 ~ 1.0, 위쪽이 0)
  public let y: Float
  
  /// Z 좌표 (깊이, 엉덩이 중점 기준)
  ///
  /// **단위 :** 대략 엉덩이 너비와 비슷한 스케일
  /// - 음수 : 카메라 쪽으로 가까움
  /// - 양수 : 카메라에서 멀어짐
  /// - 0 : 엉덩이 중점과 같은 깊이
  ///
  /// **절대 거리가 아니라 상대적 깊이만 의미한다.**
  public let z: Float
  
  /// 랜드마크 가시성 / 존재 확률 (0.0 ~ 1.0)
  ///
  /// **의미 :**
  /// - 1.0: 랜드마크가 확실히 보임
  /// - 0.0: 가려져서 안보임
  ///
  /// **활용 :**
  /// - visibility < 0.5인 관절은 분석에서 제외
  /// 예: 옆모습에서 반대편 어깨는 visibility가 낮기 때문에 분석에서 제외한다.
  public let visibility: Float
  
  /// MediaPipe 랜드마크 인덱스 ( 0 ~ 32 )
  ///
  /// **주요 인덱스 : **
  /// - 0: 코
  /// - 11, 12: 왼쪽 / 오른쪽 어깨
  /// - 13, 14: 왼쪽 / 오른쪽 팔꿈치
  /// - 15, 16: 왼쪽 / 오른쪽 손목
  /// - 23, 24: 왼쪽 / 오른쪽 엉덩이
  /// - 25, 26: 왼쪽 / 오른쪽 무릎
  /// - 27, 28: 왼쪽 / 오른쪽 발목
  public let index: Int
  
  public init(x: Float, y: Float, z: Float, visibility: Float, index: Int) {
    self.x = x
    self.y = y
    self.z = z
    self.visibility = visibility
    self.index = index
  }
  
  public var asDictionary: [String: Any] {
    return [
      "x": x,
      "y": y,
      "z": z,
      "visibility": visibility,
      "index": index
    ]
  }
}
