//
//  LoginView.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome to DanceMachine")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton(
                onRequest: viewModel.handleSignInWithAppleRequest,
                onCompletion: viewModel.handleSignInWithAppleCompletion
            )
            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
            .frame(height: 50)
            .cornerRadius(8)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}
