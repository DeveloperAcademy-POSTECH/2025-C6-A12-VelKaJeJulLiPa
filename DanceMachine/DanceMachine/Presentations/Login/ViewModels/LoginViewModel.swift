//
//  LoginViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import Foundation
import AuthenticationServices
import FirebaseAuth


@MainActor
final class LoginViewModel {
    
    func signInApple() async throws {
        let helper = SignInAppleHelper()
        let tokens = try await helper.startSignInWithAppleFlow()
        let authDataResult = try await FirebaseAuthManager.shared.signInWithApple(tokens: tokens)
        await FirebaseAuthManager.shared.updateDisplayName(for: authDataResult.user, with: tokens.name)
        let user = User(user: authDataResult.user)
        
        // Check whether user document exists or not
        if let user: User = try? await FirestoreManager.shared.get(user.userId, from: .users) {
            try await FirestoreManager.shared.updateUserLastLogin(user)
        } else {
            try await FirestoreManager.shared.createUser(user)
        }
    }
}
