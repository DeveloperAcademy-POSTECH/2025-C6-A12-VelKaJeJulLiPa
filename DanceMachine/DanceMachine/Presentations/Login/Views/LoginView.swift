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
  @EnvironmentObject var router: AuthRouter
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 24) {
        Spacer()
        
        Image("AppLogo") // FIXME: - 이미지 수정 (임시)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .padding(.horizontal, 26) // FIXME: - 공백
        
        Text("DirAct") // FIXME: - 글자 (임시)
          .font(.headline2Medium)
          .foregroundStyle(.white)
        
        Spacer()
        
        Button {
          Task { await viewModel.signInApple() }
        } label: {
          SignInWithAppleButtonViewRepresentable(
            type: .default,
            style: .white
          )
          .allowsHitTesting(false)
        }
        .frame(height: 54)
        .padding(.horizontal, 26)
        
        Spacer()
          .overlay {
            if viewModel.isLoading {
              ProgressView()
                .tint(.white)
            }
          }
      }
    }
    .onReceive(viewModel.$isNewUser) { isNewUser in
      if isNewUser {
        router.push(to: .termsAgree)
      }
    }
  }
}


#Preview {
  LoginView()
}
