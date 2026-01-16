//
//  CustomNavigationBar.swift
//  DanceMachine
//
//  Created by 조재훈 on 12/31/25.
//

import SwiftUI

struct CustomNavigationBar: View {
  let text: String
  
  var body: some View {
    HStack {
      Spacer()
      Text(text)
        .font(.heading1SemiBold)
        .foregroundStyle(.labelStrong)
      Spacer()
    }
    .frame(height: 44)
    .background(Color.backgroundNormal)
  }
}

#Preview {
  CustomNavigationBar(text: "마이페이지")
}
