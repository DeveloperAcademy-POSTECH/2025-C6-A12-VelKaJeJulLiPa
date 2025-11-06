//
//  ToolbarLeadingBackButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//


import SwiftUI

/// 뒤로가기 버튼입니다.
struct ToolbarLeadingBackButton: ToolbarContent {
  @Environment(\.dismiss) private var dismiss

  var icon: ToolbarLeadingIcon
  var action: (() -> Void)? = nil

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        if let action = action {
          action()
        } else {
          dismiss()
        }
      } label: {
        Image(systemName: icon.toolIcon)
          .foregroundStyle(.labelStrong)
          .frame(width: 22, height: 22)
      }
    }
  }
}

enum ToolbarLeadingIcon: String {
  case chevron
  case xmark
  
  var toolIcon: String {
    switch self {
    case .chevron:
      return "chevron.left"
    case .xmark:
      return "xmark"
    }
  }
}

#Preview {
  NavigationStack {
    Text("Preview")
      .toolbar {
        ToolbarLeadingBackButton(icon: .chevron)
      }
  }
}
