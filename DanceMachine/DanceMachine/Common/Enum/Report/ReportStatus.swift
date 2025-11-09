//
//  ReportStatus.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/3/25.
//

import Foundation

/// 신고 상태
enum ReportStatus: String, Codable {
  case pending    = "pending"     // 신고 접수 완료(초기상태)
  case reviewing  = "reviewing"   // 검토중
  case resolved   = "resolved"    // 신고 조치 완료
  case dismissed  = "dismissed"   // 신고 무효화 (기각)
}
