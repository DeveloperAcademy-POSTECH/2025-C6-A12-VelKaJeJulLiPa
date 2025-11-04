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
  let action: () -> Void
  
  var body: some View {
    Button {
      action()
    } label: {
      Text(title)
        .font(.headline2SemiBold)
        .foregroundStyle(titleColor)
    }
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
