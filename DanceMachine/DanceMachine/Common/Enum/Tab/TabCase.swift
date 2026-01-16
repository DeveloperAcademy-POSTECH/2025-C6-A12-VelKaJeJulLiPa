//
//  TabCase.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

enum TabCase: CaseIterable, Identifiable {
  case home
  case inbox
  case myPage

  var id: String {
    switch self {
    case .home: return "home"
    case .inbox: return "inbox"
    case .myPage: return "myPage"
    }
  }

  var localizedString: String {
    switch self {
    case .home: return String(localized: "홈")
    case .inbox: return String(localized: "수신함")
    case .myPage: return String(localized: "마이 페이지")
    }
  }

  var icon: String {
    switch self {
    case .home: return "house"
    case .inbox: return "tray"
    case .myPage: return "person.crop.circle"
    }
  }
}
