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
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome to DanceMachine")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.signInApple()
                }
            } label: {
                SignInWithAppleButtonViewRepresentable(
                    type: .default,
                    style: colorScheme == .light ? .black : .white
                )
                .allowsHitTesting(false)
            }
            .frame(height: 50) //FIXME: 버튼 크기
            .padding(.horizontal, 32) //FIXME: 버튼 여백
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}


#Preview {
    LoginView()
}
