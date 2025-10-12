//
//  LoginView.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import SwiftUI
import AuthenticationServices

// FIXME: Implement Hi-fi Design
struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome to DanceMachine")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    do {
                        try await viewModel.signInApple()
                    } catch {
                        print(error)
                    }
                }
            }, label: {
                SignInWithAppleButtonViewRepresentable(
                    type: .default,
                    style: colorScheme == .light ? .black : .white
                )
                .allowsHitTesting(false)
            })
            .frame(height: 50)
            .cornerRadius(8)
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}
