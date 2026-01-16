//
//  TeamMemberRowModifier.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/19/25.
//

import SwiftUI

// MARK: - 팀원 리스트 셀 스타일
struct TeamMemberRowModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .frame(height: 48)
      .background(Color.backgroundNormal)
      .listRowBackground(Color.backgroundNormal)
      .listRowInsets(.init())
      .listRowSeparatorTint(Color.strokeNormal)
  }
}

extension View {
  func teamMemberRowStyle() -> some View {
    self.modifier(TeamMemberRowModifier())
  }
}
