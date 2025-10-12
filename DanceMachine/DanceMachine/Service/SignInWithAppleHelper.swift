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


struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        
    }
    
}

struct SignInWithAppleResult {
    let token: String
    let nonce: String
    let name: String
    let email: String?
}

@MainActor
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
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }


    private func sha256(_ input: String) -> String {
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

extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

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
        
        let name = appleIDCredential.displayName()
        let email = appleIDCredential.email

        let tokens = SignInWithAppleResult(token: idTokenString, nonce: nonce, name: name, email: email)
        completionHandler?(.success(tokens))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        completionHandler?(.failure(URLError(.cannotFindHost)))
    }

}

extension UIViewController: @retroactive ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension UIApplication {

    static private func rootViewController() -> UIViewController? {
        var rootVC: UIViewController?
        if #available(iOS 15.0, *) {
            rootVC = UIApplication
                .shared
                .connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .last?
                .rootViewController
        } else {
            rootVC = UIApplication
                .shared
                .connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }?
                .rootViewController
        }

        return rootVC
    }

    @MainActor
    static func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? rootViewController()

        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

}
