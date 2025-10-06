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
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: icon.toolIcon)
                    .foregroundStyle(Color.gray)
                    .frame(width: 24, height: 24)
            }
//            .padding(.leading, -8)
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
