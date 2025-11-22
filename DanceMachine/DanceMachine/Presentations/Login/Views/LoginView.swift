//
//  LoginView.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
  @EnvironmentObject var router: AuthRouter
  @StateObject private var viewModel = LoginViewModel()
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        Spacer()
        
        VStack(spacing: 0) {
          Image("appLogo")
          
          Spacer().frame(height: 40)
          
          Text("DirAct")
            .font(Font.establishRetrosans(.regular, size: 44))
            .foregroundStyle(.secondaryAssitive)
          
          Spacer().frame(height: 23)
          
          Text("댄스팀을 위한 효과적인 피드백 앱")
            .font(Font.pretendard(.medium, size: 18))
            .foregroundStyle(.secondaryAssitive)
          
        }
        Spacer()
          .overlay {
            if viewModel.isLoading {
              LoadingSpinner()
                .frame(width: 28, height: 28)
            }
          }
        
        Button {
          Task { try await viewModel.signInApple() }
        } label: {
          SignInWithAppleButtonViewRepresentable(
            type: .default,
            style: .white
          )
          .allowsHitTesting(false)
        }
        .disabled(viewModel.isLoading)
        .frame(height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 26)
        
        Spacer()
      }
    }
    .alert(
      "로그인 실패",
      isPresented: $viewModel.showError
    ) {
      Button("확인", role: .cancel) {}
    } message: {
      Text("로그인을 실패했습니다.\n다시 시도해주세요.")
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
