//
//  SignInWithAppleHelper.swift
//  DanceMachine
//
//  Created by Paidion on 10/12/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit


/// 애플 로그인 로직을 담당
final class SignInAppleHelper: NSObject {
    
    private var currentNonce: String?
    private var completionHandler: ((Result<SignInWithAppleResult, Error>) -> Void)? = nil
    
    func startSignInWithAppleFlow() async throws -> SignInWithAppleResult {
        try await withCheckedThrowingContinuation { continuation in
            self.startSignInWithAppleFlow { result in
                switch result {
                case .success(let signInAppleResult):
                    continuation.resume(returning: signInAppleResult)
                    return
                case .failure(let error):
                    continuation.resume(throwing: error)
                    return
                }
            }
        }
    }

     func startSignInWithAppleFlow(viewController: UIViewController? = nil, completion: @escaping (Result<SignInWithAppleResult, Error>) -> Void) {
        guard let topVC = viewController ?? UIApplication.topViewController() else {
            completion(.failure(SignInWithAppleError.noViewController))
            return
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        completionHandler = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = topVC
        authorizationController.performRequests()
    }
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }


    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }

    private enum SignInWithAppleError: LocalizedError {
            case noViewController
            case invalidCredential
            case badResponse
            case unableToFindNonce
            case failedToStartFlow

            var errorDescription: String? {
                switch self {
                case .noViewController:
                    return "Could not find top view controller."
                case .invalidCredential:
                    return "Invalid sign in credential."
                case .badResponse:
                    return "Apple Sign In had a bad response."
                case .unableToFindNonce:
                    return "Apple Sign In token expired."
                case .failedToStartFlow:
                    return "Apple SIgn In failed."
                }
            }
        }
    
}


/// 애플 로그인 성공 및 실패 분기처리
extension SignInAppleHelper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8),
            let nonce = currentNonce else {
            completionHandler?(.failure(SignInWithAppleError.badResponse))
            return
        }

        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        let tokens = SignInWithAppleResult(token: idTokenString, nonce: nonce,
                                           appleIDCredential: appleIDCredential, fullName: fullName, email: email)
        completionHandler?(.success(tokens))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        completionHandler?(.failure(URLError(.cannotFindHost)))
    }
}


/// 애플 로그인 후 애플이 제공해주는 정보
struct SignInWithAppleResult {
    let token: String
    let nonce: String
    let appleIDCredential: ASAuthorizationAppleIDCredential
    let fullName: PersonNameComponents?
    let email: String?
}


///  애플 로그인 버튼
struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }
    
}
