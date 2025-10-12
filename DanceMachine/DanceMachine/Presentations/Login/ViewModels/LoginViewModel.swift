//
//  LoginViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import Foundation
import AuthenticationServices

final class LoginViewModel {
    
    private let authManager = FirebaseAuthManager.shared
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        authManager.handleSignInWithAppleRequest(request)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        authManager.handleSignInWithAppleCompletion(result)
    }

}

    


