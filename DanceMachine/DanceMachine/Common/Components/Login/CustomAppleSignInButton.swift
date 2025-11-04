//
//  CustomAppleSignInButton.swift
//  DanceMachine
//
//  Created by Paidion on 11/5/25.
//

import SwiftUI

// FIXME: - Hi-fi 적용하기
struct CustomAppleSignInButton: View {
  var action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "applelogo")
          .font(.heading1SemiBold)
        Text("Apple로 시작하기")
          .font(.headline)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .foregroundColor(.black)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 15))
    }
  }
}


#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    CustomAppleSignInButton {
      print("Apple 로그인 버튼 클릭됨")
    }
    .frame(height: 54)
    .padding(.horizontal, 26)
  }
}
