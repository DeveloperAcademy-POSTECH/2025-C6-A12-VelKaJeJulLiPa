//
//  MyPageNavigationRow.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 마이페이지에서 정보를 보여줄 수 있고 네비게이션이 있는 행
struct MyPageNavigationRow: View {
  let title: String
  var value: String? = nil
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
        
        Spacer()
        
        if let value = value {
          Text(value)
            .font(.headline2Medium)
            .foregroundStyle(.labelNormal)
            .padding(.trailing, 8)
        }
        
        Image(systemName: "chevron.right")
          .font(.headline2SemiBold)
          .foregroundStyle(.labelNormal)
      }
      .padding()
    }
  }
}

#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    MyPageNavigationRow(title: "TItle", value: "value", action: { print("Click") })
  }
  
}
