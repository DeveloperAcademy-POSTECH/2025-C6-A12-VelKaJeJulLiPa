//
//  LoginView.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import SwiftUI
import AuthenticationServices

//TODO: Hi-fi 디자인 반영 (현재는 임시)
struct LoginView: View {
  @State private var viewModel = LoginViewModel()
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 24) {
        Spacer()
        
        Image(.logo) // FIXME: - 이미지 수정 (임시)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .padding(.horizontal, 26) // FIXME: - 공백
        
        Text("DirAct") // FIXME: - 글자 (임시)
          .font(.headline2Medium)
          .foregroundStyle(.white)
        
        Spacer()
        
        CustomAppleSignInButton {
          Task {
            await viewModel.signInApple()
          }
        }
        .frame(height: 54)
        .padding(.horizontal, 26)
        
        Spacer()
          .overlay {
            if viewModel.isLoading { ProgressView() }
          }
      }
    }
  }
}


#Preview {
  LoginView()
}
