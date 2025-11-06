//
//  MyPageRow.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import SwiftUI

/// 마이페이지에서 정보만 표시하는 행
struct MyPageInfoRow: View {
  let title: String
  let value: String
  
  var body: some View {
    HStack {
      Text(title)
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
      
      Spacer()
      
      Text(value)
        .font(.headline2Medium)
        .foregroundStyle(.labelNormal)
    }
    .padding()
  }
}

#Preview {
  ZStack{
    Color.backgroundNormal.ignoresSafeArea()
    MyPageInfoRow(title: "TItle", value: "value")
  }
}
