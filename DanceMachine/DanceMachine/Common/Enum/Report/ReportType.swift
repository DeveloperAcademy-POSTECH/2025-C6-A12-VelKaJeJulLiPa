//
//  ReportType.swift
//  DanceMachine
//
//  Created by Paidion on 11/8/25.
//

import Foundation

/// 신고 유형
enum ReportType: String, CaseIterable {
  case insult = "insult"                               // 욕설 및 비하 (종교, 장애, 성별 등)
  case hateSpeech = "hate_speech"                      // 폭력 및 혐오표현
  case sexualContent = "sexual_content"                // 음란물 및 성적인 표현
  case gambling = "gambling"                           // 도박 및 사행성 조장
  case spamAds = "spam_ads"                            // 스팸 및 광고
  case personalInfoLeak = "personal_info_leak"         // 개인 정보 유출
  case impersonationOrFalse = "impersonation_or_false" // 사칭 및 허위 정보
  case other = "other"                                 // 기타
}
