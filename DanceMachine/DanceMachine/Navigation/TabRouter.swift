//
//  TabRouter.swift
//  DanceMachine
//
//  Created by Claude Code
//

import SwiftUI

@Observable
final class TabRouter {
  var currentTab: TabCase = .home

  func switchTab(to tab: TabCase) {
    currentTab = tab
  }
}
