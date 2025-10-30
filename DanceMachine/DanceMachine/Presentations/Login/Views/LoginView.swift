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
            Color.white.ignoresSafeArea() // FIXME: - 컬러 수정
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Welcome to DirAct")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.black) // FIXME: - 컬러 수정
                    .multilineTextAlignment(.center)
                
                Button {
                    Task {
                        await viewModel.signInApple()
                    }
                } label: {
                    SignInWithAppleButtonViewRepresentable(
                        type: .default,
                        style: .black
                    )
                    .allowsHitTesting(false)
                }
                .frame(height: 50) //FIXME: 버튼 크기
                .padding(.horizontal, 32) //FIXME: 버튼 여백
                
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
