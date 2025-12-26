//
//  VideoType.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/15/25.
//

import Foundation

enum VideoType: CaseIterable {
  case all
  case favorites

  var localizedString: String {
    switch self {
    case .all: return String(localized: "전체")
    case .favorites: return String(localized: "좋아요")
    }
  }
}
