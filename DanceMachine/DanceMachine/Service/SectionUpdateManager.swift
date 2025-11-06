//
//  SectionUpdateManager.swift
//  DanceMachine
//
//  Created by Claude on 11/5/25.
//

import Foundation

/// 섹션 업데이트 콜백을 관리하는 매니저
@Observable
final class SectionUpdateManager {
  static let shared = SectionUpdateManager()
  private init() {}

  var onSectionAdded: ((Section) -> Void)?
  var onSectionDeleted: ((String) -> Void)?
  var onSectionUpdated: ((String, String) -> Void)?
  var onTrackMoved: ((String, String) -> Void)?
}
