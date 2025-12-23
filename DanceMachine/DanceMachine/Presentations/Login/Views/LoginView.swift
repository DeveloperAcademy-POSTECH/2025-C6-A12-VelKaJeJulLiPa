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
  
  @State private var logoOffset: CGFloat = 0
  @State private var showContent = false
  
  var body: some View {
    ZStack {
      Image(.splashIcon)
        .offset(y: logoOffset)
      VStack {
        content
      }
      .offset(y: 140)
    }
    .background(
      Image(.splashBackground)
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()
    )
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
    .onAppear {
      withAnimation(.easeOut(duration: 0.6)) {
        logoOffset = -100
      }
      
      withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
        showContent = true
      }
    }
  }
  
  private var content: some View {
    VStack(spacing: 0) {
      Text("DirAct")
        .font(Font.establishRetrosans(.regular, size: 44))
        .foregroundStyle(.labelStrong)
        .opacity(showContent ? 1 : 0)
      Spacer().frame(height: 24)
      Text("댄스팀을 위한 효과적인 피드백 앱")
        .font(Font.pretendard(.medium, size: 18))
        .foregroundStyle(.labelAssitive)
        .opacity(showContent ? 1 : 0)
      Spacer().frame(height: 56)
      LoadingSpinner()
        .frame(width: 28, height: 28)
        .opacity(viewModel.isLoading ? 1 : 0)
      Spacer().frame(height: 56)
      appleLogginButton
    }
  }
  
  private var appleLogginButton: some View {
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
    .opacity(showContent ? 1 : 0)
  }
}

#Preview {
  LoginView()
}
