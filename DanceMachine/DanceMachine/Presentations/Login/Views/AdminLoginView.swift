//
//  AdminLoginView.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/8/26.
//

import SwiftUI

struct AdminLoginView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var vm: LoginViewModel
  
  @State private var email: String = ""
  @State private var password: String = ""
  
  @FocusState private var focusedField: Field?
  
  fileprivate enum Field: Hashable {
    case email
    case password
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      Text("관리자 계정으로 로그인")
        .font(.title2SemiBold)
        .foregroundStyle(Color.labelStrong)
      Spacer().frame(height: 32)
      AdminTextField(
        text: $email,
        isFocused: focusedField == .email,
        placeHolder: String(localized: "관리자 이메일")
      ).focused($focusedField, equals: .email)
      Spacer().frame(height: 16)
      AdminTextField(
        text: $password,
        isFocused: focusedField == .password,
        placeHolder: String(localized: "관리자 비밀번호"),
        isSecure: true
      ).focused($focusedField, equals: .password)
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .background(Color.backgroundElevated.ignoresSafeArea())
    .dismissKeyboardOnTap()
    .safeAreaInset(edge: .bottom) {
      bottomButtonView
        .padding(.all, 16)
    }
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .xmark)
      ToolbarCenterTitle(text: String(localized: "관리자 로그인"))
    }
    .onChange(of: vm.adminLoginSuccess) { _, success in
      if success {
        dismiss()
      }
    }
    .alert("로그인 실패", isPresented: .constant(vm.adminLoginError != nil)) {
      Button("확인", role: .cancel) {
        vm.adminLoginError = nil
      }
    } message: {
      Text(vm.adminLoginError ?? "알 수 없는 오류")
    }
  }

  private var bottomButtonView: some View {
    ActionButton(
      title: String(localized: "관리자 로그인"),
      color: email.isEmpty || password.isEmpty ? Color.fillAssitive : Color.secondaryStrong,
      height: 47,
      isEnabled: !email.isEmpty && !password.isEmpty ? true : false,
      isLoading: vm.isLoading
    ) {
      Task {
        await vm.signInWithEmail(
          email: email,
          password: password
        )
      }
    }
  }
}

#Preview {
  AdminLoginView(vm: LoginViewModel())
}

fileprivate struct AdminTextField: View {
  @Binding var text: String
  let isFocused: Bool
  let placeHolder: String
  var isSecure: Bool = false
  
  var body: some View {
    RoundedRectangle(cornerRadius: 15)
      .stroke(isFocused ? .secondaryStrong : .clear, lineWidth: 1)
      .fill(Color.fillStrong)
      .frame(maxWidth: .infinity)
      .frame(height: 51)
      .overlay {
        if isSecure {
          SecureField(
            placeHolder,
            text: $text
          )
          .padding([.leading, .vertical], 16)
          .font(.headline2Medium)
          .foregroundStyle(Color.labelStrong)
        } else {
          TextField(
            placeHolder,
            text: $text
          )
          .padding([.leading, .vertical], 16)
          .font(.headline2Medium)
          .foregroundStyle(Color.labelStrong)
        }
      }
  }
}
