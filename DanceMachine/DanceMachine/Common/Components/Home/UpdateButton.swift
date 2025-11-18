//
//  UpdateButton.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/16/25.
//

import SwiftUI

struct UpdateButton: View {
  
  let title: String
  let titleColor: Color
  let isEnabled: Bool
  let action: () -> Void
  
  init(
    title: String,
    titleColor: Color,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.titleColor = titleColor
    self.isEnabled = isEnabled
    self.action = action
  }
  
  var body: some View {
    Button {
      action()
    } label: {
      Text(title)
        .font(.headline2Medium)
        .foregroundStyle(isEnabled ? titleColor : Color.accentDisable)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }
}

#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    UpdateButton(
      title: "수정하기",
      titleColor: Color.primitiveNormal
    ) {
      
    }
  }
}
