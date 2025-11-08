//
//  CustomAppleSignInButton.swift
//  DanceMachine
//
//  Created by Paidion on 11/5/25.
//

import SwiftUI

struct CustomAppleSignInButton: View {
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "applelogo")
          .font(.system(size: 19, weight: .semibold))
        Text("Apple로 시작하기")
          .font(.system(size: 19, weight: .semibold))
      }
      .frame(height: 54)
      .frame(maxWidth: .infinity)
      .foregroundColor(.black)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 15))
    }
  }
}


#Preview {
  ZStack {
    Color.backgroundNormal.ignoresSafeArea()
    CustomAppleSignInButton {
      print("Apple 로그인 버튼 클릭됨")
    }
    .padding(.horizontal, 26)
  }
}
